# Postgres tool description (what the agent knows about the database)

```
Runs a read-only SQL query on a PostgreSQL database and returns the results.

Table: sales (one row = one product line inside an order)
Columns:
- order_id (text), order_date (date), ship_date (date), ship_mode (text)
- customer_id (text), customer_name (text), segment (text)
- country (text), city (text), state (text), postal_code (text), region (text)
- product_id (text), category (text), sub_category (text), product_name (text)
- sales (numeric), quantity (integer), discount (numeric, 0.2 means 20%), profit (numeric)

Notes:
- Data covers 2014-01-03 to 2017-12-30. The latest month is December 2017.
- One order can have many rows, so use COUNT(DISTINCT order_id) to count orders.
- Only SELECT queries are allowed.
- Always aggregate with GROUP BY or add LIMIT 20, never return thousands of rows.
- Never use SELECT *. Select only the columns you need.
- Always return 20 rows or fewer. Prefer GROUP BY summaries over raw rows.
- Filter to only the sub-categories or regions you are investigating, using WHERE.
- Round all numbers to 2 decimals with ROUND().
```
