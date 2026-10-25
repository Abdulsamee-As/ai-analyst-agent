-- "get KPI" node: all KPIs for the latest month vs the previous month, returned as ONE item
WITH latest AS (
  SELECT DATE_TRUNC('month', MAX(order_date))::date AS current_month FROM sales
),
base AS (
  SELECT s.*,
    CASE WHEN s.order_date >= l.current_month THEN 'cur' ELSE 'prev' END AS period
  FROM sales s CROSS JOIN latest l
  WHERE s.order_date >= l.current_month - INTERVAL '1 month'
),
overall AS (
  SELECT
    SUM(sales)  FILTER (WHERE period = 'cur')  AS sales_cur,
    SUM(sales)  FILTER (WHERE period = 'prev') AS sales_prev,
    SUM(profit) FILTER (WHERE period = 'cur')  AS profit_cur,
    SUM(profit) FILTER (WHERE period = 'prev') AS profit_prev,
    COUNT(DISTINCT order_id) FILTER (WHERE period = 'cur')  AS orders_cur,
    COUNT(DISTINCT order_id) FILTER (WHERE period = 'prev') AS orders_prev
  FROM base
),
by_region AS (
  SELECT region,
    SUM(sales)  FILTER (WHERE period = 'cur')  AS sales_cur,
    SUM(sales)  FILTER (WHERE period = 'prev') AS sales_prev,
    SUM(profit) FILTER (WHERE period = 'cur')  AS profit_cur,
    SUM(profit) FILTER (WHERE period = 'prev') AS profit_prev
  FROM base GROUP BY region
),
by_sub AS (
  SELECT category, sub_category,
    SUM(sales)    FILTER (WHERE period = 'cur')  AS sales_cur,
    SUM(sales)    FILTER (WHERE period = 'prev') AS sales_prev,
    SUM(profit)   FILTER (WHERE period = 'cur')  AS profit_cur,
    SUM(profit)   FILTER (WHERE period = 'prev') AS profit_prev,
    AVG(discount) FILTER (WHERE period = 'cur')  AS avg_discount_cur
  FROM base GROUP BY category, sub_category
),
loss_products AS (
  SELECT product_name, sub_category,
    STRING_AGG(DISTINCT region, ', ') AS regions,
    SUM(quantity) AS units_sold, SUM(sales) AS sales,
    SUM(profit) AS profit, AVG(discount) AS avg_discount
  FROM base WHERE period = 'cur'
  GROUP BY product_name, sub_category
  HAVING SUM(profit) < 0
  ORDER BY SUM(profit) ASC
  LIMIT 10
)
SELECT
  (SELECT TO_CHAR(current_month, 'YYYY-MM') FROM latest) AS report_month,
  (SELECT json_build_object(
      'sales_cur', ROUND(sales_cur, 2),
      'sales_prev', ROUND(sales_prev, 2),
      'sales_growth_pct', ROUND((sales_cur - sales_prev) / NULLIF(sales_prev, 0) * 100, 2),
      'profit_cur', ROUND(profit_cur, 2),
      'profit_prev', ROUND(profit_prev, 2),
      'margin_cur_pct', ROUND(profit_cur / NULLIF(sales_cur, 0) * 100, 2),
      'margin_prev_pct', ROUND(profit_prev / NULLIF(sales_prev, 0) * 100, 2),
      'orders_cur', orders_cur,
      'orders_prev', orders_prev
   ) FROM overall) AS overall,
  (SELECT json_agg(json_build_object(
      'region', region,
      'sales_cur', ROUND(sales_cur, 2),
      'sales_growth_pct', ROUND((sales_cur - sales_prev) / NULLIF(sales_prev, 0) * 100, 2),
      'profit_cur', ROUND(profit_cur, 2),
      'margin_cur_pct', ROUND(profit_cur / NULLIF(sales_cur, 0) * 100, 2),
      'margin_prev_pct', ROUND(profit_prev / NULLIF(sales_prev, 0) * 100, 2)
   ) ORDER BY sales_cur DESC) FROM by_region) AS by_region,
  (SELECT json_agg(json_build_object(
      'category', category,
      'sub_category', sub_category,
      'sales_cur', ROUND(sales_cur, 2),
      'sales_growth_pct', ROUND((sales_cur - sales_prev) / NULLIF(sales_prev, 0) * 100, 2),
      'profit_cur', ROUND(profit_cur, 2),
      'profit_prev', ROUND(profit_prev, 2),
      'margin_cur_pct', ROUND(profit_cur / NULLIF(sales_cur, 0) * 100, 2),
      'avg_discount_cur_pct', ROUND(avg_discount_cur * 100, 1)
   ) ORDER BY profit_cur ASC) FROM by_sub) AS by_sub_category,
  (SELECT COALESCE(json_agg(json_build_object(
      'product_name', product_name,
      'sub_category', sub_category,
      'regions', regions,
      'units_sold', units_sold,
      'sales', ROUND(sales, 2),
      'profit', ROUND(profit, 2),
      'avg_discount_pct', ROUND(avg_discount * 100, 1)
   ) ORDER BY profit ASC), '[]'::json) FROM loss_products) AS loss_products;
