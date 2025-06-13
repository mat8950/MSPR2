TYPE=TRIGGERS
triggers='CREATE DEFINER=`root`@`%` trigger host_tag_insert after insert on host_tag\nfor each row\ninsert into changelog (object,objectid,operation,clock)\nvalues (2,new.hosttagid,1,unix_timestamp())' 'CREATE DEFINER=`root`@`%` trigger host_tag_update after update on host_tag\nfor each row\ninsert into changelog (object,objectid,operation,clock)\nvalues (2,old.hosttagid,2,unix_timestamp())' 'CREATE DEFINER=`root`@`%` trigger host_tag_delete before delete on host_tag\nfor each row\ninsert into changelog (object,objectid,operation,clock)\nvalues (2,old.hosttagid,3,unix_timestamp())'
sql_modes=1411383296 1411383296 1411383296
definers='root@%' 'root@%' 'root@%'
client_cs_names='utf8mb4' 'utf8mb4' 'utf8mb4'
connection_cl_names='utf8mb4_general_ci' 'utf8mb4_general_ci' 'utf8mb4_general_ci'
db_cl_names='utf8mb3_bin' 'utf8mb3_bin' 'utf8mb3_bin'
created=1749744556823971 1749744556826354 1749744556834572
