
-- if we have utf8-mb4, we get sql error because index gets too long. The queries would be executed in the wrong order by DB compare
alter table `sys_refindex` drop index lookup_string;
ALTER TABLE sys_refindex CHANGE ref_string `ref_string` VARCHAR(1024) DEFAULT '' NOT NULL;
CREATE INDEX `lookup_string` ON sys_refindex (ref_string(255));

-- drop all realurl, we had random 404 problems
-- DROP TABLE tx_realurl_pathdata, tx_realurl_urldata;


drop table tx_extensionmanager_domain_model_extension;

-- avoid problems with indexes, they should be clean anyway
drop table be_sessions,fe_sessions, fe_session_data;
