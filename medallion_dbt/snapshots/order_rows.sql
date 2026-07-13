{% snapshot order_rows_snapshot %}

{{
    config(
      file_format = "delta",
      location_root = "abfss://silver@stcontosoanalytics.dfs.core.windows.net/order_rows_snapshot",
      target_schema = 'snapshots',
      invalidate_hard_deletes = True,
      unique_key = 'OrderRowKey',
      strategy = 'check',
      check_cols = 'all'
    )
}}

with source_data as (
    select
        sha1(concat(cast(OrderKey as string), '_', cast(LineNumber as string))) as OrderRowKey,
        OrderKey,
        LineNumber,
        ProductKey,
        Quantity,
        UnitPrice,
        NetPrice,
        UnitCost
    from {{ source('bronze', 'order_rows') }}
)

select *
from source_data

{% endsnapshot %}