-- MIND: this is just example stuff from our projects to bring you up to speed.
-- This file is not yet included from migrate.sh. Evaluate carefully what you need for your specific project.

-- use new backend layout integration
update pages set backend_layout = 'pagets__3col' where backend_layout=1;
update pages set backend_layout = 'pagets__2col' where backend_layout=2;
update pages set backend_layout_next_level = 'pagets__3col' where backend_layout_next_level=1;
update pages set backend_layout_next_level = 'pagets__2col' where backend_layout_next_level=2;
truncate table backend_layout;
