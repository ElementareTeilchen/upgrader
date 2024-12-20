-- if you have utf8mb4 now, you might get sql errors because index gets too long. The queries would be executed in the wrong order by DB compare
-- alter table `sys_refindex` drop index lookup_string;
-- ALTER TABLE sys_refindex CHANGE ref_string `ref_string` VARCHAR(1024) DEFAULT '' NOT NULL;
-- CREATE INDEX `lookup_string` ON sys_refindex (ref_string(255));

-- there should not be pages in default language having l10n_parent set
-- might break i.e. sitemap rendering
update pages set l10n_parent = 0  where sys_language_uid = 0;

-- in case you have no reason these two fields should differ, make them identical, this avoids issues in the backend in language compare mode
-- find / test with
-- SELECT trans.uid,trans.pid,trans.sys_language_uid,trans.title,trans.l10n_source,trans.l10n_parent FROM pages trans inner join pages orig on trans.l10n_parent=orig.uid WHERE trans.deleted=0 and trans.hidden=0 and orig.deleted=0 and orig.hidden=0 and trans.l10n_source != trans.l10n_parent;
-- update pages set l10n_source = l10n_parent where sys_language_uid > 0 and l10n_source != l10n_parent;

-- remove useless duplicates to allow DB compare to create new indexes
ALTER TABLE sys_category_record_mm ADD COLUMN temp SERIAL;
DELETE t1 FROM sys_category_record_mm t1, sys_category_record_mm t2
WHERE t1.temp > t2.temp
  AND t1.uid_local = t2.uid_local
  AND t1.uid_foreign = t2.uid_foreign
  AND t1.tablenames = t2.tablenames
  AND t1.fieldname = t2.fieldname;
ALTER TABLE sys_category_record_mm DROP COLUMN temp;

-- remove zombie records, which where not found by cleanup commands
select concat ('sys_file_metadata zombies, will be removed: ', count(*)) FROM sys_file_metadata WHERE file not in (select uid from sys_file);
delete FROM sys_file_metadata WHERE file not in (select uid from sys_file);
