
-- if we have utf8-mb4, we get sql error because index gets too long. The queries would be executed in the wrong order by DB compare
alter table `sys_refindex` drop index lookup_string;
ALTER TABLE sys_refindex CHANGE ref_string `ref_string` VARCHAR(1024) DEFAULT '' NOT NULL;
CREATE INDEX `lookup_string` ON sys_refindex (ref_string(255));


-- -- depending on your current system, you might need one or more of the following:
-- ALTER TABLE `tx_realurl_uniqalias_cache_map` ADD `uid` INT AUTO_INCREMENT NOT NULL PRIMARY KEY;

-- typo3/sysext/install/Classes/Updates/PopulatePageSlugs.php expects field to be named cache_id
-- ALTER TABLE `tx_realurl_pathcache` CHANGE `uid` `cache_id` INT(11) NOT NULL AUTO_INCREMENT;
