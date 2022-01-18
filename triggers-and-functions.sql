
/*
тригер №1 - вероятность правильности 99%
сделка не может быть совершена во время задания одного из ее участников
*/
create or replace function check_deal_complete()
returns trigger as $$
declare
    status_team_mag text = (select get_status_team_by_mag_id(new.id_magician));
    status_team_buyer_mag text = (select get_status_team_by_mag_id(new.id_buyer));
begin
    if (status_team_mag = 'busy') or (status_team_buyer_mag = 'busy')
        then return null;
    end if;
    return new;
end;
$$ language 'plpgsql';

create trigger deal_mag_mis before insert on deal               -- only insert
    for each row execute procedure check_deal_complete();

/*
триггер №2
Команда не может быть отправлена на задание, если она находится на задании или расформирована
*/
create or replace function check_go_team_on_mission()
returns trigger as $$
begin
    if (new.status_team = 'busy')
        then
        if (old.status_team = 'busy') or (old.status_team = 'disbanded') or (old.status_team = 'no_participant')
            then return null;
        end if;
    return new;
    end if;
end;
$$ language 'plpgsql';

create trigger go_team_on_mission before update on team
    for each row execute procedure check_go_team_on_mission();

/*
Триггер №3
В команде не может быть больше 2-ух магов
*/
create or replace function check_count_mag_in_team()
returns trigger as $$
declare
count_mag_in_team integer = (select count(*) from magician where id_team = new.id_team);
begin
    if (tg_op = 'INSERT') and (new.id_team is null)
    then
        if (count_mag_in_team > 1)
            then
            return null;
        end if;
    elseif (new.id_team <> old.id_team)
    then
        if (count_mag_in_team > 1)
            then
            return null;
        end if;
    end if;
    return new;
end;
$$ language 'plpgsql';

create trigger joining_the_team before insert or update on magician     --- insert and update
    for each row execute procedure check_count_mag_in_team();

/*
триггер №4
На задания не могут отправляться мертвые маги
*/
create or replace function check_go_mission_die_mag()
returns trigger as $$
declare
    mag_id integer;
begin
    if (new.status_team = 'busy')
        then
        for mag_id in (select magician.id from magician inner join team t on magician.id_team = t.id) loop  -- можно вынести в отдельную функцию
            if (get_status_mag(mag_id) = 'die')
                then
                return null;
            end if;
        end loop;
    end if;
    return new;
end
$$ language 'plpgsql';

create trigger go_mag_on_mission before update on team
    for each row execute procedure check_go_mission_die_mag();

/*
 триггер №5 - верно на 99%
 Маг не может быть человеком (ссылаться на одно и то же id)
 */
create or replace function check_participant_id_for_mag()
returns trigger as $$
begin
    if ((select count(*) from human where new.id_participant = human.id_participant) > 0)
        then
        return null;
    end if;
    return true;
end;
$$ language 'plpgsql';

create trigger mag_participant_id before insert on magician
    for each row execute procedure check_participant_id_for_mag();

/*
 триггер №6 - верно на 99%
 Человек не может быть магом (ссылаться на одно и то же id)
 */
create or replace function check_participant_id_for_human()
returns trigger as $$
begin
    if ((select count(*) from magician where new.id_participant = magician.id_participant) > 0)
        then
        return null;
    else return true;
    end if;
end;
$$ language 'plpgsql';

create trigger human_participant_id before insert on human
    for each row execute procedure check_participant_id_for_human();

/*
триггер №7 - верно на 99%
Мертвые люди не могут участвовать в экспериментах
*/
create or replace function check_status_human_for_experiment()
returns trigger as $$
declare
    status_human text = get_status_human(new.id);
begin
    if (new.id_experiment is not null)
        then
        if (status_human = 'die')
            then
            return null;
        end if;
    return new;
    end if;
end;
$$ language 'plpgsql';

create trigger go_experiment_human_not_die before update on human     
    for each row execute procedure check_status_human_for_experiment();

/* 
тригер №8
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

create trigger time_exp_of_open_close before insert on experiment
    for each row execute procedure check_start_mission_time();

/*
Триггер №9 - верно на 99%
сделка не может быть совершена, если один из участников мёртв
*/
create or replace function check_status_mag_buyer_for_deal()
returns trigger as $$
declare
    status_mag text = get_status_mag(new.id_magician);
    status_buyer text = get_status_mag(new.id_buyer);
begin
    if (status_mag = 'die') or (status_buyer = 'die')
        then
        return null;
    else return new;
    end if;
end;
$$ language 'plpgsql';

create trigger status_mag_buyer_for_deal before insert on deal
    for each row execute procedure check_status_mag_buyer_for_deal();


/* функция получения статуса команды по id мага */
create or replace function get_status_team_by_mag_id(mag_id integer)
returns text as $$
begin
 return (select status_team from team where id = (select id_team from magician where magician.id = mag_id));
end;
$$ language 'plpgsql';

/* Функция получения статуса (жив/мёртв) мага по его id */
create or replace function get_status_mag(mag_id integer)
returns text as $$
begin
    return (select status from participant where id = (select id_participant from magician where magician.id = mag_id));
end
$$ language 'plpgsql';

/* Функция получения статуса (жив/мёртв) человека по его id */
create or replace function get_status_human(human_id integer)
returns text as $$
begin
    return (select status from participant where participant.id = (select id_participant from human where human.id = human_id));
end
$$ language 'plpgsql';
