{% snapshot customer_snapshot %}

{{
    config(
      file_format = "delta",
      location_root = "abfss://silver@stcontosoanalytics.dfs.core.windows.net/customer_snapshot",
      target_schema = 'snapshots',
      invalidate_hard_deletes = True,
      unique_key = 'CustomerKey',
      strategy = 'check',
      check_cols = ['StreetAddress', 'City', 'State', 'ZipCode', 'Occupation', 'Company']
    )
}}

with source_data as (
    select
        CustomerKey,
        GeoAreaKey,
        StartDT,
        EndDT,
        Continent,
        Gender,
        Title,
        GivenName,
        MiddleInitial,
        Surname,
        StreetAddress,
        City,
        State,
        StateFull,
        ZipCode,
        Country,
        CountryFull,
        Birthday,
        Age,
        Occupation,
        Company,
        Vehicle,
        Latitude,
        Longitude
    from {{ source('bronze', 'customer') }}
)

select *
from source_data

{% endsnapshot %}