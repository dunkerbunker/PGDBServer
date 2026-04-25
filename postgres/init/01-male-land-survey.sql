-- 01-male-land-survey.sql
-- Initializes the male-land-survey project.

-- 1. Create Prod Resources
CREATE ROLE mls_prod_user WITH LOGIN PASSWORD 'CHANGE_ME_PROD_DB_PASSWORD';
CREATE DATABASE male_land_survey_prod;
GRANT ALL PRIVILEGES ON DATABASE male_land_survey_prod TO mls_prod_user;

-- Connect to Prod DB and enable PostGIS + adjust schemas
\connect male_land_survey_prod;
CREATE EXTENSION IF NOT EXISTS postgis;
-- Grant ownership of public schema
ALTER SCHEMA public OWNER TO mls_prod_user;

-- 2. Create Staging Resources  
CREATE ROLE mls_staging_user WITH LOGIN PASSWORD 'CHANGE_ME_STAGING_DB_PASSWORD';
CREATE DATABASE male_land_survey_staging;
GRANT ALL PRIVILEGES ON DATABASE male_land_survey_staging TO mls_staging_user;

-- Connect to Staging DB and enable PostGIS + adjust schemas
\connect male_land_survey_staging;
CREATE EXTENSION IF NOT EXISTS postgis;
ALTER SCHEMA public OWNER TO mls_staging_user;
