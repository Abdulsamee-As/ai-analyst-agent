-- Read-only role for the AI agent (least privilege)
-- Replace the placeholder with a strong password. Never commit the real one.
CREATE ROLE ai_reader WITH LOGIN PASSWORD 'CHANGE_ME';
GRANT USAGE ON SCHEMA public TO ai_reader;
GRANT SELECT ON public.sales TO ai_reader;
CREATE POLICY ai_reader_can_read ON public.sales FOR SELECT TO ai_reader USING (true);
ALTER ROLE ai_reader SET statement_timeout = '10s';
