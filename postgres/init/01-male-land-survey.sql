-- 01-male-land-survey.sql
-- Initializes the male-land-survey project.

-- 1. Create Prod Resources
CREATE ROLE mls_prod_user WITH LOGIN CREATEDB PASSWORD 'MLS_PRD_Hero9876';
CREATE DATABASE male_land_survey_prod;
GRANT ALL PRIVILEGES ON DATABASE male_land_survey_prod TO mls_prod_user;

-- Connect to Prod DB and enable PostGIS + adjust schemas
\connect male_land_survey_prod;
CREATE EXTENSION IF NOT EXISTS postgis;
CREATE SCHEMA IF NOT EXISTS mls;
ALTER SCHEMA mls OWNER TO mls_prod_user;
ALTER ROLE mls_prod_user SET search_path TO mls, public;

-- 2. Create Staging Resources  
CREATE ROLE mls_staging_user WITH LOGIN CREATEDB PASSWORD 'MLS_STG_Hero9876';
CREATE DATABASE male_land_survey_staging;
GRANT ALL PRIVILEGES ON DATABASE male_land_survey_staging TO mls_staging_user;

-- Connect to Staging DB and enable PostGIS + adjust schemas
\connect male_land_survey_staging;
CREATE EXTENSION IF NOT EXISTS postgis;
CREATE SCHEMA IF NOT EXISTS mls;
ALTER SCHEMA mls OWNER TO mls_staging_user;
ALTER ROLE mls_staging_user SET search_path TO mls, public;
