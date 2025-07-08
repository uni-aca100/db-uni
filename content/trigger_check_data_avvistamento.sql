/*
  Trigger impedisce l'inserimento di un avvistamento effettuato precedentemente
  alla data di iscrizione del socio.
  Non è consentito ai soci l'inserimento di avvistamenti precedenti alla loro data di iscrizione.
  Un Socio può contribuire alle attività dell'associazione solo dopo essersi iscritto.
*/
CREATE OR REPLACE TRIGGER trg_check_data_avvistamento BEFORE
  INSERT OR UPDATE ON avvistamento
  FOR EACH ROW
DECLARE
  var_data_iscrizione socio.data_iscrizione%TYPE;
  date_avvistamento_precedente EXCEPTION;
BEGIN
  -- Recupera la data di iscrizione del socio osservatore
  SELECT data_iscrizione
    INTO var_data_iscrizione
    FROM socio
   WHERE codice_tessera = :new.codice_tessera_osservatore;

  -- Se la data dell'avvistamento è precedente alla data di iscrizione, solleva errore
  IF :new.data_avvistamento < var_data_iscrizione THEN
    RAISE date_avvistamento_precedente;
  END IF;
EXCEPTION
  WHEN no_data_found THEN
    raise_application_error(
      -20011,
      'Il socio osservatore non esiste.'
    );
  WHEN date_avvistamento_precedente THEN
    raise_application_error(
      -20012,
      'Non è consentito inserire avvistamenti precedenti alla data di iscrizione del
      socio osservatore.'
    );
END;