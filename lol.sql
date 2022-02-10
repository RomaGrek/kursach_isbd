/*
Важные детали (они есть)
*/

/* скрипт для удаления таблиц */

/* удаление енама */
drop type if exists level, status_team cascade;

/* удаление таблиц
truncate table item,
    team, area, inventory,
    mission, experiment,
    participant, human, magician,
    incident, exemplar, trader,
    deal, presence, mission_log;
 */
 drop table if exists item,
    team, area, inventory,
    mission, experiment,
    participant, human, magician,
    incident, exemplar, trader,
    deal, presence, mission_log cascade ;
drop function if exists get_status_team() cascade;

drop function if exists get_count_mags_in_team(integer) cascade;

drop function if exists update_status_team(text, integer) cascade;

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

drop function if exists get_end_time(timestamp) cascade;

drop function if exists get_time_exp(timestamp) cascade;

drop function if exists get_time() cascade;

drop function if exists get_value(integer, integer) cascade;

drop function if exists get_name() cascade;

drop function if exists get_title() cascade;

drop function if exists get_gender() cascade;


/* создание сущностей для бд */

/* енам уровней OK*/
create type level as enum ('D', 'C', 'B', 'A', 'S');

create type status_team as enum ('free', 'busy', 'no_participant', 'disbanded');

/* предмет OK  №1*/
create table item (
    item_code serial primary key,
    title varchar(32) not null,
    price_in_smoke integer not null
                  check (price_in_smoke > 0)
);


/* команда ОК №2*/
create table team (
    id serial primary key,
    team_level level  default null,
    status_team status_team not null
);

/* район ОК №3*/
create table area (
    id serial primary key,
    level level not null
);

/* инвентарь ОК №4*/
create table inventory (
    id serial primary key,
    busy_slots integer not null
                       check (busy_slots >= 0 and busy_slots < 100)
);

/* задание ОК №5*/
create table mission (
    id serial primary key,
    id_team integer references team
                     on delete cascade not null,
    id_area integer references area
                     on delete cascade not null,
    start_time timestamp not null,
    end_time timestamp default null,
                     check (start_time < end_time),
    count_exp integer not null default 0
);

/* эксперимент OK №6*/
create table experiment (
    id serial primary key,
    id_mission integer references mission
                        on delete cascade not null,
    smoke_received integer not null
                        check (smoke_received > 0),
    time_exp timestamp not null
);


/* Участник OK №7*/
create table participant (
    id serial primary key,
    name varchar(32) not null,
    gender varchar(1) not null
                         check ( gender = 'w' or gender = 'm' ),
    age integer not null
                         check ( age > 15 ),
    status varchar(32) not null
                         check ( status='die' or status = 'alive' )
);

/* человек OK №8*/
create table human (
    id serial primary key,
    id_experiment integer references experiment
                   on delete set null
                   default null,
    id_participant integer references participant
                   on delete cascade not null
);

/* маг OK №9*/
create table magician (
    id serial primary key,
    id_team integer references team
                      on delete set null
                      default null,
    id_participant integer references participant
                   on delete cascade not null,
    amount_of_smoke integer not null
                      default 50
                      check (amount_of_smoke > 50)
);

/* инцидент ОК №10*/
create table incident (
    id serial primary key,
    id_mission integer references mission
                      on delete cascade not null,
    id_magician integer references magician
                      on delete cascade not null
);

/* экземпляр предмета ОК №11*/
create table exemplar (
    id serial primary key,
    id_item integer references item
                      on delete cascade not null,
    id_inventory integer references inventory
		      on delete cascade not null,
    status varchar(32) not null
                      check (status = 'good' or status = 'bad')
);

/* покупатель ОК №12*/
create table trader
(
    id_magician  integer primary key references magician
        on delete cascade not null,
    id_inventory integer references inventory
        on delete cascade not null
);

/* сделка ОК №13*/
create table deal (
    id serial primary key,
    id_buyer integer references trader
                  on delete cascade not null,
    id_exemplar integer references exemplar
                  on delete cascade not null,
    id_seller integer references trader
                  on delete cascade not null,
    time_deal timestamp not null
);

