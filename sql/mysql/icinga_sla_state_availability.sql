DELIMITER //

DROP FUNCTION IF EXISTS icinga_sla_state_availability//

CREATE FUNCTION icinga_sla_state_availability(
  obj_id       BIGINT UNSIGNED,
  state        SMALLINT,
  t_start      DATETIME,
  t_end        DATETIME,
  tp_object_id BIGINT UNSIGNED
)
  RETURNS DOUBLE
  READS SQL DATA
BEGIN
  DECLARE result DOUBLE;
  SET @tp_object_id := tp_object_id;

  -- make sure we have cache
  CALL icinga_sla_cache_events(obj_id, t_start, t_end, tp_object_id);

  SELECT sla INTO result FROM (
  SELECT
    SUM(CASE WHEN current_state = state THEN duration ELSE 0 END) / (UNIX_TIMESTAMP(t_end) - UNIX_TIMESTAMP(t_start)) AS sla
  FROM icinga_sla_eventcache
  WHERE object_id = obj_id
    AND start = t_start
    AND end = t_end
    AND (tp_object_id = tp_object_id OR (@tp_object_id IS NULL AND tp_object_id IS NULL))
  ORDER BY seqno ASC) as summary;

  RETURN result;
END//

DELIMITER ;
