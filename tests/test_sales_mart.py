from pathlib import Path
import duckdb
from jinja2 import Environment, StrictUndefined

ROOT = Path(__file__).resolve().parents[1] / 'medallion_dbt'


def render(path):
    return Environment(undefined=StrictUndefined).from_string(path.read_text()).render(
        ref=lambda name: name, config=lambda **kwargs: '',
    )


def database():
    conn = duckdb.connect()
    conn.execute("""
        CREATE TABLE sales_snapshot AS SELECT
            1 AS OrderKey, 1 AS LineNumber, DATE '2026-01-01' AS OrderDate,
            1 AS CustomerKey, 1 AS StoreKey, 1 AS ProductKey,
            2 AS Quantity, 20.0 AS UnitPrice, 15.0 AS NetPrice, 5.0 AS UnitCost,
            'EUR' AS CurrencyCode, 1.0 AS ExchangeRate, NULL::TIMESTAMP AS dbt_valid_to;
        CREATE TABLE product_snapshot AS SELECT 1 AS ProductKey, 'P1' AS ProductCode,
            'Product' AS ProductName, 'Maker' AS Manufacturer, 'Brand' AS Brand,
            1 AS CategoryKey, 'Category' AS CategoryName, NULL::TIMESTAMP AS dbt_valid_to;
        CREATE TABLE store_snapshot AS SELECT 1 AS StoreKey, 'S1' AS StoreCode,
            1 AS GeoAreaKey, 'FR' AS CountryCode, 'France' AS CountryName,
            'Paris' AS State, NULL::TIMESTAMP AS dbt_valid_to;
        CREATE TABLE date_snapshot AS SELECT DATE '2026-01-01' AS Date,
            'January' AS Month, 'Jan' AS MonthShort, 1 AS MonthNumber, 2026 AS Year,
            NULL::TIMESTAMP AS dbt_valid_to;
    """)
    return conn


def test_currency_groups_and_current_snapshot_totals():
    with database() as conn:
        conn.execute("INSERT INTO sales_snapshot SELECT * REPLACE(2 AS OrderKey, 'USD' AS CurrencyCode, 2.0 AS ExchangeRate) FROM sales_snapshot")
        conn.execute("INSERT INTO sales_snapshot SELECT * REPLACE(99 AS OrderKey, TIMESTAMP '2025-12-31' AS dbt_valid_to) FROM sales_snapshot WHERE OrderKey = 1")
        rows = conn.execute(render(ROOT / 'models/marts/mart_sales_performance.sql')).fetchdf()
        assert set(rows.CurrencyCode) == {'EUR', 'USD'}
        assert rows.TotalOrders.tolist() == [1, 1]
        assert rows.TotalRevenue.tolist() == [30, 30]
        assert rows.TotalCost.tolist() == [10, 10]
        assert rows.TotalMargin.tolist() == [20, 20]


def test_missing_financial_field_is_reported():
    with database() as conn:
        query = render(ROOT / 'tests/sales_financial_fields.sql')
        assert conn.execute(query).fetchall() == []
        conn.execute('UPDATE sales_snapshot SET UnitCost = NULL')
        assert conn.execute(query).fetchall() == [(1, 1)]
