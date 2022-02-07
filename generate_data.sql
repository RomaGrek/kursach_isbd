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

/*generate status_team; нет статуса "busy" чтобы избежать нестыковок по времени*/
create or replace function get_status_team()
returns text as $$
declare
 status_team text array[4] = '{"free","no_participant","disbanded"}';
begin
        return status_team[trunc(random()*3)::integer+1];
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
select id, get_name(), get_gender(), get_value(16, 70), get_status_part()
from generate_series(1, 3000000) as id;

/*generate area*/
insert into area
select id, get_level()::level
from generate_series(1, 13) as id;

/*generate door*/
insert into door
select id, get_value(1, 13)
from generate_series(1, 999) as id;

/*generate team*/
insert into team
select id, get_level()::level, get_status_team()::status_team
from generate_series(1, 300000) as id;

/*generate mission*/
insert into mission
select id, get_value(1, 299999), get_value(1, 13), t, get_end_time(t)
from generate_series(1, 500000) as id, get_time() as t;

/*generate experiment*/
insert into experiment
select i, id_mis.id, get_value(1, 200), get_end_time(id_mis.start_time)
from generate_series(1, 700000) as i,
 (select id, start_time from mission where (id=get_value(1, 499999))) as id_mis;

/*generate human*/
insert into human
select id, get_value(1, 699999), id
from generate_series(1000001, 3000000) as id;

/*generate magican*/
insert into magician
select id, get_value(1, 299999), id, get_value(51, 2000)
from generate_series(1, 1000000) as id;

/*generate mission_log*/
insert into mission_log
select id, get_value(1, 999999), get_value(1, 499999)
from generate_series(1, 500000) as id;

/*generate incident*/
insert into incident
select id, get_value(1, 499999), get_value(1, 999999)
from generate_series(1, 100000) as id;

/*generate inventory*/
insert into inventory
select id, 0  
from generate_series(300001, 500000) as id;

/*generate buyer*/
insert into buyer
select id, id
from generate_series(300001, 500000) as id;

/*generate item*/
insert into item
select id, get_title(), get_value(100, 1000)
from generate_series(1, 1000000) as id;

/*generate exemplar*/
insert into exemplar
select id, get_value(1, 999999), get_value(300001, 199999), get_status_exm()
from generate_series(1, 500000) as id;
 
/*generate deal*/
insert into deal (id, id_buyer, id_exemplar, id_magician, time_deal)
select id, get_value(300001, 199999), get_value(1, 499999), get_value(1, 999999), get_time()
from generate_series(1, 400000) as id;
