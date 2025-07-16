-- remove all whitespace if TSconfig only contains whitespace
update pages set TSconfig = '' where TSconfig REGEXP '^[[:space:]]*$' and TSconfig != '';
