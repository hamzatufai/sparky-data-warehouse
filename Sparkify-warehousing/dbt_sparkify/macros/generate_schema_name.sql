-- =============================================================================
-- generate_schema_name.sql
-- By default dbt writes models to "<target_schema>_<custom_schema>".
-- We override that so a model configured with +schema: STAGING lands in
-- SPARKIFY_DB.STAGING (not SPARKIFY_DB.ANALYTICS_STAGING), giving us the
-- clean RAW -> STAGING -> MARTS layering.
-- =============================================================================

{% macro generate_schema_name(custom_schema_name, node) -%}

    {%- if custom_schema_name is none -%}
        {{ target.schema }}
    {%- else -%}
        {{ custom_schema_name | trim }}
    {%- endif -%}

{%- endmacro %}
