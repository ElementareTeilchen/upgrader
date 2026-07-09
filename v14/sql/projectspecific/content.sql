-- fill in whatever you need for your project
-- update pages set tsconfig_includes = replace(tsconfig_includes, 'whateverYouDontNeedAnymore', '') where tsconfig_includes != '';
update pages set tsconfig_includes = '' where tsconfig_includes REGEXP '^[[:space:]]*$' and tsconfig_includes != '';
