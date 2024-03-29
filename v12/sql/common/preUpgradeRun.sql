-- if you have utf8mb4 now, you might get sql errors because index gets too long. The queries would be executed in the wrong order by DB compare
-- alter table `sys_refindex` drop index lookup_string;
-- ALTER TABLE sys_refindex CHANGE ref_string `ref_string` VARCHAR(1024) DEFAULT '' NOT NULL;
-- CREATE INDEX `lookup_string` ON sys_refindex (ref_string(255));

-- there should not be pages in default language having l10n_parent set
-- might break i.e. sitemap rendering
update pages set l10n_parent = 0  where sys_language_uid = 0;
