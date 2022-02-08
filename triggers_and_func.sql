/*
тригер №1 - вероятность правильности 99%
сделка не может быть совершена во время задания одного из ее участников
Как проверять: сделать заведомо неправильный и правильный отдельный insert после того, как все заполниться
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
    return new;
    end if;
end;
$$ language 'plpgsql';

create trigger go_team_on_mission before update on team
    for each row execute procedure check_go_team_on_mission();

/*
Триггер №3
В команде не может быть больше 2-ух магов
очень большой вопрос в is null строчке: скорее всего там not null ПРОВЕРИТЬ НУЖНО!
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