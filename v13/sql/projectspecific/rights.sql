-- fill in whatever you need for your project

-- since v12 the submodules must be checked as own modules
update be_groups set groupMods = replace(groupMods, 'web_info,', 'web_info,web_info_overview,web_info_translations,');
-- update be_groups set groupMods = replace(groupMods, 'web_brofix,', 'web_brofix,web_brofix_broken_links,web_brofix_manage_exclusions,');
