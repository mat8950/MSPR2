TYPE=TRIGGERS
triggers='CREATE DEFINER=`root`@`%` trigger dchecks_insert after insert on dchecks\nfor each row\ninsert into changelog (object,objectid,operation,clock)\nvalues (10,new.dcheckid,1,unix_timestamp())' 'CREATE DEFINER=`root`@`%` trigger dchecks_update after update on dchecks\nfor each row\ninsert into changelog (object,objectid,operation,clock)\nvalues (10,old.dcheckid,2,unix_timestamp())' 'CREATE DEFINER=`root`@`%` trigger dchecks_delete before delete on dchecks\nfor each row\ninsert into changelog (object,objectid,operation,clock)\nvalues (10,old.dcheckid,3,unix_timestamp())'
sql_modes=1411383296 1411383296 1411383296
definers='root@%' 'root@%' 'root@%'
client_cs_names='utf8mb4' 'utf8mb4' 'utf8mb4'
connection_cl_names='utf8mb4_general_ci' 'utf8mb4_general_ci' 'utf8mb4_general_ci'
db_cl_names='utf8mb3_bin' 'utf8mb3_bin' 'utf8mb3_bin'
created=1749744556715753 1749744556717132 1749744556720258
