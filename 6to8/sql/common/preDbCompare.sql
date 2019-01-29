-- this missing field causes exception, even for DB compare command
ALTER TABLE pages ADD `tsconfig_includes` TEXT DEFAULT NULL;

-- if we have utf8-mb4, we get sql error because index gets too long. The queries would be executed in the wrong order by DB compare
alter table `sys_refindex` drop index if exists lookup_string;
ALTER TABLE sys_refindex CHANGE ref_string `ref_string` VARCHAR(1024) DEFAULT '' NOT NULL;
CREATE INDEX `lookup_string` ON sys_refindex (ref_string(255));

-- otherwise mysql | mariadb might throw error like
-- Statement violates GTID consistency:
-- Updates to non-transactional tables can only be done in either autocommitted statements or single-statement transactions,
-- and never in the same statement as updates to transactional tables.
ALTER TABLE sys_registry ENGINE = InnoDB;

-- CREATE TABLE `sys_note` (`uid` INT UNSIGNED AUTO_INCREMENT NOT NULL, `pid` INT UNSIGNED DEFAULT 0 NOT NULL, `deleted` SMALLINT UNSIGNED DEFAULT 0 NOT NULL, `tstamp` INT UNSIGNED DEFAULT 0 NOT NULL, `crdate` INT UNSIGNED DEFAULT 0 NOT NULL, `cruser` INT UNSIGNED DEFAULT 0 NOT NULL, `subject` VARCHAR(255) DEFAULT '' NOT NULL, `message` TEXT DEFAULT NULL, `personal` SMALLINT UNSIGNED DEFAULT 0 NOT NULL, `category` SMALLINT UNSIGNED DEFAULT 0 NOT NULL, `sorting` INT DEFAULT 0 NOT NULL, INDEX `parent` (pid), PRIMARY KEY(uid)) DEFAULT CHARACTER SET utf8 COLLATE utf8_unicode_ci ENGINE = InnoDB
-- CREATE TABLE `tx_realurl_uniqalias_cache_map` (`alias_uid` INT DEFAULT 0 NOT NULL, `url_cache_id` INT DEFAULT 0 NOT NULL, INDEX `check_existence` (alias_uid, url_cache_id)) DEFAULT CHARACTER SET utf8 COLLATE utf8_unicode_ci ENGINE = InnoDB
-- CREATE TABLE `tx_realurl_urldata` (`uid` INT AUTO_INCREMENT NOT NULL, `pid` INT DEFAULT 0 NOT NULL, `crdate` INT DEFAULT 0 NOT NULL, `page_id` INT DEFAULT 0 NOT NULL, `rootpage_id` INT DEFAULT 0 NOT NULL, `original_url` TEXT DEFAULT NULL, `speaking_url` TEXT DEFAULT NULL, `request_variables` TEXT DEFAULT NULL, `expire` INT DEFAULT 0 NOT NULL, INDEX `parent` (pid), INDEX `pathq1` (rootpage_id, original_url(32), expire), INDEX `pathq2` (rootpage_id, speaking_url(32)), INDEX `page_id` (page_id), PRIMARY KEY(uid)) DEFAULT CHARACTER SET utf8 COLLATE utf8_unicode_ci ENGINE = InnoDB
-- CREATE TABLE `tx_realurl_pathdata` (`uid` INT AUTO_INCREMENT NOT NULL, `pid` INT DEFAULT 0 NOT NULL, `page_id` INT DEFAULT 0 NOT NULL, `language_id` INT DEFAULT 0 NOT NULL, `rootpage_id` INT DEFAULT 0 NOT NULL, `mpvar` TINYTEXT DEFAULT NULL, `pagepath` TEXT DEFAULT NULL, `expire` INT DEFAULT 0 NOT NULL, INDEX `parent` (pid), INDEX `pathq1` (rootpage_id, pagepath(32), expire), INDEX `pathq2` (page_id, language_id, rootpage_id, expire), INDEX `expire` (expire), PRIMARY KEY(uid)) DEFAULT CHARACTER SET utf8 COLLATE utf8_unicode_ci ENGINE = InnoDB
-- CREATE TABLE `cf_cache_imagesizes` (`id` INT UNSIGNED AUTO_INCREMENT NOT NULL, `identifier` VARCHAR(250) DEFAULT '' NOT NULL, `expires` INT UNSIGNED DEFAULT 0 NOT NULL, `content` MEDIUMBLOB DEFAULT NULL, INDEX `cache_id` (identifier, expires), PRIMARY KEY(id)) DEFAULT CHARACTER SET utf8 COLLATE utf8_unicode_ci ENGINE = InnoDB
-- CREATE TABLE `cf_cache_imagesizes_tags` (`id` INT UNSIGNED AUTO_INCREMENT NOT NULL, `identifier` VARCHAR(250) DEFAULT '' NOT NULL, `tag` VARCHAR(250) DEFAULT '' NOT NULL, INDEX `cache_id` (identifier), INDEX `cache_tag` (tag), PRIMARY KEY(id)) DEFAULT CHARACTER SET utf8 COLLATE utf8_unicode_ci ENGINE = InnoDB