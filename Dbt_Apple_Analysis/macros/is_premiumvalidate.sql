{% macro is_premium(column_name) %}

{% set premium_values = ['Pro','Pro Max']  %}

 {% set rendered_sql  %}

            case when {{column_name}} in premium_values then true
                else false
            end;
{%endset%}

{{log(rendered_sql,info=true)}}

{% endmacro %}