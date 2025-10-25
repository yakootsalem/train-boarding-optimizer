import csv, math, random

# הגדרות כלליות
CARS = 6          # מספר הקרונות ברכבת
BOARD_SEC = 10    # זמן עלייה של נוסע אחד בשניות
RUNS = 500        # מספר ריצות סימולציה לכל תרחיש

# רשימת התרחישים (שם, ממוצע אורך תור, סטיית תקן)
DAY_SCENARIOS = [
    ("Morning_rush", 40, 10),   # עומס גבוה - שעות הבוקר
    ("Midday", 18, 6),          # עומס מתון - שעות הצהריים
    ("Evening_peak", 32, 9)     # עומס בינוני - שעות הערב
]

random.seed(42)  # כדי שהתוצאות יהיו קבועות בכל הרצה (לשחזור)

# פונקציה ליצירת אורכי תורים מקריים לפי התפלגות גאוסית
def gen_queue_lengths(cars, mu, sigma):
    return [max(0, round(random.gauss(mu, sigma))) for _ in range(cars)]

# חישוב זמן יציאה ללא איזון תורים (הקרון האחרון מסיים)
def time_without_project(queue):
    return max(queue) * BOARD_SEC

# חישוב זמן יציאה עם איזון תורים (חלוקה שווה של הנוסעים)
def time_with_project(queue, cars):
    total = sum(queue)
    max_after_balance = math.ceil(total / cars)  # ceil מבטיח שלא יהיה "חצי נוסע"
    return max_after_balance * BOARD_SEC

# כתיבת הנתונים לקובץ CSV
with open("train_sim.csv", "w", newline="", encoding="utf-8") as f:
    w = csv.writer(f)
    # כותרות העמודות
    w.writerow(["day_scenario", "run_idx", "cars", "board_sec", "mu", "sigma", "q_lengths",
                "T_without", "T_with", "improve_sec", "improve_pct"])

    # ריצה על כל התרחישים וכל הריצות
    for name, mu, sigma in DAY_SCENARIOS:
        for r in range(1, RUNS + 1):
            q = gen_queue_lengths(CARS, mu, sigma)
            T1 = time_without_project(q)
            T2 = time_with_project(q, CARS)
            imp = T1 - T2
            imp_pct = (imp / T1) * 100 if T1 > 0 else 0
            # כתיבת התוצאות לשורה בקובץ
            w.writerow([name, r, CARS, BOARD_SEC, mu, sigma, ";".join(map(str, q)),
                        T1, T2, imp, round(imp_pct, 2)])
