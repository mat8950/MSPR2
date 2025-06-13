TYPE=TRIGGERS
triggers='CREATE DEFINER=`root`@`%` trigger drules_insert after insert on drules\nfor each row\ninsert into changelog (object,objectid,operation,clock)\nvalues (9,new.druleid,1,unix_timestamp())' 'CREATE DEFINER=`root`@`%` trigger drules_update after update on drules\nfor each row\ninsert into changelog (object,objectid,operation,clock)\nvalues (9,old.druleid,2,unix_timestamp())' 'CREATE DEFINER=`root`@`%` trigger drules_delete before delete on drules\nfor each row\ninsert into changelog (object,objectid,operation,clock)\nvalues (9,old.druleid,3,unix_timestamp())'
sql_modes=1411383296 1411383296 1411383296
definers='root@%' 'root@%' 'root@%'
client_cs_names='utf8mb4' 'utf8mb4' 'utf8mb4'
connection_cl_names='utf8mb4_general_ci' 'utf8mb4_general_ci' 'utf8mb4_general_ci'
db_cl_names='utf8mb3_bin' 'utf8mb3_bin' 'utf8mb3_bin'
created=1749744556708519 1749744556710368 1749744556712967