/* история миссий ОК №14*/
create table mission_log (
       id serial primary key,
       id_magician integer references magician
                      on delete cascade not null,
       id_mission integer references mission
                      on delete cascade not null
);


/*
триггер №2
Команда не может быть отправлена на задание, если она находится на задании или расформирована
Сделать проверку новым неравильным и правильным update
*/
create or replace function check_go_team_on_mission()
returns trigger as $$
begin
    if (new.status_team = 'busy')
        then
        if (old.status_team <> 'free')
            then return null;
        end if;
    end if;
    return new;
end;
$$ language 'plpgsql';

create trigger go_team_on_mission before update on team
    for each row execute procedure check_go_team_on_mission();

/*
Триггер №3
Также установления статуса
Проверка на то, что в команде не может быть больше 2-ух магов
Вот эту штуку лучше лишний раз не трогать, вроде она работает
*/
create or replace function check_count_mag_in_team()
returns trigger as $$
begin
    if (tg_op = 'INSERT') then
        if (new.id_team is not null) then
            if (get_count_mags_in_team(new.id_team) > 1) then
                return null;
            else
                if (get_count_mags_in_team(new.id_team) = 0) then
                    perform update_status_team('no_participant', new.id_team);
                else
                    perform update_status_team('free', new.id_team);
                end if;
                return new;
            end if;
        else
            return new;
        end if;
    else
        if (old.id_team is null) then
            if (new.id_team is not null) then
                if (get_count_mags_in_team(new.id_team) > 1) then
                    return null;
                else
                    if (get_count_mags_in_team(new.id_team) = 0) then
                        perform update_status_team('no_participant', new.id_team);
                    else
                        perform update_status_team('free', new.id_team);
                    end if;
                    return new;
                end if;
            else
                return new;
            end if;
        else
            if (new.id_team is null) then
                if ((get_count_mags_in_team(old.id_team) - 1) = 1) then
                    perform update_status_team('no_participant', old.id_team);
                else
                    perform update_status_team('disbanded', old.id_team);
                end if;
                return new;
            else
                if (old.id_team = new.id_team) then
                    return new;
                else
                    if (get_count_mags_in_team(new.id_team) > 1) then
                        return null;
                    else
                        if (get_count_mags_in_team(old.id_team) - 1 = 1) then
                            perform update_status_team('no_participant', old.id_team);
                        else
                            perform update_status_team('disbanded', old.id_team);
                        end if;
                        if (get_count_mags_in_team(new.id_team) = 1) then
                            perform update_status_team('free', new.id_team);
                        else
                            perform update_status_team('no_participant', new.id_team);
                        end if;
                        return new;
                    end if;
                end if;
            end if;
        end if;
    end if;
end;
$$ language 'plpgsql';

create trigger joining_the_team before insert or update on magician     --- insert and update
    for each row execute procedure check_count_mag_in_team();

/*
триггер №4
На задания не могут отправляться мертвые маги
тоже нужна проверка отдельным апдейтом верным и не верным
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
 проверить
 */
create or replace function check_participant_id_for_mag()
returns trigger as $$
begin
    if ((select count(*) from human where new.id_participant = human.id_participant) > 0)
        then
        return null;
    end if;
    return new;
end;
$$ language 'plpgsql';

create trigger mag_participant_id before insert on magician
    for each row execute procedure check_participant_id_for_mag();

/*
 триггер №6 - верно на 99%
 Человек не может быть магом (ссылаться на одно и то же id)
 тоже проверочка станданртная нужна
 */
create or replace function check_participant_id_for_human()
returns trigger as $$
begin
    if ((select count(*) from magician where new.id_participant = magician.id_participant) > 0)
        then
        return null;
    else return new;
    end if;
end;
$$ language 'plpgsql';

create trigger human_participant_id before insert on human
    for each row execute procedure check_participant_id_for_human();

/*
триггер №7 - верно на 99%
Мертвые люди не могут участвовать в экспериментах
проверочка тоже нужна
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
проверочка тоже нужна
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

 */

