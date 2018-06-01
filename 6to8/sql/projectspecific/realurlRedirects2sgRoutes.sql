-- include this sql if you want to migrate old realurl redirects (support dropped since 2.0) to EXT:sg_routes
delete from tx_realurl_redirects where counter=0;
truncate table tx_sgroutes_domain_model_route;
truncate table tx_sgroutes_domain_model_category;
truncate table tx_sgroutes_domain_model_route_category;

-- make sure we have one (and only one) / at beginning
insert into tx_sgroutes_domain_model_route (pid,source_url, destination_url, redirect_code, categories, tstamp, crdate) select 2, concat('/',url), concat('/', destination), '301', 1, tstamp, tstamp from tx_realurl_redirects;
update tx_sgroutes_domain_model_route set destination_url = REPLACE(destination_url, '//','/');

-- set specific category for imported data
INSERT INTO `tx_sgroutes_domain_model_category` (`uid`, `pid`, `title`, `description`, `tstamp`, `crdate`, `cruser_id`, `hidden`, `deleted`, `starttime`, `endtime`, `t3ver_oid`, `t3ver_id`, `t3ver_wsid`, `t3ver_label`, `t3ver_state`, `t3ver_stage`, `t3ver_count`, `t3ver_tstamp`, `t3ver_move_id`, `t3_origuid`) VALUES
(1,	2,	'realurl-imports',	'redirects imported from EXT:realurl. Realurl does not support redirects any more.',	1507124393,	1507124393,	97,	0,	0,	0,	0,	0,	0,	0,	'',	0,	0,	0,	0,	0,	0);
INSERT INTO `tx_sgroutes_domain_model_route_category` (`uid_local`, `uid_foreign`) select uid, 1 from tx_sgroutes_domain_model_route;
