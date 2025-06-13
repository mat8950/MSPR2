TYPE=TRIGGERS
triggers='CREATE DEFINER=`root`@`%` trigger httpstep_insert after insert on httpstep\nfor each row\ninsert into changelog (object,objectid,operation,clock)\nvalues (14,new.httpstepid,1,unix_timestamp())' 'CREATE DEFINER=`root`@`%` trigger httpstep_update after update on httpstep\nfor each row\ninsert into changelog (object,objectid,operation,clock)\nvalues (14,old.httpstepid,2,unix_timestamp())' 'CREATE DEFINER=`root`@`%` trigger httpstep_delete before delete on httpstep\nfor each row\ninsert into changelog (object,objectid,operation,clock)\nvalues (14,old.httpstepid,3,unix_timestamp())'
sql_modes=1411383296 1411383296 1411383296
definers='root@%' 'root@%' 'root@%'
client_cs_names='utf8mb4' 'utf8mb4' 'utf8mb4'
connection_cl_names='utf8mb4_general_ci' 'utf8mb4_general_ci' 'utf8mb4_general_ci'
db_cl_names='utf8mb3_bin' 'utf8mb3_bin' 'utf8mb3_bin'
created=1749744556730164 1749744556731600 1749744556734550