/*
Триггер №10
Каждый раз когда генерим экзмепляр, там генеритьс id_инвентаря. У этого id должно прибавляться поле busy slots.
еще раз нужно будет проверить
*/
create or replace function add_count_busy_slots()
returns trigger as $$
begin

    if (tg_op = 'INSERT')
        then
        perform inc_dec_busy_slots(new.id_inventory, '+');
    elseif (tg_op = 'UPDATE')
        then
        perform inc_dec_busy_slots(old.id_inventory, '-');
        perform inc_dec_busy_slots(new.id_inventory, '+');
    end if;
    return new;

end;
$$ language 'plpgsql';


create trigger auto_add_count_busy_slots after insert or update on exemplar
    for each row execute procedure add_count_busy_slots();


/*
Триггер №11
Каждый раз когда добавляется id_mission у экмперимента, увеличиваем счетчик на 1
Вопрос на счет изменения в течении работы программы сущности эксперимент
*/
create or replace function add_count_exp_in_mission()
returns trigger as $$
begin
    perform inc_count_exp(new.id_mission);
    return new;
end;
$$ language 'plpgsql';

create trigger auto_add_count_exp_in_mission after insert on experiment
    for each row execute procedure add_count_exp_in_mission();

/*
Триггер №12
Изменение статуса команды при изменении id_team у магов

create or replace function change_status_team()
returns trigger as $$
declare
    count_mag_in_team integer = (select count(*) from magician where id_team = new.id_team);
begin
    if (tg_op = 'UPDATE')
        then

    end if;
    return new;
end;
$$ language 'plpgsql';

create trigger auto_change_status_team before update or insert on magician
    for each row execute procedure change_status_team();
*/

/*
create or replace function check_part_id_in_human()
returns trigger as $$
begin
    if ((select count(*) from experiment where experiment.id = new.id_experiment) = 0)
        then
        return null;
    else return new;
    end if;
end;
$$ language 'plpgsql';
create trigger go_part_id_in_human after insert on human
    for each row execute procedure check_part_id_in_human();
 */

/*
функция посчета количества магов в команде по id_team
*/

create or replace function get_count_mags_in_team(id_team_check integer)
returns integer as $$
begin
    return (select count(*) from magician where id_team = id_team_check);
end;
$$ language 'plpgsql';

/*
    функция установки статуса команде по её id
*/
create or replace function update_status_team(new_status_team text, id_team integer)
returns void as $$
begin
    update team set status_team = new_status_team::status_team  where team.id = id_team;
end;
$$ language 'plpgsql';

/* функция инкремента или декримента для изменения кол-ва занятых слотов
 */
create or replace function inc_dec_busy_slots(id_inventory_fk integer, operation varchar(1))
returns void as $$
begin
        if (operation = '+')
        then
        update inventory set busy_slots = busy_slots + 1 where inventory.id = id_inventory_fk;
    elseif (operation = '-')
        then
        update inventory set busy_slots = busy_slots - 1 where inventory.id = id_inventory_fk;
    end if;
end
$$ language 'plpgsql';

/*
функция инкремента количества экспериментов во время миссии
*/
create or replace function inc_count_exp(mission_id integer)
returns void as $$
begin
    update mission set count_exp = count_exp + 1 where mission.id = mission_id;
end;
$$ language 'plpgsql';

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

/*generate level*/
create or replace function get_level()
returns text as $$
declare
 temp integer:=trunc(random()*5)::integer+1;
begin
        return (select substring('ABCDS' from temp for 1));
end;
$$ language'plpgsql';

/*generate status_participant*/
create or replace function get_status_part()
returns text as $$
declare
 status_part text array[2] = '{"alive","die"}';
begin
 return status_part[trunc(random()*2)::integer+1];
end;
$$ language'plpgsql';

/*generate status_exm*/
create or replace function get_status_exm()
returns text as $$
declare
 status_exm text array[2] = '{"good","bad"}';
begin
 return status_exm[trunc(random()*2)::integer+1];
end;
$$ language 'plpgsql';

/*generate end_time*/
create or replace function get_end_time(start_time timestamp)
returns timestamp as $$
begin
 return (select(start_time::timestamp + (select get_value(1,7))*interval'1 days'));
end;
$$ language 'plpgsql';

