-- if we have utf8-mb4, we get sql error because index gets too long. The queries would be executed in the wrong order by DB compare
-- alter table `sys_refindex` drop index lookup_string;
-- ALTER TABLE sys_refindex CHANGE ref_string `ref_string` VARCHAR(1024) DEFAULT '' NOT NULL;
-- CREATE INDEX `lookup_string` ON sys_refindex (ref_string(255));

-- there should not be pages in default language having l10n_parent set
-- might break i.e. sitemap rendering
update pages set l10n_parent = 0  where sys_language_uid = 0;

-- in case you have updated news from an older version and get an error like "Data truncated for column 'related_links' at row xxx"
-- UPDATE tx_news_domain_model_news SET related_links=0 WHERE related_links IS NULL;
