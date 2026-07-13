{% snapshot date_snapshot %}

{{
    config(
      file_format = "delta",
      location_root = "abfss://silver@stcontosoanalytics.dfs.core.windows.net/date_snapshot",
      target_schema = 'snapshots',
      invalidate_hard_deletes = True,
      unique_key = 'DateKey',
      strategy = 'check',
      check_cols = 'all'
    )
}}

with source_data as (
    select
        Date,
        DateKey,
        Year,
        YearQuarter,
        YearQuarterNumber,
        Quarter,
        YearMonth,
        YearMonthShort,
        YearMonthNumber,
        Month,
        MonthShort,
        MonthNumber,
        DayofWeek,
        DayofWeekShort,
        DayofWeekNumber,
        WorkingDay,
        WorkingDayNumber
    from {{ source('bronze', 'date') }}
)

select *
from source_data

{% endsnapshot %}