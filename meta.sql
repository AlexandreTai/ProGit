--for a table:
select 
   --'Table'    as PropertyType
   --,sch.name   as SchemaName
   --,sep.name   as DescriptionType
   tbl.name   as TableName
  ,sep.value  as DescriptionDefinition
from sys.tables tbl
  inner join sys.schemas sch
	on  tbl.schema_id = sch.schema_id
  inner join sys.extended_properties sep
	on  tbl.object_id = sep.major_id
where  sep.class = 1
   and sep.minor_id = 0
   and (sep.value <> '1' and sep.value <> 1)
   and sep.name like '%Description'
   and sch.name = 'sius'
       
       
-- for a column:
select 
   col.name   as ColumnName
  ,t.name +
   case when t.name in ('char' ,'varchar' ,'nchar' ,'nvarchar') then '(' +
        
        case when col.max_length = -1 then 'MAX' else convert(   varchar(4)
                ,case when t.name in ('nchar' ,'nvarchar') then col.max_length /
                      2 else col.max_length end  ) end + ')' when t.name in ('decimal' , 'numeric') then 
        '(' + convert(varchar(4) ,col.precision) + ','
        
        + convert(varchar(4) ,col.Scale) + ')' else '' end as "DDL name"
  ,sep.value  as DescriptionDefinition
from sys.extended_properties sep
  inner join sys.columns col
	on  sep.major_id = col.object_id
		and sep.minor_id = col.column_id
  inner join sys.types t
	on  col.user_type_id = t.user_type_id
  inner join sys.tables tbl
	on  sep.major_id = tbl.object_id
  inner join sys.schemas sch
	on  tbl.schema_id = sch.schema_id
where  sep.class = 1
   and (sep.value <> '1' and sep.value <> 1)
   and sep.name like '%Description'
   and sch.name = 'sius'
   and tbl.name = 'LostSales' ---table---

--Procedures 
select 
   prc.name   as ProcedureName
  ,sep.value  as DescriptionDefinition
from sys.extended_properties sep
  inner join sys.procedures prc
	on  sep.major_id = prc.object_id
  inner join sys.schemas SCH
	on  prc.schema_id = SCH.schema_id
where  sep.minor_id = 0
   and sep.name     like '%Description'
   and sch.name     = 'sius'

--Procedure parameters
select 
   prm.name   as ParameterName
  ,t.name +
   case when t.name in ('char' ,'varchar' ,'nchar' ,'nvarchar') then '(' +
        
        case when prm.max_length = -1 then 'MAX' else convert(   varchar(4)
                ,case when t.name in ('nchar' ,'nvarchar') then prm.max_length /
                      2 else prm.max_length end  ) end + ')' when t.name in ('decimal' , 'numeric') then 
        '(' + convert(varchar(4) ,prm.precision) + ','
        
        + convert(varchar(4) ,prm.Scale) + ')' else '' end as "DDL name"
  ,sep.value  as DescriptionDefinition
from sys.extended_properties sep
  inner join sys.procedures spr
	on  sep.major_id = spr.object_id
  inner join sys.schemas SCH
	on  spr.schema_id = SCH.schema_id
  inner join sys.parameters prm
	on  sep.major_id = prm.object_id
		and sep.minor_id = prm.parameter_id
  inner join sys.types t
	on  prm.user_type_id = t.user_type_id
where  sep.class_desc = N'parameter'
   and sep.name       like '%Description'
   and sch.name       = 'sius'
   and spr.name       = 'ServiceMain_Read' --ProcedureName





























