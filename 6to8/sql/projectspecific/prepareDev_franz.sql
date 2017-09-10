update sys_domain set hidden=1;
update sys_domain set hidden=0, domainName = '8-master-xxx.dev' where uid=1;

-- this should be not necessary if you start with full dump of 6.2
delete from sys_registry where entry_namespace='installUpdate';