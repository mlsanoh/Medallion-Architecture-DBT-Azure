{% snapshot orders_snapshot %}

{{
    config(
      file_format = "delta",
      location_root = "abfss://silver@stcontosoanalytics.dfs.core.windows.net/orders_snapshot",
      target_schema = 'snapshots',
      invalidate_hard_deletes = True,
      unique_key = 'OrderKey',
      strategy = 'check',
      check_cols = 'all'
    )
}}

with source_data as (
    select
        OrderKey,
        CustomerKey,
        StoreKey,
        OrderDate,
        DeliveryDate,
        CurrencyCode
    from {{ source('bronze', 'orders') }}
)

select *
from source_data

{% endsnapshot %}