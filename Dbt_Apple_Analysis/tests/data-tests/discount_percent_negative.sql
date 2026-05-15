select 
*
from {{  ref('stg_apple_products_merge') }}
where DISCOUNT_PERCENTAGE < 0