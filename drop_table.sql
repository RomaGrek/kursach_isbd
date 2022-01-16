/* скрипт для удаления таблиц */

/* удаление енама */
drop type if exists level, status_team cascade;

/* удаление таблиц */
drop table if exists item,
    team, area, inventory,
    door, mission, experiment,
    participant, human, magician,
    incident, exemplar, buyer,
    deal, presence, mission_log cascade;