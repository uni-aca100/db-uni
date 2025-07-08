/*
  trigger per impedire l'inserimento di un avvistamento se la località
  non rientra tra gli habitat tipici della specie in quel periodo dell'anno.
  L'associazione non è interessata agli avvistamenti accidentali, e pertanto
  è necessario verificare la coerenza tra la località e gli habitat della specie.
  ricordiamo che un avvistamento si riferisce a una sola specie, ma può
  riguardare più esemplari della stessa specie.
*/
CREATE OR REPLACE TRIGGER trg_check_localita_avvistamento BEFORE
  INSERT OR UPDATE ON avvistamento
  FOR EACH ROW
DECLARE
  habitat_non_valido EXCEPTION;
  var_specie_nome_scientifico specie.nome_scientifico%TYPE;
  found_habitat               NUMBER(1) := 0;
BEGIN
  -- uno stesso avvistamento anche se di più esemplari, 
  -- si riferisce a una sola specie.
  SELECT nome_scientifico_specie
    INTO var_specie_nome_scientifico
    FROM esemplare
   WHERE codice_avvistamento = :new.codice_avvistamento;

  /*
    Contiamo quante corrispondenze esistono tra gli habitat della
    località avvistamento (:new.plus_code) e gli habitat della specie
    osservata (var_specie_nome_scientifico) per il periodo dell'anno
    in cui è stato effettuato l'avvistamento (:new.data_avvistamento).
    In pratica, verifica se esiste almeno un habitat associato a quella
    località che sia anche un habitat tipico per la specie in quel periodo.
  */
  SELECT COUNT(*)
    INTO found_habitat
    FROM associazione_localita_habitat l
   WHERE l.plus_code = :new.plus_code
     AND EXISTS (
    SELECT 1
      FROM specie_vive_in_habitat v
     WHERE v.nome_scientifico_specie = var_specie_nome_scientifico
       AND v.codice_eunis = l.codice_eunis
       AND TO_NUMBER(to_char(
      :new.data_avvistamento,
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
      'La specie associata all''avvistamento non esiste.'
    );
  WHEN habitat_non_valido THEN
    raise_application_error(
      -20014,
      'La località di avvistamento non è valida per la specie in quel periodo dell''anno.'
    );
END;