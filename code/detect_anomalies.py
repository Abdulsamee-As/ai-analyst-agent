# n8n Code node (Python, Run Once for All Items)
# Flags the latest month for each region and sub-category if its z-score is above 2 or below -2.
# n8n Cloud Python cannot import libraries, so mean and std are calculated by hand.

rows = [item["json"] for item in _items]
latest_month = max(row["month"] for row in rows)

groups = {}
for row in rows:
    key = (row["dimension"], row["name"])
    if key not in groups:
        groups[key] = []
    groups[key].append(row)

anomalies = []
Z_LIMIT = 2
MIN_HISTORY = 6

for (dimension, name), group_rows in groups.items():
    current = [r for r in group_rows if r["month"] == latest_month]
    history = [r for r in group_rows if r["month"] != latest_month]
    if len(current) == 0 or len(history) < MIN_HISTORY:
        continue

    for metric in ["sales", "profit"]:
        values = [float(r[metric]) for r in history]
        current_value = float(current[0][metric])
        mean = sum(values) / len(values)
        variance = sum((v - mean) ** 2 for v in values) / (len(values) - 1)
        std = variance ** 0.5
        if std == 0:
            continue
        z = (current_value - mean) / std
        if abs(z) > Z_LIMIT:
            anomalies.append({
                "dimension": dimension,
                "name": name,
                "metric": metric,
                "current_value": round(current_value, 2),
                "normal_average": round(mean, 2),
                "std_dev": round(std, 2),
                "z_score": round(z, 2),
                "direction": "above normal" if z > 0 else "below normal"
            })

anomalies = sorted(anomalies, key=lambda a: abs(a["z_score"]), reverse=True)

return [{
    "json": {
        "report_month": str(latest_month)[:7],
        "anomaly_count": len(anomalies),
        "anomalies": anomalies
    }
}]
