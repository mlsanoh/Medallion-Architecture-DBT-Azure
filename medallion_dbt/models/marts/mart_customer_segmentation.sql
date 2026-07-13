-- le profil des meilleurs clients (top 10% en chiffre d'affaires), leur panier moyen, leur répartition par genre, tranche d'âge et zone géographique

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
        CustomerKey,
        NetPrice,
        Quantity
    from {{ ref('sales_snapshot') }}
    where dbt_valid_to is null
),

customer_dim as (
    select
        CustomerKey,
        Gender,
        Age, 
        Continent,
        Country,
        State
    from {{ ref('customer_snapshot') }}
    where dbt_valid_to is null
),

customer_aggregates as (
    select
        s.CustomerKey,
        sum(s.NetPrice * s.Quantity) as TotalSpend,
        count(distinct s.OrderKey) as TotalOrders,
        round(sum(s.NetPrice * s.Quantity) / nullif(count(distinct s.OrderKey), 0), 2) as AverageOrderValue
    from sales_fact as s
    group by 1
),

customer_ranked as (
    select
        ca.*,
        percent_rank() over (order by ca.TotalSpend desc) as spend_percentile
    from customer_aggregates as ca
),

final_segmentation as (
    select
        cr.CustomerKey,
        c.Gender,
        c.Age,
        c.Continent,
        c.Country,
        c.State,
        cr.TotalSpend,
        cr.TotalOrders,
        cr.AverageOrderValue,
        case 
            when cr.spend_percentile <= 0.10 then 'Top 10%'
            else 'Standard'
        end as CustomerSegment
    from customer_ranked as cr
    inner join customer_dim as c on cr.CustomerKey = c.CustomerKey
)

select *
from final_segmentation