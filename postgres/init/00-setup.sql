-- 00-setup.sql
-- Runs on Database initialization.

-- Enable pg_stat_statements on the default 'postgres' database for the exporter
CREATE EXTENSION IF NOT EXISTS pg_stat_statements;
