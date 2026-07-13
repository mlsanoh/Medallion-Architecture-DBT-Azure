{% snapshot store_snapshot %}

{{
    config(
      file_format = "delta",
      location_root = "abfss://silver@stcontosoanalytics.dfs.core.windows.net/store_snapshot",
      target_schema = 'snapshots',
      invalidate_hard_deletes = True,
      unique_key = 'StoreKey',
      strategy = 'check',
      check_cols = 'all'
    )
}}

with source_data as (
    select
        StoreKey,
        StoreCode,
        GeoAreaKey,
        CountryCode,
        CountryName,
        State,
        OpenDate,
        CloseDate,
        Description,
        SquareMeters,
        Status
    from {{ source('bronze', 'store') }}
)

select *
from source_data

{% endsnapshot %}