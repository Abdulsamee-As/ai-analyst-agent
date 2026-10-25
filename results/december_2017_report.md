# Real output: December 2017 run

## KPIs
- Sales: $83,829.32
- Sales growth vs November: -29.23%
- Profit: $8,483.35
- Margin: 10.12%

## Agent summary
Overall sales for December 2017 reached $83,829.32 with a healthy net profit margin of 10.12%. Storage profits surged to $1,394.12 due to disciplined pricing and low discounts of 2% in the West region. However, while Appliances sales grew to $6,516.83, excessive discounting of 40% in the Central region caused a $427.00 loss that requires tighter promotional controls.

## Finding 1 (medium): Storage Sub-Category Profit Spike
- What happened: Storage profit reached $1,394.12 in December 2017, well above the normal monthly average of $423.08 (z-score 2.71).
- Likely cause: Strong West region volume ($5,653.22 across 67 units) with an average discount of about 2%.
- Recommendation: Keep low discount thresholds for Storage in high-performing regions and apply similar controls elsewhere.

## Finding 2 (high): Appliances Sales Growth and Discount Losses
- What happened: Appliances sales reached $6,516.83, compared to a normal average of $2,149.26 (z-score 2.54).
- Likely cause: Volume driven by East and Central, but a 40% average discount in Central produced a $427.00 loss.
- Recommendation: Cap Appliance discounts in Central at 20%.

## Manual verification (SQL)

| Region  | Sales    | Profit  | Avg discount |
|---------|----------|---------|--------------|
| Central | 2,591.53 | -427.00 | 40.0%        |
| West    | 423.42   | 130.94  | 4.0%         |
| South   | 640.00   | 172.91  | 10.0%        |
| East    | 2,861.88 | 813.59  | 2.9%         |

The agent's claim matched exactly.

## insights_log rows saved automatically
| id | title | severity |
|----|-------|----------|
| 1 | Storage Sub-Category Profit Spike | medium |
| 2 | Appliances Sales Growth and Discount Losses | high |
