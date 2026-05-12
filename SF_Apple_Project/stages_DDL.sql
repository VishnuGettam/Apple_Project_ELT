use role sysadmin;

create or replace database customers_db;
create or replace schema customers_raw;


create or replace file format ff_csv_infer_schema
type='csv' 
PARSE_HEADER = TRUE
FIELD_OPTIONALLY_ENCLOSED_BY = '"';          
 
create or replace file format ff_csv_load
type='csv'
skip_header=1
FIELD_OPTIONALLY_ENCLOSED_BY = '"'; 

--create stage--
create or replace stage apple_s3
url='s3://apple-329599618475-ap-south-2-an' ;

--list files--
list @apple_s3;
--validate the data in stage file--
select 
$1::string
from @apple_s3 
(file_format=>'ff_csv_load');
 

--validate the columns in stage file---
SELECT *
FROM TABLE(
  INFER_SCHEMA(
    LOCATION    => '@apple_s3/apple_products.csv',
    FILE_FORMAT => 'ff_csv_infer_schema'
  )
);
 
----create raw table---
CREATE OR REPLACE TRANSIENT TABLE tblappleproducts_raw
USING TEMPLATE (
  SELECT ARRAY_AGG(OBJECT_CONSTRUCT(
    'COLUMN_NAME', UPPER(REPLACE(COLUMN_NAME, ' ', '_')),
    'TYPE',       TYPE,
    'NULLABLE',   NULLABLE,
    'EXPRESSION', EXPRESSION,
    'FILENAMES',  FILENAMES,
    'ORDER_ID',   ORDER_ID
  )) WITHIN GROUP (ORDER BY ORDER_ID)
  FROM TABLE(
    INFER_SCHEMA(
      LOCATION    => '@apple_s3',
      FILE_FORMAT => 'ff_csv_infer_schema'
    )
  )
);


------snow pipe -----
create or replace pipe appleproducts_load_pipe
auto_ingest = true
as
copy into tblappleproducts_raw
from @apple_s3
file_format = 'ff_csv_load'; 


select system$pipe_status('appleproducts_load_pipe');

 
desc pipe appleproducts_load_pipe;


alter pipe appleproducts_load_pipe refresh;

ALTER PIPE appleproducts_load_pipe SET PIPE_EXECUTION_PAUSED = TRUE;
 
-- Did files actually load?
SELECT *
FROM TABLE(INFORMATION_SCHEMA.COPY_HISTORY(
  TABLE_NAME => 'TBLAPPLEPRODUCTS_RAW',
  START_TIME => DATEADD('hour', -1, CURRENT_TIMESTAMP())
));

-- Pipe-level load history
SELECT *
FROM TABLE(INFORMATION_SCHEMA.PIPE_USAGE_HISTORY(
  DATE_RANGE_START => DATEADD('hour', -1, CURRENT_TIMESTAMP()),
  PIPE_NAME => 'appleproducts_load_pipe'
));


select * from tblappleproducts_raw;




 


