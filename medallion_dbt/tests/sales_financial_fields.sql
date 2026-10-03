-- Éviter que SUM ignore silencieusement des valeurs financières absentes.
select OrderKey, LineNumber
from {{ ref('sales_snapshot') }}
where dbt_valid_to is null
  and (
    CurrencyCode is null
    or trim(CurrencyCode) = ''
    or NetPrice is null
    or UnitCost is null
    or Quantity is null
  )
