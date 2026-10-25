-- "Get History" node: monthly sales and profit per region and per sub-category
SELECT 'region' AS dimension, region AS name,
  DATE_TRUNC('month', order_date)::date AS month,
  ROUND(SUM(sales), 2) AS sales, ROUND(SUM(profit), 2) AS profit
FROM sales
GROUP BY region, DATE_TRUNC('month', order_date)
UNION ALL
SELECT 'sub_category', sub_category,
  DATE_TRUNC('month', order_date)::date,
  ROUND(SUM(sales), 2), ROUND(SUM(profit), 2)
FROM sales
GROUP BY sub_category, DATE_TRUNC('month', order_date)
ORDER BY dimension, name, month;
