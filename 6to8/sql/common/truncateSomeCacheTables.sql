-- if not truncated, we get fatal errors on console
-- probably only cf_extbase, but we truncate others as well, which will be flushed anyway
TRUNCATE `cf_cache_hash`;
TRUNCATE `cf_cache_hash_tags`;
TRUNCATE `cf_cache_pages`;
TRUNCATE `cf_cache_pagesection`;
TRUNCATE `cf_cache_pagesection_tags`;
TRUNCATE `cf_cache_pages_tags`;
TRUNCATE `cf_cache_rootline`;
TRUNCATE `cf_cache_rootline_tags`;
TRUNCATE `cf_extbase_datamapfactory_datamap`;
TRUNCATE `cf_extbase_datamapfactory_datamap_tags`;
TRUNCATE `cf_extbase_object`;
TRUNCATE `cf_extbase_object_tags`;
TRUNCATE `cf_extbase_reflection`;
TRUNCATE `cf_extbase_reflection_tags`;