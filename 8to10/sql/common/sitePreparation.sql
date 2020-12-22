-- fill in whatever you need for your project

-- set root flag where domain records have been
update pages set is_siteroot=1 where uid in (select pid from sys_domain);
-- domains should be defined in site yaml now, avoid problems with not matching legacy domain record
truncate sys_domain;