/*generate exp_time*/
create or replace function get_time_exp(start_time timestamp)
returns timestamp as $$
begin
 return (select(start_time::timestamp + (select get_value(1,5))*interval'1 days'));
end;
$$ language 'plpgsql';

/*generate time*/
create or replace function get_time()
returns timestamp as $$
begin
 return (select('1930-01-01'::date + random()*365*interval'1 days' + random()*85*interval'1 years')::date);
end;
$$ language 'plpgsql';

/*generate value*/
create or replace function get_value(left_border integer, amount integer)
returns integer as $$
declare
 temp integer:=trunc(random()*amount)::integer;
begin
        return (temp + left_border);
end;
$$ language 'plpgsql';

/*generate name*/
create or replace function get_name()
returns varchar(45) as $$
declare
 temp integer:=trunc(random()*26)::integer+1;
begin
        return (select substring('abcdefghijklmnopqrstuvwxyz' from temp));
end;
$$ language 'plpgsql';

/*generate title*/
create or replace function get_title()
returns varchar(32) as $$
declare
 temp integer:=trunc(random()*25)::integer+1;
begin
        return (select substring('13467acegijklmnopqrstuvwxyz' from temp));
end;
$$ language 'plpgsql';

/*generate gender*/
create or replace function get_gender()
returns varchar(1) as $$
declare
 temp integer:=trunc(random()*2)::integer+1;
begin
        return(select substring('mw' from temp for 1));
end;
$$ language 'plpgsql';


/*=-=-=-=--=-=-=-SHORT FUNCTION(id)=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=*/

/*generate participant*/
insert into participant
select id, get_name(), get_gender(), get_value(16, 70), 'alive'
from generate_series(1, 30000) as id;

/*generate human*/
insert into human (id, id_participant)
select participant.id,participant.id
from participant where participant.id>10000;

/*generate magican*/
insert into magician (id, id_participant, amount_of_smoke)
select id, id, get_value(5000, 5000)
from generate_series(1, 10000) as id;

/*generate area*/
insert into area
select id, get_level()::level
from generate_series(1, 13) as id;

/*generate team*/
insert into team (id, status_team)
select id,  'disbanded'
from generate_series(1, 3500) as id;

/*update magician: set 1st member of team*/
update magician
set
	id_team=sub.id
from (select id from team) as sub where magician.id=sub.id and sub.id<=3000;

/*update magician: set 2nd member of team*/
update magician
set
	id_team=sub.id
from (select id from team) as sub where magician.id=(sub.id+3000) and sub.id<=3250;

/*generate mission*/
insert into mission
select id, id, get_value(1, 13), '1985-11-18'
from generate_series(1, 3000) as id;

/*update mission: set end time*/
update mission
set
	end_time=get_end_time('1985-11-18')
;

/*generate experiment*/
insert into experiment
select i, get_value(1, 2999), get_value(1, 200), get_end_time('1985-11-18')
from generate_series(1, 4000) as i;

/*update human*/
update human
set
	id_experiment=sub.id
from (select id from experiment) as sub where human.id=(sub.id+10000);

/*generate incident*/
insert into incident
select id, id, id
from generate_series(1, 500) as id;

/*generate mission_log 1st magician in team*/
insert into mission_log
select id, id, id
from generate_series(1, 3000) as id;

/*generate mission_log 2nd magician in team*/
insert into mission_log
select id, id, id-3000
from generate_series(3001, 6000) as id;

/*generate inventory*/
insert into inventory
select id, 0
from generate_series(3001, 5000) as id;

/*generate trader*/
insert into trader
select id, id
from generate_series(3001, 5000) as id;

/*generate item*/
insert into item
select id, get_title(), get_value(100, 1000)
from generate_series(1, 10000) as id;

/*generate exemplar*/
insert into exemplar
select id, get_value(1, 9999), get_value(3001, 1999), get_status_exm()
from generate_series(1, 5000) as id;

/*generate deal*/
insert into deal (id, id_buyer, id_exemplar, id_seller, time_deal)
select id, get_value(3001, 1999), get_value(1, 4999), get_value(1, 9999), get_end_time('1985-11-18')
from generate_series(1, 4000) as id;
