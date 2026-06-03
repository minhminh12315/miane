-- Initialization script for PostgreSQL
-- Creates separate databases for each microservice
-- This script runs automatically when the postgres container starts for the first time

CREATE DATABASE "Miane_trip";
CREATE DATABASE "Miane_expense";
CREATE DATABASE "Miane_notification";
