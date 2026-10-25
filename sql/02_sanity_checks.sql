SELECT
  COUNT(*)                                       AS total_rows,
  MIN(order_date)                                AS first_order,
  MAX(order_date)                                AS last_order,
  ROUND(SUM(sales), 2)                           AS total_sales,
  ROUND(SUM(profit), 2)                          AS total_profit,
  COUNT(*) FILTER (WHERE postal_code IS NULL)    AS missing_postal,
  COUNT(*) FILTER (WHERE ship_date < order_date) AS shipped_before_ordered,
  COUNT(*) FILTER (WHERE sales <= 0)             AS zero_or_negative_sales
FROM sales;
-- Result: 9994 rows, 2014-01-03 to 2017-12-30, sales 2297200.86, profit 286397.02, all checks 0
