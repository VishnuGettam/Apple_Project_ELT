{% test  validate_ram(model,column_name)  %}

{% set accpeted_values = [2,3,4,6]   %}

{{ log( "Model Name - " ~ model , info = true   )}}

{{ log( "Column Name - " ~ column_name , info = true   ) }}

select
* 
from {{ model  }} 
where {{ column_name }} not  in ({{ accpeted_values  | join(',') }})

{% endtest  %}