{{
    config(
        alias = 'tblappleproducts_merge_stg',
        materialized = 'incremental',
        transient = true,
        unique_key = 'UPC',
        incremental_strategy = 'merge',
        on_schema_change = 'append_new_columns'

    )

}}


with appleproducts_cte as
(
    select 
    PRODUCT_NAME,
    PRODUCT_URL,
    BRAND,
    SALE_PRICE,
    MRP,
    DISCOUNT_PERCENTAGE,
    NUMBER_OF_RATINGS,
    NUMBER_OF_REVIEWS,
    UPC,
    STAR_RATING,
    RAM , 
    _LOADED_AT
    from  {{ source('customers_stg_source', 'tblappleproducts_raw') }}  
)

select 
    upper(trim(UPC)) as UPC,
    trim(PRODUCT_NAME) as PRODUCT_NAME,
    trim(PRODUCT_URL) as PRODUCT_URL,
    initcap(trim(BRAND)) as BRAND,
    try_to_number(trim(SALE_PRICE), 10, 2) as SALE_PRICE_INR,
    try_to_number(trim(MRP),10,2) as MRP_INR,
    try_to_number(trim(DISCOUNT_PERCENTAGE),5,2) as DISCOUNT_PERCENTAGE,
    try_to_number(trim(NUMBER_OF_RATINGS)) as NUMBER_OF_RATINGS,
    try_to_number(trim(NUMBER_OF_REVIEWS)) as NUMBER_OF_REVIEWS,    
    try_cast(trim(STAR_RATING) as number(2,1)) as STAR_RATING,
    trim(RAM) as RAM_raw,  
    _LOADED_AT  as _LOADED_AT,

    {% if is_incremental()   %}
    current_timestamp()::timestamp_ltz as _dbt_updated_at

    {% else %}

        null::timestamp_ltz as _dbt_updated_at

    {% endif  %}


    
from  appleproducts_cte

{% if is_incremental() %}

where _loaded_at > (
    select coalesce(max(_loaded_at), '1900-01-01'::timestamp_ltz) 
    from {{ this }}
    )

{% endif %}
