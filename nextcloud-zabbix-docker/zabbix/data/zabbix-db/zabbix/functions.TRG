TYPE=TRIGGERS
triggers='CREATE DEFINER=`root`@`%` trigger functions_insert after insert on functions\nfor each row\ninsert into changelog (object,objectid,operation,clock)\nvalues (7,new.functionid,1,unix_timestamp())' 'CREATE DEFINER=`root`@`%` trigger functions_update after update on functions\nfor each row\ninsert into changelog (object,objectid,operation,clock)\nvalues (7,old.functionid,2,unix_timestamp())' 'CREATE DEFINER=`root`@`%` trigger functions_delete before delete on functions\nfor each row\ninsert into changelog (object,objectid,operation,clock)\nvalues (7,old.functionid,3,unix_timestamp())'
sql_modes=1411383296 1411383296 1411383296
definers='root@%' 'root@%' 'root@%'
client_cs_names='utf8mb4' 'utf8mb4' 'utf8mb4'
connection_cl_names='utf8mb4_general_ci' 'utf8mb4_general_ci' 'utf8mb4_general_ci'
db_cl_names='utf8mb3_bin' 'utf8mb3_bin' 'utf8mb3_bin'
created=1749744556775078 1749744556776768 1749744556780468
