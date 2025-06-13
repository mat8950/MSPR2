TYPE=TRIGGERS
triggers='CREATE DEFINER=`root`@`%` trigger httpstepitem_insert after insert on httpstepitem\nfor each row\ninsert into changelog (object,objectid,operation,clock)\nvalues (16,new.httpstepitemid,1,unix_timestamp())' 'CREATE DEFINER=`root`@`%` trigger httpstepitem_update after update on httpstepitem\nfor each row\ninsert into changelog (object,objectid,operation,clock)\nvalues (16,old.httpstepitemid,2,unix_timestamp())' 'CREATE DEFINER=`root`@`%` trigger httpstepitem_delete before delete on httpstepitem\nfor each row\ninsert into changelog (object,objectid,operation,clock)\nvalues (16,old.httpstepitemid,3,unix_timestamp())'
sql_modes=1411383296 1411383296 1411383296
definers='root@%' 'root@%' 'root@%'
client_cs_names='utf8mb4' 'utf8mb4' 'utf8mb4'
connection_cl_names='utf8mb4_general_ci' 'utf8mb4_general_ci' 'utf8mb4_general_ci'
db_cl_names='utf8mb3_bin' 'utf8mb3_bin' 'utf8mb3_bin'
created=1749744556750344 1749744556752061 1749744556754453
