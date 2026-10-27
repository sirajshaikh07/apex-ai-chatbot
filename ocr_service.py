#!/usr/bin/env python3
"""
Enterprise OCR Microservice for Oracle 26ai RAG Pipeline
Supports: Scanned PDFs, Images (PNG, JPG, TIFF, WEBP), and Mixed Digital/Scanned Docs
Runs on port 5055
"""

import io
import json
import os
import sys
from flask import Flask, request, jsonify
from PIL import Image
import pytesseract
import pypdf
import pdf2image

app = Flask(__name__)
pytesseract.pytesseract.tesseract_cmd = '/usr/bin/tesseract'

@app.route('/health', methods=['GET'])
def health():
    return jsonify({"status": "UP", "service": "Enterprise OCR Service", "engine": "Tesseract 5.3 + poppler"})

@app.route('/ocr', methods=['POST'])
def perform_ocr():
    try:
        content_type = request.headers.get('Content-Type', '').lower()
        file_bytes = None
        filename = request.args.get('filename', 'document.pdf').lower()

        # Support raw binary or multipart/form-data or json
        if request.is_json:
            import base64
            body = request.get_json()
            filename = body.get('filename', filename).lower()
            b64_data = body.get('data_base64', '')
            file_bytes = base64.b64decode(b64_data)
        elif request.files and 'file' in request.files:
            f = request.files['file']
            filename = f.filename.lower()
            file_bytes = f.read()
        else:
            file_bytes = request.get_data()

        if not file_bytes:
            return jsonify({"status": "ERROR", "message": "No file content provided"}), 400

        extracted_text = ""
        method_used = "UNKNOWN"

        # Check file type
        if filename.endswith(('.txt', '.csv', '.json', '.md', '.log', '.xml')):
            try:
                extracted_text = file_bytes.decode('utf-8', errors='ignore').strip()
                method_used = "PLAIN_TEXT"
            except Exception:
                pass
        
        is_pdf = filename.endswith('.pdf') or file_bytes.startswith(b'%PDF')

        if not extracted_text and is_pdf:
            # 1. Try digital text extraction first
            try:
                reader = pypdf.PdfReader(io.BytesIO(file_bytes))
                pages_text = []
                for p in reader.pages:
                    t = p.extract_text()
                    if t:
                        pages_text.append(t)
                digital_text = "\n\n".join(pages_text).strip()
                if len(digital_text) > 60:
                    extracted_text = digital_text
                    method_used = "PDF_DIGITAL"
            except Exception as e:
                digital_text = ""

            # 2. If digital text is missing or sparse (< 60 chars), run OCR on rendered page images
            if not extracted_text or len(extracted_text) <= 60:
                try:
                    images = pdf2image.convert_from_bytes(file_bytes, dpi=200)
                    ocr_pages = []
                    for idx, img in enumerate(images):
                        page_text = pytesseract.image_to_string(img, lang='eng')
                        if page_text.strip():
                            ocr_pages.append(f"--- Page {idx+1} ---\n" + page_text.strip())
                    extracted_text = "\n\n".join(ocr_pages).strip()
                    method_used = "PDF_SCANNED_OCR"
                except Exception as ocr_err:
                    if not extracted_text:
                        return jsonify({"status": "ERROR", "message": f"PDF OCR failed: {str(ocr_err)}"}), 500
        elif not extracted_text:
            # Image file (PNG, JPG, JPEG, TIFF, WEBP, BMP)
            try:
                img = Image.open(io.BytesIO(file_bytes))
                extracted_text = pytesseract.image_to_string(img, lang='eng').strip()
                method_used = "IMAGE_OCR"
            except Exception as img_err:
                return jsonify({"status": "ERROR", "message": f"Image OCR failed: {str(img_err)}"}), 500

        if not extracted_text:
            return jsonify({
                "status": "FAILED",
                "message": "No text could be extracted or recognized from this document",
                "char_count": 0
            }), 200

        return jsonify({
            "status": "SUCCESS",
            "method": method_used,
            "char_count": len(extracted_text),
            "text": extracted_text
        })

    except Exception as exc:
        return jsonify({"status": "ERROR", "message": str(exc)}), 500

if __name__ == '__main__':
    port = int(os.environ.get("OCR_PORT", 5055))
    print(f"Starting Enterprise OCR Microservice on port {port}...")
    app.run(host='0.0.0.0', port=port, debug=False)
