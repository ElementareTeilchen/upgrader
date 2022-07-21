delete FROM `sys_log` where details like '%has cleared the cache%';
delete FROM `sys_log` where details like '[scheduler%';
delete FROM `sys_log` where details like 'User %s logged in from%';
delete FROM `sys_log` where tstamp < UNIX_TIMESTAMP(DATE_SUB(NOW(), INTERVAL 360 DAY));
delete FROM `sys_log` where details like '%was deleted unrecoverable%';
delete FROM `sys_log` where error=1;
