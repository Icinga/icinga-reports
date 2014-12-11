
DROP PROCEDURE IF EXISTS icinga_sla_set_holiday;

DELIMITER $$

CREATE PROCEDURE icinga_sla_set_holiday((
    IN tp_object_id BIGINT UNSIGNED,
    IN t_date DATE
)
BEGIN
  DECLARE t_start DATETIME;
  DECLARE t_end DATETIME;

  -- generate start and end timestamp
  SELECT TIMESTAMP(t_date) INTO t_start;
  SELECT TIMESTAMP(DATE_ADD(t_date, INTERVAL 1 DAY)) INTO t_end;

  -- clean existing definitions for that day
  DELETE FROM icinga_sla_periods_outofsla
  WHERE timeperiod_object_id = tp_object_id
    AND start_time >= t_start
    AND end_time <= t_end;

  -- insert out of sla data for that holiday
  INSERT INTO icinga_sla_periods_outofsla
    (timeperiod_object_id, start_time, end_time)
  VALUES
    (tp_object_id, t_start, t_end);

  -- output
  SELECT
    tp_object_id AS timeperiod_object_id,
    t_start AS start_time,
    t_end AS end_time;

END;
$$
DELIMITER ;
