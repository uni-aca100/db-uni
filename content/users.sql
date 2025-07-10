--  DBMS: Oracle 19c 

-- Utente amministratore del database
CREATE USER db_admin IDENTIFIED BY adminpwd;
GRANT ALL PRIVILEGES TO db_admin;

-- Ruolo per i soci
CREATE ROLE ruolo_socio IDENTIFIED BY sociopwd;
GRANT connect,
  CREATE SESSION
TO ruolo_socio;

GRANT SELECT ON regione TO ruolo_socio;
GRANT SELECT ON localita_avvistamento TO ruolo_socio;
GRANT SELECT ON avvistamento TO ruolo_socio;
GRANT SELECT ON specie TO ruolo_socio;
GRANT SELECT ON habitat TO ruolo_socio;
GRANT SELECT ON esemplare TO ruolo_socio;
GRANT SELECT ON media TO ruolo_socio;
GRANT SELECT ON dispositivo_richiamo TO ruolo_socio;
GRANT SELECT ON pattern_migratori TO ruolo_socio;
GRANT SELECT ON badge TO ruolo_socio;
GRANT SELECT ON associazione_localita_habitat TO ruolo_socio;
GRANT SELECT ON specie_vive_in_habitat TO ruolo_socio;
GRANT SELECT ON socio_pubblico TO ruolo_socio;

-- Ruolo Socio revisore
CREATE ROLE ruolo_socio_revisore IDENTIFIED BY revisorepwd;
GRANT EXECUTE ON revisione_avvistamento TO ruolo_socio_revisore;

-- utente revisore_1, possiede un doppio ruolo, di socio e revisore
CREATE USER revisore_1 IDENTIFIED BY revisore1pwd;
GRANT ruolo_socio TO revisore_1;
GRANT ruolo_socio_revisore TO revisore_1;

-- utente socio_1, ruolo socio
CREATE USER socio_1 IDENTIFIED BY socio1pwd;
GRANT ruolo_socio TO socio_1;