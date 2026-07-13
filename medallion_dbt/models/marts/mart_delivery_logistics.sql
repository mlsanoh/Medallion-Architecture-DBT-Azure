-- le délai moyen de livraison par pays de destination et par magasin, et la proportion de commandes livrées en retard

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
        DeliveryDate,
        StoreKey
    from {{ ref('sales_snapshot') }}
    where dbt_valid_to is null
),

store_dim as (
    select
        StoreKey,
        StoreCode,
        CountryName,
        State
    from {{ ref('store_snapshot') }}
    where dbt_valid_to is null
),

date_dim as (
    select
        Date,
        Year,
        Month,
        MonthNumber
    from {{ ref('date_snapshot') }}
    where dbt_valid_to is null
),

delivery_metrics as (
    select
        s.OrderKey,
        s.StoreKey,
        s.OrderDate,
        datediff(s.DeliveryDate, s.OrderDate) as DaysToDeliver,
        case 
            when datediff(s.DeliveryDate, s.OrderDate) > 7 then 1
            else 0
        end as is_delayed
    from sales_fact as s
    where s.DeliveryDate is not null 
),

final_aggregation as (
    select
        d.Year,
        d.Month,
        d.MonthNumber,
        st.StoreKey,
        st.StoreCode,
        st.CountryName,
        st.State,
        count(distinct dm.OrderKey) as TotalOrdersDelivered,
        -- Délai moyen de livraison
        round(avg(dm.DaysToDeliver), 1) as AverageDaysToDeliver,
        -- Nombre de commandes en retard
        sum(dm.is_delayed) as TotalDelayedOrders,
        -- Proportion de commandes en retard (Somme des 1 / Nombre total de lignes * 100)
        round((sum(dm.is_delayed) / nullif(count(distinct dm.OrderKey), 0)) * 100, 2) as DelayRatePercentage

    from delivery_metrics as dm
    inner join store_dim as st on dm.StoreKey = st.StoreKey
    inner join date_dim as d on dm.OrderDate = d.Date
    group by all
)

select *
from final_aggregation