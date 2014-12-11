SLA Availability Reporting
==========================

Icinga's SLA reporting consists of the following components:

 * SQL schema extension
  - cache tables
  - procedures to update caches
  - function to query SLA values
 * Jasper example reports

Requirements
------------

What is required to run the SLA reporting?

 * Icinga 1 or 2
 * with enabled IDO export
 * and especially "state history" enabled (which is default)
 * laying in a MySQL database

While Icinga supports other databases, the SLA analysis has only been written
for MySQL.

Installation
------------

### Extend the IDO

The schema extension will add some tables, procedures and functions.
See [details](#SQL schema components) below for more information.

```
cat sql/mysql/*.sql | mysql icinga
```

This also works for updating and will replace the existing elements.

### Cleanup old SLA stuff

If you tried one of the older versions of this SLA reporting the schema names
were different.

To clean this up you can use a SQL script to remove those tables and functions.

Normally these tables only provide cache, so there is no sensible data.

```
mysql icinga < sql/mysql/tools/remove_old_sla_schema.sql
```

### Jasper Server

An example report with SLA data is included in the JasperReports examples set.

SQL schema components
---------------------

The following schema components belong to this SQL reporting:

| name                          | type      | purpose                                                         |
| ----------------------------- | --------- | --------------------------------------------------------------- |
| icinga_sla_eventcache         | table     | Cache table for calculated events                               |
| icinga_sla_periods_outofsla   | table     | Cache of periods that count as out-of-SLA                       |
| icinga_sla_cache_events       | procedure | Calculate (SLA relevant) events in the requested period         |
| icinga_sla_refresh_periods    | procedure | Fill the periods cache with data based on Icinga's time periods |
| icinga_sla_set_holiday        | procedure | Set a single day to be a holiday - as out-of-SLA                |
| icinga_sla_state_availability | function  | Get the SLA values while using a cache                          |

The directly used component is usually *icinga_sla_state_availability*.

How to query
------------

You can query the SLA values in a SQL join context, meaning you can query the
values within any SELECT.

Here is an example:

``` sql
SELECT
  name1,
  icinga_sla_state_availability(
    object_id,
    0,
    '2014-10-01',
    '2014-11-01',
    NULL
  ) * 100 AS state_ok
FROM icinga_objects
WHERE
  is_active = 1
  AND objecttype_id = 1;
```

The function itself has the following arguments:

| # | parameter   | type            | description                                                  |
| - | ----------- | --------------- | -------------------------------------------------------------|
| 1 | object_id   | BIGINT UNSIGNED | object id of the host or service                             |
| 2 | state       | SMALLINT        | state id which you want to retrieve percentage for           |
| 3 | start_time  | DATETIME        | start of time frame                                          |
| 4 | end_time    | DATETIME        | end of time frame                                            |
| 5 | timeperiod  | BIGINT UNSIGNED | time period object id to limit on a SLA period (can be NULL) |

The returned value is a float between 0 and 1, 0.85 meaning 85% of that state
in the time period.

State IDs are as follows:

| # | service  | host        |
| - | -------- | ----------- |
| 0 | OK       | UP          |
| 1 | WARNING  | DOWN        |
| 2 | CRITICAL | UNREACHABLE |
| 3 | UNKNOWN  | --          |

Whats neat about our cached implementation here is that you can use the query
function multiple times, while it is generated cached event once per object_id.

Maintain SLA periods
--------------------

The so called out-of-SLA periods can be calculated based on the time periods
Icinga knows.

There is a procedure refreshing that data for the current year until 4 years
into the future.

``` sql
CALL icinga_sla_refresh_periods();
```

Check the table *icinga_sla_periods_outofsla* for generated data.

The utility function *icinga_sla_set_holiday* can be used to declare a certain
day as an holiday, setting it out-of-SLA.

``` sql
CALL icinga_sla_set_holiday(1234, '2014-12-25');
```

You can lookup time periods in the object table:

``` sql
SELECT object_id, name1 FROM icinga_objects WHERE objecttype_id = 9;
```

**Note:** You always need to re-apply your manual holidays or any other
modifications after running *icinga_sla_refresh_periods*!

## Limitations

TODO

How it works
------------

This chapter tries to describe how the SLA calculation works.

TODO

Manually use the cached data
----------------------------

TODO
