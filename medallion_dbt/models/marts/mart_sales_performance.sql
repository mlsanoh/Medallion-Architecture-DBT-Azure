-- Les revenus totaux, les coûts et les marges nettes réelles par mois, par magasin et par catégorie de produit après conversion des devises

{{
    config(
        materialized = 'table',
        schema = 'marts',
        file_format = 'delta',
        location_root = 'abfss://gold@stcontosoanalytics.dfs.core.windows.net/'
    )
}}

with sales_fact as (
    select
        OrderKey,
        OrderDate,
        CustomerKey,
        StoreKey,
        ProductKey,
        Quantity,
        UnitPrice,
        NetPrice,
        UnitCost,
        CurrencyCode,
        ExchangeRate
    from {{ ref('sales_snapshot') }}
    where dbt_valid_to is null
),

product_dim as (
    select
        ProductKey,
        ProductCode,
        ProductName,
        Manufacturer,
        Brand,
        CategoryKey,
        CategoryName
    from {{ ref('product_snapshot') }}
    where dbt_valid_to is null
),

store_dim as (
    select
        StoreKey,
        StoreCode,
        GeoAreaKey,
        CountryCode,
        CountryName,
        State
    from {{ ref('store_snapshot') }}
    where dbt_valid_to is null
),

date_dim as (
    select
        Date,
        Month,
        MonthShort,
        MonthNumber,
        Year
    from {{ ref('date_snapshot') }}
    where dbt_valid_to is null
),

transformed as (
    select
        d.Year,
        d.Month,
        d.MonthNumber,
        st.StoreKey,
        st.StoreCode,
        st.CountryName,
        p.CategoryKey,
        p.CategoryName,
        p.Brand,
        p.ProductName,
        s.CurrencyCode,
        count(distinct s.OrderKey) as TotalOrders,
        sum(s.Quantity) as TotalQuantity,
        sum(s.NetPrice * s.Quantity) as TotalRevenue,
        sum(s.UnitCost * s.Quantity) as TotalCost,
        sum((s.NetPrice * s.Quantity) - (s.UnitCost * s.Quantity)) as TotalMargin,
        round((sum((s.NetPrice * s.Quantity) - (s.UnitCost * s.Quantity)) / nullif(sum(s.NetPrice * s.Quantity), 0)) * 100, 2) as MarginRate

    from sales_fact as s
    inner join product_dim as p on s.ProductKey = p.ProductKey
    inner join store_dim as st on s.StoreKey = st.StoreKey
    inner join date_dim as d on s.OrderDate = d.Date
    group by all
)

select * 
from transformed

