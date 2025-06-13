TYPE=TRIGGERS
triggers='CREATE DEFINER=`root`@`%` trigger httptest_insert after insert on httptest\nfor each row\ninsert into changelog (object,objectid,operation,clock)\nvalues (11,new.httptestid,1,unix_timestamp())' 'CREATE DEFINER=`root`@`%` trigger httptest_update after update on httptest\nfor each row\ninsert into changelog (object,objectid,operation,clock)\nvalues (11,old.httptestid,2,unix_timestamp())' 'CREATE DEFINER=`root`@`%` trigger httptest_delete before delete on httptest\nfor each row\ninsert into changelog (object,objectid,operation,clock)\nvalues (11,old.httptestid,3,unix_timestamp())'
sql_modes=1411383296 1411383296 1411383296
definers='root@%' 'root@%' 'root@%'
client_cs_names='utf8mb4' 'utf8mb4' 'utf8mb4'
connection_cl_names='utf8mb4_general_ci' 'utf8mb4_general_ci' 'utf8mb4_general_ci'
db_cl_names='utf8mb3_bin' 'utf8mb3_bin' 'utf8mb3_bin'
created=1749744556722958 1749744556724424 1749744556727078
