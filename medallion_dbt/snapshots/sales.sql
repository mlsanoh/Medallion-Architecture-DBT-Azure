{% snapshot sales_snapshot %}

{{
    config(
      file_format = "delta",
      location_root = "abfss://silver@stcontosoanalytics.dfs.core.windows.net/sales_snapshot",
      target_schema = 'snapshots',
      invalidate_hard_deletes = True,
      unique_key = 'SalesKey',
      strategy = 'check',
      check_cols = 'all'
    )
}}

with source_data as (
    select
        sha1(concat(cast(OrderKey as string), '_', cast(LineNumber as string))) as SalesKey,
        OrderKey,
        LineNumber,
        OrderDate,
        DeliveryDate,
        CustomerKey,
        StoreKey,
        ProductKey,
        Quantity,
        UnitPrice,
        NetPrice,
        UnitCost,
        CurrencyCode,
        ExchangeRate
    from {{ source('bronze', 'sales') }}
)

select *
from source_data

{% endsnapshot %}