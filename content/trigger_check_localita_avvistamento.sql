/*
  trigger per impedire l'inserimento di un avvistamento se la località
  non rientra tra gli habitat tipici della specie in quel periodo dell'anno.
  L'associazione non è interessata agli avvistamenti accidentali, e pertanto
  è necessario verificare la coerenza tra la località e gli habitat della specie.
  ricordiamo che un avvistamento si riferisce a una sola specie, ma può
  riguardare più esemplari della stessa specie.
*/
CREATE OR REPLACE TRIGGER trg_check_localita_avvistamento BEFORE
-- solo dopo che l'esemplare è stato inserito possiamo verificare
-- se l'avvistamento è valido, la procedura add_avvistamento
-- inserisce entrambi e fa rollback su tutto in caso di errore
  INSERT OR UPDATE ON esemplare
  FOR EACH ROW
DECLARE
  habitat_non_valido EXCEPTION;
  found_habitat  NUMBER(1) := 0;
  var_data_e_ora avvistamento.data_e_ora%TYPE;
  var_plus_code  avvistamento.plus_code%TYPE;
BEGIN
  -- Recupera data e località dell'avvistamento
  SELECT data_e_ora,
         plus_code
    INTO
    var_data_e_ora,
    var_plus_code
    FROM avvistamento
   WHERE codice_tessera_osservatore = :new.codice_tessera_osservatore
     AND n_avvistamento = :new.n_avvistamento;

  -- Verifica habitat
  SELECT COUNT(*)
    INTO found_habitat
    FROM associazione_localita_habitat l
   WHERE l.plus_code = var_plus_code
     AND EXISTS (
    SELECT 1
      FROM specie_vive_in_habitat v
     WHERE v.nome_scientifico_specie = :new.nome_scientifico_specie
       AND v.codice_eunis = l.codice_eunis
       AND TO_NUMBER(to_char(
      var_data_e_ora,
      'MM'
    )) BETWEEN v.periodo_inizio AND v.periodo_fine
  );

  IF found_habitat = 0 THEN
    RAISE habitat_non_valido;
  END IF;
EXCEPTION
  WHEN no_data_found THEN
    raise_application_error(
      -20013,
      'L''avvistamento specificato non esiste.'
    );
  WHEN habitat_non_valido THEN
    raise_application_error(
      -20014,
      'La località di avvistamento non è valida per la specie in quel periodo dell''anno.'
    );
END;
/