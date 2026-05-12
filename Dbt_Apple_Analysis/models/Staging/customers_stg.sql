{{
    config(
        alias = 'tblcustomers_stg',
        materialized = 'table',
        transient = true
    )

}}

select * 
from  {{ source('customers_stg_source', 'tblcustomers_raw') }}  