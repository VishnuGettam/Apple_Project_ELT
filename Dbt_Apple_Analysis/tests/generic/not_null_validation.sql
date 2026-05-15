{% test not_null_validation(model,column_name)  %}

select 
*  
from {{ model  }}
where {{ column_name }} is null

{% endtest %}