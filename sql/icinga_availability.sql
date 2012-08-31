
-- ----------------------------------------------- --
-- SLA function for Icinga/IDO                     --
--                                                 --
-- Author    : Thomas Gelf <thomas@gelf.net>       --
-- Copyright : 2012 Netways <support@netways.de>   --
-- License   : GPL 2.0                             --
-- ----------------------------------------------- --
#
# History
# 
# added to Icinga @ 8/31/2012
#

DELIMITER |

DROP FUNCTION IF EXISTS icinga_availability|
CREATE FUNCTION icinga_availability (id BIGINT UNSIGNED, start DATETIME, end DATETIME)
  RETURNS DECIMAL(7, 4)
    READS SQL DATA
BEGIN
  DECLARE availability DECIMAL(7, 4);
  DECLARE type_id INT;
  DECLARE dummy INT;

  SELECT objecttype_id INTO type_id FROM icinga_objects WHERE object_id = id;

  -- We'll use @-Vars, this allows easy testing of subqueries without a function
  SELECT @former_id INTO dummy FROM (
      SELECT @former_id := @id, @former_start := @start, @former_end := @end,
             @id := id, @start := start, @end := end FROM DUAL
  ) dummy;

  SELECT
    -- Let's pick up the first valid value...
    COALESCE(
    -- ...beginning with the sum of all found state durations
    CAST(SUM(
      state.duration
      /
      -- ... divided through the chosen time period duration...
      (UNIX_TIMESTAMP(@end) - UNIX_TIMESTAMP(@start))
      -- ...multiplying the result with 100 (%)...
      * 100
      -- ...ignoring all but OK, WARN or UP states...
      * IF (type_id = 1, IF(state.current_state = 0, 1, 0), IF (state.current_state < 2, 1, 0))
    ) AS DECIMAL(7, 4)),

    -- We didn't find a single event? Well, there are alternatives:

    -- Let's look whether there is a newer event, we'll us it's last hard state
    (SELECT IF(
      -- A host has to be up, a service may be warning too...
      (type_id = 1 AND last_state = 0) OR (type_id = 2 AND last_state IN (0, 1)),
      -- So if we get a match, and it is fine,
      -- set this states percentage to 100%...
      100,
      -- ...0% otherwise
      0)
      FROM icinga_statehistory
      WHERE object_id = @id AND state_time > @end
      ORDER BY state_time ASC LIMIT 1
      -- Of course, this part is also NULL if there is no matching newer state.
      -- And there is room for improvement, we should check how long the state
      -- is lasting and calculate a correct percentage.
    ),

    -- Still nothing? Well, we have one last chance. Have a look at the current
    -- host or service state, pick it if it lasting long enough. Same game here:
    -- it would be better to agree on how to deal with a correctly calculated
    -- percentage paying attention to the state duration
    IF(
      type_id = 1,
      (SELECT IF(last_hard_state = 0, 100, 0)
       FROM icinga_hoststatus
       WHERE last_hard_state_change < @start
        AND last_hard_state = 0
        AND host_object_id = @id
      ),
      (SELECT IF(last_hard_state IN (0, 1), 100, 0)

       FROM icinga_servicestatus
       WHERE last_hard_state_change < @start
         AND service_object_id = @id
      )
    )
  ) INTO availability FROM (

-- fetch all states, downtimes ecc
SELECT
  IF(
    -- If we have no former state (will happen when starting with a downtime)
    COALESCE(@last_state, last_state) IS NULL,
    -- ...remember the duration and return 0...
    (@add_duration := COALESCE(@add_duration, 0)
      + UNIX_TIMESTAMP(state_time)
      - UNIX_TIMESTAMP(COALESCE(@last_ts, @start))
    ) * 0,
    -- ...otherwise return a correct duration...
    UNIX_TIMESTAMP(state_time)
      - UNIX_TIMESTAMP(COALESCE(@last_ts, @start))
      -- ...and don't forget to add what we remembered 'til now:
      + COALESCE(@add_duration, 0)
  ) AS duration,

  -- current_state is the state from the last state change until now:
  CASE type
    -- If we have a state change, use the either @last_state or our last_state
    -- column if the former has not yet defined
    WHEN 'hard_state' THEN IF(@cnt_dt >= 1, 0, COALESCE(@last_state, last_state))

    -- ...this is also true for soft states. Helps us to ship around an Icinga
    -- bug sometimes setting erraneous last_hard_state values
    WHEN 'soft_state' THEN IF(@cnt_dt >= 1, 0, COALESCE(@last_state, last_state))
    
    -- Use @last_state as is if a downtime starts. If it is NULL don't worry,
    -- duration has been adjusted above
    WHEN 'dt_start' THEN @last_state

    -- Set @last_state to 0 if we are in a downtime and have no @last_state
    -- This is not 100% correct as it fakes OK for the time period after an
    -- initial downtime with no former event. I'll rethink this later.
    -- One far day.
    WHEN 'dt_end' THEN COALESCE(@last_state, 0)
  END AS current_state,

  -- next_state is the state from now on, so it replaces @last_state:
  CASE type
    -- Set our next @last_state if we have a hard state change
    WHEN 'hard_state' THEN @last_state := state
    -- ...or if there is a soft_state and no @last_state has been seen before
    WHEN 'soft_state' THEN IF(
      -- If we don't have a @last_state...
      COALESCE(@last_state, NULL) IS NULL,
      -- ...use and set our own last_hard_state (last_state is an alias here)...
      @last_state:= last_state,
      -- ...and return @last_state otherwise, as soft states shall have no
      -- impact on availability
      @last_state
    )
      -- You're right, the COALESCE is useless here. Nonetheless, please leave
      -- it as is. I've seen pretty strange behaviour witholder MySQL versions
      -- for constructs such as IF(@emty_var IS NULL, ...)
    WHEN 'dt_start' THEN 0
    WHEN 'dt_end' THEN @last_state + 0
  END AS next_state,

  -- Our start_time is either the last end_time or @start...
  COALESCE(@last_ts, @start) AS start_time,

  -- ...end when setting the new end_time we remember it in @last_ts:
  @last_ts := state_time AS end_time,

  -- Use a dummy column for different row cleanup jobs.
  -- First raise or lower our downtime counter
  CASE type
    WHEN 'dt_start' THEN @cnt_dt := COALESCE(@cnt_dt, 0) + 1
    WHEN 'dt_end' THEN @cnt_dt := GREATEST(@cnt_dt - 1, 0)
    ELSE @cnt_dt
  END
  -- Then set @add_duration to NULL in case we got a new @last_state
  + COALESCE(
    IF(
      COALESCE(@last_state, last_state) IS NULL,
      0,
      @add_duration := null
    ),
    0
  ) AS dummy,

  -- Also fetch the event type
  type

FROM (

-- Fetch all statehistory events...
SELECT
   state_time,
   IF(state_type = 1, 'hard_state', 'soft_state') AS type,
   state,
   -- Workaround for a nasty Icinga issue. In case a hard state is reached
   -- before max_check_attempts, the last_hard_state value is wrong. As of
   -- this we are stepping through all single events, even soft ones. Of
   -- course soft states do not have an influence on the availability:
   IF(state_type = 1, last_state, last_hard_state) AS last_state
FROM icinga_statehistory
WHERE object_id = @id
  AND state_time >= @start
  AND state_time <= @end
  -- AND (state_type = 1 OR (state = 0 AND last_state > 0))

-- Add all related downtime start times...
UNION SELECT
  GREATEST(actual_start_time, @start) AS state_time,
  'dt_start' AS type,
  NULL AS state,
  NULL AS last_state
FROM icinga_downtimehistory
WHERE object_id = @id
  AND actual_start_time < @end
  AND actual_end_time > @start

-- ...and also all downtime end times to the mix
UNION SELECT
  LEAST(actual_end_time, @end) AS state_time,
  'dt_end' AS type,
  NULL AS state,
  NULL AS last_state
FROM icinga_downtimehistory
WHERE object_id = @id
  AND actual_start_time < @end
  AND actual_end_time > @start

-- TODO: Handling downtimes still being active would be nice.
--       But pay attention: they could be completely outdated

ORDER BY state_time ASC
) events
-- OK, we got the single history events, now add downtimes to the mix...

    -- retrieve the state for the last time period
    UNION SELECT
     UNIX_TIMESTAMP(@end) - UNIX_TIMESTAMP(IF(@last_state IS NULL, @start, @last_ts)) AS duration,
     @last_state AS current_state,
     @last_state AS next_state,
     @last_ts AS start_time,
     @end AS end_time,
     NULL AS dummy,
     NULL AS type
    FROM DUAL
    WHERE @end > @last_ts

    -- clear @last_ts and @last_state
    UNION SELECT
      0 AS duration,
      0 AS current_state,
      0 AS next_state,
      0 AS start_time,
      0 AS end_time,
      NULL AS type,
      NULL AS dummy
    FROM DUAL WHERE @last_ts IN (
      SELECT (@last_state := @last_ts := @cnt_dt := @add_duration := NULL) + 1 FROM DUAL
    )

) state

  WHERE state.current_state = 0;

  -- Restore other vars
  SELECT @id INTO dummy FROM (
     SELECT @id := @former_id, @start := @former_start,
            @end := @former_end FROM DUAL
  ) dummy;
  
  RETURN availability;
END|

DELIMITER ;


