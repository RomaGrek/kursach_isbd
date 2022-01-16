/*
тригер №1
сделка не может быть совершена во время задания одного из ее участников
использует функцию get_status_team_by_mag_id
*/
create or replace function check_deal_complete()
returns trigger as $$
declare
    status_team_mag text = (select get_status_team_by_mag_id(new.id_magician));
    status_team_buyer_mag text = (select get_status_team_by_mag_id(new.id_buyer));
begin
    if (status_team_mag = 'busy') or (status_team_buyer_mag = 'busy')
        then return null;
    else return new;
    end if;
end;
$$ language 'plpgsql';

create trigger deal_mag_mis before insert on deal
    for each row execute procedure check_deal_complete();

/* функция получения статуса команды по id мага (используется в триггере №1) */
create or replace function get_status_team_by_mag_id(mag_id integer)
returns text as $$
begin
 return (select status_team from team where id = (select id_team from magician where magician.id = mag_id));
end;
$$ language 'plpgsql';

/* тригер №7
Время начала задания, не может быть
больше времени эксперимента, входящего в это задание
*/
create or replace function check_start_mission_time()
returns trigger as $$
    begin
        if (new.time_exp <= (select start_time from mission where new.id_mission = id))
            or (new.time_exp >= (select end_time from mission where new.id_mission = id))
        then return null;
        else return new;
        end if;
    end;
$$ language 'plpgsql';
