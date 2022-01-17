/* создание сущностей для бд */

/* енам уровней OK*/
create type level as enum ('D', 'C', 'B', 'A', 'S');

create type status_team as enum ('free', 'busy', 'no_participant', 'disbanded');

/* предмет OK  */
create table item (
    item_code serial primary key,
    title varchar(32) not null,
    price_in_smoke integer not null
                  check (price_in_smoke > 0)
);


/* команда ОК */
create table team (
    id serial primary key,
    team_level level,
    status_team status_team
);

/* район ОК */
create table area (
    id serial primary key,
    level level
);

/* инвентарь ОК */
create table inventory (
    id serial primary key,
    free_slots integer not null
                       check (free_slots > 0 and free_slots < 100)
);

/* дверь ОК */
create table door (
    id serial primary key,
    id_area integer references area
                  on delete cascade
);

/* задание ОК */
create table mission (
    id serial primary key,
    id_team integer references team
                     on delete cascade,
    id_area integer references area
                     on delete cascade,
    start_time timestamp not null,
    end_time timestamp not null
);

/* эксперимент OK */
create table experiment (
    id serial primary key,
    id_mission integer references mission
                        on delete cascade,
    smoke_received integer not null
                        check (smoke_received > 0),
    time_exp timestamp not null
);


/* Участник OK */
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

/* человек OK */
create table human (
    id serial primary key,
    id_experiment integer references experiment
                   on delete set null
                   default null,
    id_participant integer references participant
                   on delete cascade
);

/* маг OK */
create table magician (
    id serial primary key,
    id_team integer references team
                      on delete set null
                      default null,
    id_participant integer references participant
                   on delete cascade ,
    amount_of_smoke integer not null
                      default 50
                      check (amount_of_smoke > 50)
);

/* инцидент ОК */
create table incident (
    id serial primary key,
    id_mission integer references mission
                      on delete cascade,
    id_magician integer references magician
                      on delete cascade
);

/* экземпляр предмета ОК */
create table exemplar (
    id serial primary key,
    id_item integer references item
                      on delete cascade,
    status varchar(32) not null
                      check (status = 'good' or status = 'bad')
);

/* покупатель ОК */
create table buyer
(
    id_magician  integer primary key references magician
        on delete cascade,
    id_inventory integer references inventory
        on delete cascade
);

/* сделка ОК */
create table deal (
    id serial primary key,
    id_buyer integer references buyer
                  on delete cascade,
    id_exemplar integer references exemplar
                  on delete cascade,
    id_magician integer references magician
                  on delete cascade,
    time_deal timestamp not null
);

/* наличие в инвенатаре предмета ОК */
create table presence (
    id_inventory integer references inventory
                      on delete cascade,
    id_item integer references item
                      on delete cascade
);

create table mission_log (
       id serial primary key,
       id_magician integer references magician
                      on delete cascade,
       id_mission integer references mission
                      on delete cascade
);


