CREATE TABLE insights_log (
  id              BIGSERIAL PRIMARY KEY,
  run_at          TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  report_month    TEXT NOT NULL,
  title           TEXT NOT NULL,
  what_happened   TEXT,
  likely_cause    TEXT,
  recommendation  TEXT,
  severity        TEXT CHECK (severity IN ('high', 'medium', 'low'))
);
ALTER TABLE insights_log ENABLE ROW LEVEL SECURITY;
