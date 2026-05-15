{{
    config(
        alias = 'tblappleproducts',
        materialized = 'incremental',
        incremental_strategy='merge',
        unique_key='model_name'
    )
}}



with apple_products_cte as 
(
    select * from {{  ref('stg_apple_products') }}
)
select *
 from apple_products_cte
 {% if is_incremental()  %}

where created_at > (select max(created_at) from {{ this  }})

 {% endif %}