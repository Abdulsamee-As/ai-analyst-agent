-- Build the clean sales table from the raw CSV import (raw to clean pattern)
DROP TABLE IF EXISTS sales;

CREATE TABLE sales (
  row_id        INTEGER PRIMARY KEY,
  order_id      TEXT NOT NULL,
  order_date    DATE NOT NULL,
  ship_date     DATE NOT NULL,
  ship_mode     TEXT,
  customer_id   TEXT,
  customer_name TEXT,
  segment       TEXT,
  country       TEXT,
  city          TEXT,
  state         TEXT,
  postal_code   TEXT,
  region        TEXT,
  product_id    TEXT,
  category      TEXT,
  sub_category  TEXT,
  product_name  TEXT,
  sales         NUMERIC(12,4),
  quantity      INTEGER,
  discount      NUMERIC(4,2),
  profit        NUMERIC(12,4)
);

INSERT INTO sales (
  row_id, order_id, order_date, ship_date, ship_mode,
  customer_id, customer_name, segment, country, city, state,
  postal_code, region, product_id, category, sub_category,
  product_name, sales, quantity, discount, profit
)
SELECT
  "Row ID", "Order ID",
  TO_DATE("Order Date", 'MM/DD/YYYY'),
  TO_DATE("Ship Date", 'MM/DD/YYYY'),
  "Ship Mode", "Customer ID", "Customer Name", "Segment",
  "Country", "City", "State",
  LPAD("Postal Code"::TEXT, 5, '0'),
  "Region", "Product ID", "Category", "Sub-Category", "Product Name",
  "Sales"::NUMERIC(12,4),
  "Quantity"::INTEGER,
  "Discount"::NUMERIC(4,2),
  "Profit"::NUMERIC(12,4)
FROM raw_superstore;

ALTER TABLE sales ENABLE ROW LEVEL SECURITY;
