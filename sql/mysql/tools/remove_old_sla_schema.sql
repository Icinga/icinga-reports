--
-- Use this script to remove old tables and procedures from
-- your database that existed before the inclusion into the
-- Icinga project.
--
-- All tables normally only contain cached data.
--

DROP FUNCTION IF EXISTS icinga_state_availability;

DROP PROCEDURE IF EXISTS icinga_cache_sladata;
DROP PROCEDURE IF EXISTS icinga_refresh_slaperiods;
DROP PROCEDURE IF EXISTS icinga_update_holiday;

DROP TABLE IF EXISTS icinga_sla_periods;
DROP TABLE IF EXISTS icinga_outofsla_periods;
DROP TABLE IF EXISTS icinga_sladata_cache;

