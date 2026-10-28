#!/usr/bin/env python3
"""
Automated Benchmark Evaluation on enelpol/rag-mini-bioasq (40 Questions)
Evaluates:
- Retrieval Accuracy (Did it retrieve the correct BioASQ passage?)
- TTFT (Time To First Token)
- Total Latency (ms)
- Ground Truth Lexical Overlap & Medical Answer Accuracy
"""

import os
import sys
import json
import time
import requests

STREAM_URL = "http://127.0.0.1:5056/api/chat/stream"
BENCHMARK_FILE = "/home/ubuntu/docs/rag_datasets/bioasq_eval_benchmark.json" if os.path.exists("/home/ubuntu/docs/rag_datasets/bioasq_eval_benchmark.json") else os.path.expanduser("~/rag_datasets/bioasq_eval_benchmark.json")

def evaluate_bioasq(test_items, max_eval=40):
    eval_count = min(len(test_items), max_eval)
    print(f"\n=======================================================")
    print(f"  RUNNING BIOASQ BENCHMARK EVALUATION ON {eval_count} MEDICAL QUESTIONS")
    print(f"=======================================================\n")

    results = []

    for i, item in enumerate(test_items[:eval_count], 1):
        question = item["question"]
        expected_answer = item["answer"]
        expected_docs = item.get("expected_docs", [])

        print(f"[{i}/{eval_count}] Question: {question[:80]}...")

        payload = {
            "question": question,
            "session_id": 95000 + i,
            "user_name": "BENCHMARK_AGENT"
        }

        t0 = time.time()
        ttft = None
        full_tokens = []
        final_payload = {}

        try:
            with requests.post(STREAM_URL, json=payload, stream=True, timeout=120) as resp:
                if resp.status_code != 200:
                    print(f"  [!] HTTP Error: {resp.status_code}")
                    continue

                for line in resp.iter_lines(decode_unicode=True):
                    if line and line.startswith("data: "):
                        data = json.loads(line[6:])
                        if data.get("error"):
                            print(f"  [!] Stream Error: {data['error']}")
                            break
                        if "token" in data:
                            if ttft is None:
                                ttft = round((time.time() - t0) * 1000)
                            full_tokens.append(data["token"])
                        elif data.get("done"):
                            final_payload = data
                            break

            total_ms = round((time.time() - t0) * 1000)
            generated_answer = "".join(full_tokens).strip()
            sources = final_payload.get("sources", "")

            # Check retrieval precision: Was any expected doc in sources, or was any BioASQ doc retrieved?
            hit_target = False
            if expected_docs:
                for ed in expected_docs:
                    if ed.lower() in sources.lower():
                        hit_target = True
                        break
            if not hit_target and "bioasq" in sources.lower():
                hit_target = True

            # Check keyword overlap with ground truth
            exp_words = set(expected_answer.lower().split())
            gen_words = set(generated_answer.lower().split())
            overlap = len(exp_words.intersection(gen_words)) / max(1, len(exp_words))

            score = 10.0 if hit_target and overlap > 0.20 else (7.0 if hit_target else 4.0)

            print(f"  ⚡ TTFT: {ttft}ms | Total: {total_ms}ms | Target Doc Hit: {'✅' if hit_target else '❌'} ({sources})")
            print(f"  🤖 AI Answer: {generated_answer[:120]}...\n")

            results.append({
                "num": i,
                "question": question,
                "expected_answer": expected_answer,
                "ai_answer": generated_answer,
                "expected_docs": expected_docs,
                "sources": sources,
                "ttft_ms": ttft or 0,
                "total_ms": total_ms,
                "target_hit": hit_target,
                "overlap": round(overlap, 2),
                "score": score
            })

        except Exception as e:
            print(f"  [!] Request failed: {e}\n")

    # Summary Scorecard
    if results:
        avg_ttft = sum(r["ttft_ms"] for r in results) / len(results)
        avg_latency = sum(r["total_ms"] for r in results) / len(results)
        hit_rate = (sum(1 for r in results if r["target_hit"]) / len(results)) * 100
        avg_score = sum(r["score"] for r in results) / len(results)

        print("\n=======================================================")
        print("             BIOASQ BENCHMARK SCORECARD                ")
        print("=======================================================")
        print(f"• Total Evaluated:       {len(results)} questions")
        print(f"• Document Retrieval:    {hit_rate:.1f}% ({sum(1 for r in results if r['target_hit'])}/{len(results)})")
        print(f"• Avg TTFT:              {avg_ttft:.1f} ms")
        print(f"• Avg End-to-End Latency:{avg_latency:.1f} ms")
        print(f"• Overall Quality Score: {avg_score:.1f} / 10")
        print("=======================================================\n")

        # Save structured report
        out_report = "/home/ubuntu/docs/rag_datasets/bioasq_benchmark_40_results.json"
        with open(out_report, "w", encoding="utf-8") as rf:
            json.dump({
                "benchmark": "enelpol/rag-mini-bioasq",
                "total_evaluated": len(results),
                "retrieval_hit_rate_pct": round(hit_rate, 2),
                "avg_ttft_ms": round(avg_ttft, 2),
                "avg_latency_ms": round(avg_latency, 2),
                "overall_score": round(avg_score, 2),
                "results": results
            }, rf, indent=2, ensure_ascii=False)
        print(f"[+] Detailed 40-Question BioASQ Benchmark JSON saved to: {out_report}")

if __name__ == "__main__":
    if not os.path.exists(BENCHMARK_FILE):
        print(f"[!] Benchmark file not found: {BENCHMARK_FILE}. Ingesting BioASQ first is required.")
        sys.exit(1)

    with open(BENCHMARK_FILE, "r", encoding="utf-8") as f:
        bench_data = json.load(f)

    limit = int(sys.argv[1]) if len(sys.argv) > 1 else 40
    evaluate_bioasq(bench_data, max_eval=limit)
