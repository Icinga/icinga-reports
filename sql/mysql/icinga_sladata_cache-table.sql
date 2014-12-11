DROP TABLE IF EXISTS icinga_sladata_cache;

CREATE TABLE icinga_sladata_cache (
  timestamp    DATETIME,
  object_id    BIGINT UNSIGNED NOT NULL,
  tp_object_id BIGINT UNSIGNED,
  start        DATETIME,
  end          DATETIME,
  seqno        BIGINT AUTO_INCREMENT,
  duration     BIGINT,
  current_state SMALLINT,
  real_state   SMALLINT,
  next_state   SMALLINT,
  addd         SMALLINT,
  dt_depth     SMALLINT,
  tp_depth     SMALLINT,
  type         VARCHAR(40),
  start_time   DATETIME,
  end_time     DATETIME,
  PRIMARY KEY (seqno),
  INDEX (timestamp),
  INDEX (object_id, tp_object_id, start, end)
);
