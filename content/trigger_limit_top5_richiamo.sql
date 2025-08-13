/*
  Trigger che implementa il vincolo:
  Gli osservatori che rientrano tra i primi 5 per numero di
  avvistamenti effettuati utilizzando dispositivi di richiamo
  non possono registrare ulteriori avvistamenti che prevedano
  l’impiego di tali dispositivi.
*/
CREATE OR REPLACE TRIGGER trg_limit_top5_richiamo
BEFORE INSERT ON dispositivo_richiamo
-- facciamo affidamento sulla procedura add_avvistamento
-- che in caso di errore effettua il rollback anche
-- dell'avvistamento stesso
FOR EACH ROW
DECLARE
  too_many_avvistamenti EXCEPTION;
  var_oss_is_top_5 NUMBER;
BEGIN
  select count(*) into var_oss_is_top_5
  from (
      select o.codice_tessera
      from osservatore o
      join avvistamento a on o.codice_tessera = a.codice_tessera_osservatore
      join dispositivo_richiamo d on d.codice_tessera_osservatore = o.codice_tessera
      group by o.codice_tessera
      order by count(*) desc
      fetch first 5 rows only
  ) where :new.codice_tessera_osservatore = codice_tessera;
  
  -- Trova i primi 5 osservatori per numero di avvistamenti con dispositivi di richiamo
  -- e verifica se l'osservatore corrente è tra questi
  IF var_oss_is_top_5 > 0 THEN
    raise too_many_avvistamenti;
  end if;

EXCEPTION
  WHEN too_many_avvistamenti THEN
    RAISE_APPLICATION_ERROR(
      -20038,
      'L''osservatore ha già raggiunto il limite (tra i primi 5 per numero di utilizzo) di avvistamenti con dispositivi di richiamo.'
    );
END;
/