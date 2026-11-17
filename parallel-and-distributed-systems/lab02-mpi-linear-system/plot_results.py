"""Построить три графика из summary.csv: python3 plot_results.py.

Нужен matplotlib: python3 -m pip install matplotlib
"""
import csv
from pathlib import Path

import matplotlib
matplotlib.use("Agg")
import matplotlib.pyplot as plt


folder = Path(__file__).resolve().parent
with (folder / "summary.csv").open() as stream:
    rows = list(csv.DictReader(stream))
p = [int(row["processes"]) for row in rows]
seconds = [float(row["median_seconds"]) for row in rows]
speedup = [float(row["speedup"]) for row in rows]
efficiency = [float(row["efficiency_percent"]) for row in rows]
minimum = [float(row["min_seconds"]) for row in rows]
maximum = [float(row["max_seconds"]) for row in rows]
n = int(rows[0]["n"])

plt.rcParams.update({"font.family": "DejaVu Sans", "font.size": 11})
for filename, title, ylabel, values in [
    ("time.png", "Время решения системы", "Время, с", seconds),
    ("speedup.png", "Ускорение вычислений", "Ускорение Sₚ = T₁ / Tₚ", speedup),
    ("efficiency.png", "Эффективность распараллеливания", "Эффективность Sₚ / p, %", efficiency),
]:
    fig, ax = plt.subplots(figsize=(8.5, 5.5), dpi=180)
    fig.subplots_adjust(left=0.12, right=0.96, top=0.81, bottom=0.24)
    ax.plot(p, values, color="#21618c", marker="o", linewidth=2, label="Измеренные результаты")
    if filename == "time.png":
        ax.errorbar(p, values,
                    yerr=[[t-lo for t,lo in zip(seconds,minimum)],
                          [hi-t for hi,t in zip(maximum,seconds)]],
                    fmt="none", ecolor="#21618c", capsize=5)
    elif filename == "speedup.png":
        ax.plot(p[:4], p[:4], linestyle="--", color="#777777", label="Идеал Sₚ = p")
    else:
        ax.plot(p[:4], [100]*4, linestyle="--", color="#777777", label="Идеал 100 %")
    ax.scatter([16], [values[-1]], color="#b65b13", s=75, zorder=4,
               label="16 процессов на 8 ядрах")
    ax.set_xscale("log", base=2)
    ax.set_xticks(p, labels=[str(value) for value in p])
    ax.set_xlim(0.85, 19)
    ax.set_ylim(bottom=0)
    ax.set_xlabel("Число MPI-процессов p")
    ax.set_ylabel(ylabel)
    ax.grid(axis="y", alpha=0.25)
    ax.spines[["top", "right"]].set_visible(False)
    ax.legend(fontsize=9, loc="best")
    fig.suptitle(title, fontsize=16, fontweight="bold", y=0.96)
    fig.text(0.5, 0.89, f"Apple M2 · 8 ядер · N = {n} · ε = 10⁻⁵ · медианы трёх запусков",
             ha="center", fontsize=10)
    note = "16 процессов делят 8 физических ядер; это не замер на 16 ядрах."
    if filename == "time.png":
        note += "\nУсы показывают минимум и максимум трёх измерений."
    else:
        note += "\nУскорение и эффективность рассчитаны по медианам времени."
    fig.text(0.12, 0.065, note, fontsize=9, color="#444444", linespacing=1.6)
    fig.savefig(folder / filename)
    plt.close(fig)
    print(f"Saved {filename}")
