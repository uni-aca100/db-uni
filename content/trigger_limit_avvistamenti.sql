/*
  questo trigger implementa il vincolo:
  Ogni socio può registrare al massimo 15 esemplari,
  appartenenti alla stessa specie e con lo stesso stato di maturità,
  avvistati nella stessa località nell’arco di una settimana.

  limita gli inserimenti eccessivi, riducendo il rischio di dati anomali o poco credibili.
*/
CREATE OR REPLACE TRIGGER trg_limit_avvistamenti
BEFORE INSERT OR UPDATE ON esemplare
-- solo dopo che l'esemplare è stato inserito possiamo verificare
-- se l'avvistamento è valido, facciamo affidamento sulla procedura
-- add_avvistamento che in caso di errore effettua il rollback
FOR EACH ROW
DECLARE
  var_count_avv NUMBER;
  var_new_avv avvistamento%ROWTYPE;
  too_many_avvistamenti EXCEPTION;
BEGIN
  SELECT * INTO var_new_avv FROM avvistamento
  WHERE codice_tessera_osservatore = :new.codice_tessera_osservatore
    AND n_avvistamento = :new.n_avvistamento;

  -- ottiene il numero di esemplari avvistati per lo stesso socio
  -- nella stessa località e con lo stesso stato di maturità
  SELECT COUNT(*)
  INTO var_count_avv
  FROM avvistamento a
  JOIN localita_avvistamento l ON a.plus_code = l.plus_code
  JOIN esemplare e ON a.codice_tessera_osservatore = e.codice_tessera_osservatore
    AND a.n_avvistamento = e.n_avvistamento
  JOIN specie s ON e.nome_scientifico_specie = s.nome_scientifico
  WHERE a.codice_tessera_osservatore = :new.codice_tessera_osservatore
    AND l.plus_code = var_new_avv.plus_code
    AND e.maturita = :new.maturita
    AND e.nome_scientifico_specie = :new.nome_scientifico_specie
    AND TRUNC(a.data_e_ora) BETWEEN TRUNC(var_new_avv.data_e_ora) - 6 AND TRUNC(var_new_avv.data_e_ora);


 IF var_count_avv >= 15 THEN
    raise too_many_avvistamenti;
  END IF;
    
EXCEPTION
  WHEN no_data_found THEN
    raise_application_error(
      -20015,
      'L''avvistamento specificato non esiste.'
    );
  WHEN too_many_avvistamenti THEN
    raise_application_error(
      -20016,
      'Il socio ha già registrato il numero massimo di avvistamenti per la stessa specie e stato di maturità nella stessa località nell''arco di una settimana.'
    );
END;
/