CREATE USER socio IDENTIFIED BY socio
  DEFAULT TABLESPACE users
  TEMPORARY TABLESPACE temp;

GRANT connect,resource TO socio;

CREATE USER socio_revisore IDENTIFIED BY socio_revisore
  DEFAULT TABLESPACE users
  TEMPORARY TABLESPACE temp;

GRANT connect,resource TO socio_revisore;

CREATE USER responsabile IDENTIFIED BY responsabile
  DEFAULT TABLESPACE users
  TEMPORARY TABLESPACE temp;

GRANT connect,resource TO responsabile;