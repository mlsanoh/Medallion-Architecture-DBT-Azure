{% snapshot product_snapshot %}

{{
    config(
      file_format = "delta",
      location_root = "abfss://silver@stcontosoanalytics.dfs.core.windows.net/product_snapshot",
      target_schema = 'snapshots',
      invalidate_hard_deletes = True,
      unique_key = 'ProductKey',
      strategy = 'check',
      check_cols = 'all'
    )
}}

with source_data as (
    select
        ProductKey,
        ProductCode,
        ProductName,
        Manufacturer,
        Brand,
        Color,
        WeightUnit,
        Weight,
        Cost,
        Price,
        CategoryKey,
        CategoryName,
        SubCategoryKey,
        SubCategoryName
    from {{ source('bronze', 'product') }}
)

select *
from source_data

{% endsnapshot %}