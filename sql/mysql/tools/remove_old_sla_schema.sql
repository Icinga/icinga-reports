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




DROP FUNCTION IF EXISTS icinga_sla_state_availability(
DROP PROCEDURE IF EXISTS icinga_debug_sladetail(
DROP PROCEDURE IF EXISTS icinga_get_sladetail(
DROP PROCEDURE IF EXISTS icinga_sla_cache_events(
DROP PROCEDURE IF EXISTS icinga_sla_refresh_periods()
DROP PROCEDURE IF EXISTS icinga_sla_set_holiday(
DROP TABLE IF EXISTS icinga_sla_eventcache (
DROP TABLE IF EXISTS icinga_sla_periods_outofsla (
