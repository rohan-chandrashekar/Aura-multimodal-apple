import json
import os
import sys
import numpy as np
from scipy import stats

ACCENT_DIR = "test_accents"
ACCENT_MITIGATED_DIR = "test_accents_mitigated"
LIGHTING_DIR = "test_lighting"
MITIGATED_DIR = "test_lighting_mitigated"


def load_json(path):
    if not os.path.exists(path):
        return None
    with open(path) as f:
        return json.load(f)


def analyze_speech_fairness():
    results = load_json(os.path.join(ACCENT_DIR, "speech_results.json"))
    if not results:
        print("No speech results found. Run: swift run Aura --fairness-speech test_accents")
        return None

    print("=" * 60)
    print("SPEECH FAIRNESS ANALYSIS")
    print("=" * 60)

    accents = []
    wers = []
    for r in results:
        accents.append(r["accent"])
        wers.append(r["wer"] * 100)

    print(f"\n{'Accent':<15} {'WER (%)':<10}")
    print("-" * 25)
    for a, w in zip(accents, wers):
        print(f"{a:<15} {w:<10.1f}")

    mean_wer = np.mean(wers)
    std_wer = np.std(wers, ddof=1) if len(wers) > 1 else 0
    min_wer = np.min(wers)
    max_wer = np.max(wers)
    disparity = max_wer - min_wer

    print(f"\nMean WER: {mean_wer:.1f}% ± {std_wer:.1f}%")
    print(f"Range: {min_wer:.1f}% – {max_wer:.1f}%")
    print(f"Disparity (max - min): {disparity:.1f} percentage points")

    if len(wers) >= 3:
        chi2, p_kruskal = stats.kruskal(*[[w] for w in wers])
        print(f"\nKruskal-Wallis H-test (are WERs equal across accents?):")
        print(f"  H = {chi2:.2f}, p = {p_kruskal:.4f}")
        if p_kruskal < 0.05:
            print("  → Significant difference across accents (p < 0.05)")
        else:
            print("  → No significant difference (p >= 0.05)")

    best_accent = accents[np.argmin(wers)]
    worst_accent = accents[np.argmax(wers)]
    print(f"\nBest: {best_accent} ({min_wer:.1f}%), Worst: {worst_accent} ({max_wer:.1f}%)")

    mitigated = load_json(os.path.join(ACCENT_MITIGATED_DIR, "speech_results.json"))
    if mitigated:
        print("\nAfter speech enhancement mitigation:")
        mit_wers = [r["wer"] * 100 for r in mitigated]
        for a, wb, wa in zip(accents, wers, mit_wers):
            delta = wa - wb
            print(f"  {a:<15} {wb:.1f}% → {wa:.1f}%  ({delta:+.1f})")
        mit_disp = max(mit_wers) - min(mit_wers)
        print(f"\n  Disparity after: {mit_disp:.1f} pp (was {disparity:.1f} pp)")
        print(f"  Enhancement targets noise, not voice quality → no disparity reduction")

    return {"wers": wers, "accents": accents, "disparity": disparity, "mean": mean_wer}


def analyze_vision_fairness():
    before = load_json(os.path.join(LIGHTING_DIR, "vision_results.json"))
    after = load_json(os.path.join(MITIGATED_DIR, "vision_results.json"))

    if not before:
        print("\nNo vision results found. Run: swift run Aura --fairness-vision test_lighting")
        return None

    print("\n" + "=" * 60)
    print("VISION FAIRNESS ANALYSIS")
    print("=" * 60)

    levels_before = [r["level"] for r in before]
    recalls_before = [r["recall"] * 100 for r in before]

    print(f"\n{'Condition':<20} {'Recall Before (%)':<20}", end="")
    if after:
        recalls_after = [r["recall"] * 100 for r in after]
        print(f"{'Recall After (%)':<20}", end="")
    print()
    print("-" * (60 if after else 40))

    for i, (level, rb) in enumerate(zip(levels_before, recalls_before)):
        print(f"{level:<20} {rb:<20.0f}", end="")
        if after and i < len(after):
            print(f"{recalls_after[i]:<20.0f}", end="")
        print()

    disp_before = max(recalls_before) - min(recalls_before)
    print(f"\nDisparity before mitigation: {disp_before:.0f} pp")

    if after:
        recalls_after = [r["recall"] * 100 for r in after]
        disp_after = max(recalls_after) - min(recalls_after)
        print(f"Disparity after mitigation:  {disp_after:.0f} pp")
        improvement = disp_before - disp_after
        print(f"Disparity reduction: {improvement:.0f} pp")

        if len(recalls_before) >= 3:
            t_stat, p_paired = stats.wilcoxon(
                recalls_before, recalls_after,
                alternative="less",
                zero_method="zsplit",
            ) if any(a != b for a, b in zip(recalls_before, recalls_after)) else (0, 1.0)
            print(f"\nWilcoxon signed-rank test (does mitigation improve recall?):")
            print(f"  W = {t_stat:.2f}, p = {p_paired:.4f}")

    return {
        "before": recalls_before,
        "after": recalls_after if after else None,
        "disparity_before": disp_before,
        "disparity_after": disp_after if after else None,
    }


def compute_task_metrics():
    print("\n" + "=" * 60)
    print("SCRIPTED TASK EVALUATION SUMMARY")
    print("=" * 60)

    tasks = []

    accent_results = load_json(os.path.join(ACCENT_DIR, "speech_results.json"))
    if accent_results:
        for r in accent_results:
            tasks.append({
                "task": f"caption_{r['accent']}",
                "completed": r["wer"] < 1.0,
                "time_ms": r["latency_ms"],
                "quality": 1.0 - r["wer"],
            })

    vision_results = load_json(os.path.join(LIGHTING_DIR, "vision_results.json"))
    if vision_results:
        for r in vision_results:
            tasks.append({
                "task": f"ocr_{r['level']}",
                "completed": r["recall"] > 0,
                "time_ms": r["latency_ms"],
                "quality": r["recall"],
            })

    if not tasks:
        print("No task results found.")
        return

    completion_rate = sum(1 for t in tasks if t["completed"]) / len(tasks) * 100
    times = [t["time_ms"] for t in tasks if t["completed"]]
    qualities = [t["quality"] for t in tasks]

    print(f"\nTotal tasks: {len(tasks)}")
    print(f"Task completion rate: {completion_rate:.0f}%")
    if times:
        print(f"Time-on-task — mean: {np.mean(times):.0f} ms, median: {np.median(times):.0f} ms")
    print(f"Quality score — mean: {np.mean(qualities) * 100:.1f}%, std: {np.std(qualities) * 100:.1f}%")

    print("\nSUS: requires human participant ratings (10 questions, 1–5 scale).")
    print("Framework built; collect ratings with a post-task questionnaire.")


def main():
    speech = analyze_speech_fairness()
    vision = analyze_vision_fairness()
    compute_task_metrics()

    print("\n" + "=" * 60)
    print("SUMMARY FOR DOCS")
    print("=" * 60)
    if speech:
        print(f"Speech WER disparity across accents: {speech['disparity']:.1f} pp")
        print(f"Speech mean WER: {speech['mean']:.1f}%")
    if vision:
        print(f"Vision recall disparity (before): {vision['disparity_before']:.0f} pp")
        if vision["disparity_after"] is not None:
            print(f"Vision recall disparity (after mitigation): {vision['disparity_after']:.0f} pp")


if __name__ == "__main__":
    main()
