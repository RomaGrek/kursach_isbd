/* удаление енама */
drop type if exists level, status_team cascade;

/* удаление таблиц
truncate table item,
    team, area, inventory,
    door, mission, experiment,
    participant, human, magician,
    incident, exemplar, buyer,
    deal, presence, mission_log;

 */
 drop table if exists item,
    team, area, inventory,
    door, mission, experiment,
    participant, human, magician,
    incident, exemplar, buyer,
    deal, presence, mission_log cascade ;
drop function if exists check_deal_complete() cascade;

drop function if exists check_go_team_on_mission() cascade;

drop function if exists check_count_mag_in_team() cascade;

drop function if exists check_go_mission_die_mag() cascade;

drop function if exists check_participant_id_for_mag() cascade;

drop function if exists check_participant_id_for_human() cascade;

drop function if exists check_status_human_for_experiment() cascade;

drop function if exists check_start_mission_time() cascade;

drop function if exists check_status_mag_buyer_for_deal() cascade;

drop function if exists add_count_busy_slots() cascade;

drop function if exists add_count_exp_in_mission() cascade;

drop function if exists inc_dec_busy_slots(integer, varchar) cascade;

drop function if exists inc_count_exp(integer) cascade;

drop function if exists get_status_team_by_mag_id(integer) cascade;

drop function if exists get_status_mag(integer) cascade;

drop function if exists get_status_human(integer) cascade;

drop function if exists get_level() cascade;

drop function if exists get_status_part() cascade;

drop function if exists get_status_exm() cascade;

drop function if exists get_status_team() cascade;

drop function if exists get_end_time(timestamp) cascade;

drop function if exists get_time_exp(timestamp) cascade;

drop function if exists get_time() cascade;

drop function if exists get_value(integer, integer) cascade;

drop function if exists get_name() cascade;

drop function if exists get_title() cascade;

drop function if exists get_gender() cascade;