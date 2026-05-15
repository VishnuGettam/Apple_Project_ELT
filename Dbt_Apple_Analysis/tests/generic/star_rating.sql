{% test star_rating(model,column_name)   %}

{{ config(
    severity = 'warn'
) }}

select *
from {{ model }}
where {{ column_name }} < 0 or {{ column_name }} > 5

{% endtest %}