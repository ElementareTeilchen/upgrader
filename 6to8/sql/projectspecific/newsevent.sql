-- MIND: this is just example stuff from our projects to bring you up to speed.
-- This file is not yet included from migrate.sh. Evaluate carefully what you need for your specific project.

-- migrate stuff from EXT:roq_newsevent to EXT:eventnews
update sys_template set include_static_file=replace(include_static_file, 'EXT:roq_newsevent/Configuration/TypoScript', 'EXT:eventnews/Configuration/TypoScript') where uid=1;

update  tx_news_domain_model_news set is_event=1 where tx_roqnewsevent_is_event=1;
update  tx_news_domain_model_news set datetime=tx_roqnewsevent_startdate+tx_roqnewsevent_starttime where tx_roqnewsevent_startdate > 0;
update  tx_news_domain_model_news set event_end=tx_roqnewsevent_enddate+tx_roqnewsevent_endtime where tx_roqnewsevent_enddate > 0;

update  tx_news_domain_model_news set archive=event_end where is_event=1 AND event_end > 0 AND archive=0;

update tt_content set pi_flexform=replace(pi_flexform, 'eventDetail', 'detail') where pi_flexform like '%eventDetail%';
update tt_content set pi_flexform=replace(pi_flexform, 'eventList', 'list') where pi_flexform like '%eventList%';

