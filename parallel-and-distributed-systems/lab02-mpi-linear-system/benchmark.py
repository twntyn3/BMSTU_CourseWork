"""Три запуска на 1, 2, 4, 8 и 16 процессах; CSV и медианы времён.

Запуск: python3 benchmark.py N
Перезаписывает measurements.csv и summary.csv в папке скрипта.
"""
import csv
from pathlib import Path
import statistics
import subprocess
import sys


folder = Path(__file__).resolve().parent
if len(sys.argv) != 2:
    raise SystemExit("Usage: python3 benchmark.py N")
n = int(sys.argv[1])
process_counts = [1, 2, 4, 8, 16]
repeats = 3
records = []
fields = ["repeat", "n", "epsilon", "problem", "processes", "iterations",
          "seconds", "relative_residual", "relative_error", "max_abs_error", "verified"]

with (folder / "measurements.csv").open("w", newline="") as stream:
    writer = csv.DictWriter(stream, fieldnames=fields)
    writer.writeheader()
    stream.flush()
    # Повторяем всю серию, чтобы не измерять один p только в начале или конце.
    for repeat in range(1, repeats + 1):
        for processes in process_counts:
            print(f"Repeat {repeat}/{repeats}, processes={processes}", flush=True)
            command = ["mpirun", "--host", "localhost:8", "--oversubscribe",
                       "--bind-to", "none", "-np", str(processes),
                       str(folder / "lab2"), str(n), "1e-5", "mixed"]
            result = subprocess.run(command, text=True, stdout=subprocess.PIPE, check=True)
            rows = list(csv.DictReader(result.stdout.splitlines()))
            if len(rows) != 1:
                raise RuntimeError("Expected one CSV record from the solver")
            row = rows[0]
            if (row["verified"] != "true" or int(row["n"]) != n or
                    int(row["processes"]) != processes or row["problem"] != "mixed" or
                    float(row["epsilon"]) != 1e-5):
                raise RuntimeError("Unexpected parameters or verification failure")
            row["repeat"] = repeat
            writer.writerow(row)
            stream.flush()
            records.append(row)
            print(f"  {float(row['seconds']):.3f} s, {row['iterations']} iterations", flush=True)
            if processes == 1 and float(row["seconds"]) < 30.0:
                raise SystemExit("Single-process time below 30 s. Increase N and rerun.")

summary = []
for processes in process_counts:
    selected = [r for r in records if int(r["processes"]) == processes]
    times = [float(r["seconds"]) for r in selected]
    summary.append({
        "n": n, "epsilon": 1e-5, "processes": processes, "repeats": repeats,
        "median_seconds": statistics.median(times),
        "min_seconds": min(times), "max_seconds": max(times),
        "min_iterations": min(int(r["iterations"]) for r in selected),
        "max_iterations": max(int(r["iterations"]) for r in selected),
        "max_relative_residual": max(float(r["relative_residual"]) for r in selected),
        "max_relative_error": max(float(r["relative_error"]) for r in selected),
        "oversubscribed": processes > 8,
    })
baseline = summary[0]["median_seconds"]
for row in summary:
    row["speedup"] = baseline / row["median_seconds"]
    row["efficiency_percent"] = 100.0 * row["speedup"] / row["processes"]
with (folder / "summary.csv").open("w", newline="") as stream:
    writer = csv.DictWriter(stream, fieldnames=list(summary[0]))
    writer.writeheader()
    writer.writerows(summary)
print("Saved measurements.csv and summary.csv", flush=True)
