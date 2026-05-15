select 
*
from {{  ref('stg_apple_products') }}
where DISCOUNT_PERCENTAGE < 0