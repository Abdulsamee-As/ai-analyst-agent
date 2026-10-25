-- Manual check of the agent's Appliances finding
SELECT region,
  ROUND(SUM(sales), 2)          AS sales,
  ROUND(SUM(profit), 2)         AS profit,
  ROUND(AVG(discount) * 100, 1) AS avg_discount_pct
FROM sales
WHERE sub_category = 'Appliances' AND order_date >= '2017-12-01'
GROUP BY region
ORDER BY profit;
-- Central 2591.53 / -427.00 / 40.0   West 423.42 / 130.94 / 4.0
-- South 640.00 / 172.91 / 10.0       East 2861.88 / 813.59 / 2.9
