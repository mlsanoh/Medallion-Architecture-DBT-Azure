{% snapshot currency_exchange_snapshot %}

{{
    config(
      file_format = "delta",
      location_root = "abfss://silver@stcontosoanalytics.dfs.core.windows.net/currency_exchange_snapshot",
      target_schema = 'snapshots',
      invalidate_hard_deletes = True,
      unique_key = 'exchange_key',
      strategy = 'check',
      check_cols = ['Exchange']
    )
}}

with source_data as (
    select
        sha1(concat(cast(Date as string), '_', FromCurrency, '_', ToCurrency)) as exchange_key,
        Date,
        FromCurrency,
        ToCurrency,
        Exchange
    from {{ source('bronze', 'currency_exchange') }}
)

select *
from source_data

{% endsnapshot %}