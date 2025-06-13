TYPE=TRIGGERS
triggers='CREATE DEFINER=`root`@`%` trigger httpstep_field_insert after insert on httpstep_field\nfor each row\ninsert into changelog (object,objectid,operation,clock)\nvalues (15,new.httpstep_fieldid,1,unix_timestamp())' 'CREATE DEFINER=`root`@`%` trigger httpstep_field_update after update on httpstep_field\nfor each row\ninsert into changelog (object,objectid,operation,clock)\nvalues (15,old.httpstep_fieldid,2,unix_timestamp())' 'CREATE DEFINER=`root`@`%` trigger httpstep_field_delete before delete on httpstep_field\nfor each row\ninsert into changelog (object,objectid,operation,clock)\nvalues (15,old.httpstep_fieldid,3,unix_timestamp())'
sql_modes=1411383296 1411383296 1411383296
definers='root@%' 'root@%' 'root@%'
client_cs_names='utf8mb4' 'utf8mb4' 'utf8mb4'
connection_cl_names='utf8mb4_general_ci' 'utf8mb4_general_ci' 'utf8mb4_general_ci'
db_cl_names='utf8mb3_bin' 'utf8mb3_bin' 'utf8mb3_bin'
created=1749744556814141 1749744556816373 1749744556820307
