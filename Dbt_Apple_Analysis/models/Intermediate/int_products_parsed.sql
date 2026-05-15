{{
    config(
        alias = 'tblappleproducts_stg_1',
        materialized = 'incremental',
        transient = true
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
RAM 
from  {{ source('customers_stg_source', 'tblappleproducts_raw') }}  
)
select 
    
    substr(product_name,6,(length(product_name)+1))  as model_name,
    case when substr(product_name,16,1) ilike any ('P%','(%') then substr(product_name,7,9)
        else substr(product_name,7,10) 
    end as model_family,

    trim(split_part(substr(product_name,position('(',product_name) +1, length(product_name)+1 ),',',0)) as color,

    
case when try_to_number(trim(split_part(substr(product_name,position('(',product_name)+1, length(product_name)-4 - position('(',product_name) ),',',2)))
is null then  
try_to_number(split_part(trim(split_part(substr(product_name,position('(',product_name)+1, length(product_name)-4 - position('(',product_name) ),',',2)),' ',0))
else  try_to_number(trim(split_part(substr(product_name,position('(',product_name)+1, length(product_name)-4 - position('(',product_name) ),',',2)))
end as storage_gb,

    trim(replace(RAM,'GB','')) as ram_gb,

    SALE_PRICE / (
case when try_to_number(trim(split_part(substr(product_name,position('(',product_name)+1, length(product_name)-4 - position('(',product_name) ),',',2)))
is null then  
try_to_number(split_part(trim(split_part(substr(product_name,position('(',product_name)+1, length(product_name)-4 - position('(',product_name) ),',',2)),' ',0))
else  try_to_number(trim(split_part(substr(product_name,position('(',product_name)+1, length(product_name)-4 - position('(',product_name) ),',',2)))
end  ) as price_per_gb,
mrp - SALE_PRICE as discount_amount,
star_rating + number_of_reviews as engagement_score ,
current_timestamp()::timestamp_ltz as created_at
from 
appleproducts_cte