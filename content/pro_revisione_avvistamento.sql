/*
  Questa procedura permette a un revisore effettuare la valutazione di
  un avvistamento. Durante l'operazione, vengono registrate
  la data della revisione (se non specificata, viene usata la data corrente)
  e il codice della tessera del revisore che ha eseguito la revisione.

La procedura verifica innanzitutto che l'avvistamento e il revisore esistano.
Inoltre, controlla che la data di revisione sia successiva sia alla data
dell'avvistamento che a quella di designazione del revisore.
Se queste condizioni non sono rispettate, verrà generata un'eccezione.

Requisiti per la Revisione:
Vengono imposti i seguenti requisiti per la valutazione:
    - Se all'avvistamento non sono associati media o condizioni ambientali
      e la specie si trova in stato di conservazione Criticamente Minacciata (CR) o In Pericolo (EN),
      la valutazione della revisione non può essere diversa da "non confermato".
    - Se all'avvistamento non è associato alcun contenuto multimediale,
      la valutazione della revisione non può essere "confermato".

Ricordiamo che i possibili stati di valutazione sono: "confermato", "possibile" e "non confermato".
  */

CREATE OR REPLACE PROCEDURE revisione_avvistamento (
  p_codice_avvistamento     IN avvistamento.codice_avvistamento%TYPE,
  p_codice_tessera_revisore IN revisore.codice_tessera%TYPE,
  p_valutazione             IN avvistamento.valutazione%TYPE,
  p_data_revisione          IN avvistamento.data_revisione%TYPE DEFAULT sysdate
) AS
  var_exists_avvistamento         NUMBER := 0;
  avvistamento_not_found EXCEPTION;
  revisore_not_found EXCEPTION;
  revisore_precedente_designazione EXCEPTION;
  revisione_precedente_avvistamento EXCEPTION;
  revisione_cannot_be_confirmed EXCEPTION;
  revisione_must_be_not_confirmed EXCEPTION;
  var_data_designazione_revisore  revisore.data_attribuzione%TYPE;
  var_media_count                 NUMBER := 0;
  var_condizioni_ambientali_count NUMBER := 0;
  var_revisore_exists             NUMBER := 0;
  var_stato_conservazione         specie.stato_conservazione%TYPE;
BEGIN
  -- Verifica se l'avvistamento esiste
  SELECT COUNT(*)
    INTO var_exists_avvistamento
    FROM avvistamento
   WHERE codice_avvistamento = p_codice_avvistamento;

  IF var_exists_avvistamento = 0 THEN
    RAISE avvistamento_not_found;
  END IF;

  -- Verifica se il revisore esiste e recupera la data di designazione
  SELECT COUNT(*)
    INTO var_revisore_exists
    FROM revisore
   WHERE codice_tessera = p_codice_tessera_revisore;

  IF var_revisore_exists = 0 THEN
    RAISE revisore_not_found;
  END IF;

  -- Verifica che la revisione non sia precedente alla designazione
  SELECT data_attribuzione
    INTO var_data_designazione_revisore
    FROM revisore
   WHERE codice_tessera = p_codice_tessera_revisore;

  IF p_data_revisione < var_data_designazione_revisore THEN
    RAISE revisore_precedente_designazione;
  END IF;

  -- Verifica se l'avvistamento è stato effettuato prima della data di revisione
  SELECT COUNT(*)
    INTO var_exists_avvistamento
    FROM avvistamento
   WHERE codice_avvistamento = p_codice_avvistamento
     AND data_avvistamento <= p_data_revisione;

  IF var_exists_avvistamento = 0 THEN
    RAISE revisione_precedente_avvistamento;
  END IF;

  -- Recupera lo stato di conservazione della specie associata all'avvistamento
  -- tutti gli esemplari di un avvistamento si riferiscono alla stessa specie
  SELECT stato_conservazione
    INTO var_stato_conservazione
    FROM specie s
   WHERE s.nome_scientifico = (
    SELECT MIN(e.nome_scientifico_specie)
      FROM esemplare e
     WHERE e.codice_avvistamento = p_codice_avvistamento
  );

  -- Controlla se l'avvistamento ha media associati
  SELECT COUNT(*)
    INTO var_media_count
    FROM media
   WHERE codice_avvistamento = p_codice_avvistamento;

  -- Controlla se l'avvistamento ha condizioni ambientali associate
  SELECT COUNT(*)
    INTO var_condizioni_ambientali_count
    FROM condizioni_ambientali
   WHERE codice_avvistamento = p_codice_avvistamento;

  -- Verifica i requisiti per la valutazione
  IF
    var_media_count = 0
    AND p_valutazione = 'confermato'
  THEN
    RAISE revisione_cannot_be_confirmed;
  ELSIF
    var_media_count = 0
    AND var_condizioni_ambientali_count = 0
    AND var_stato_conservazione IN ( 'CR',
                                     'EN' )
    AND p_valutazione = 'confermato'
  THEN
    RAISE revisione_cannot_be_confirmed;
  END IF;

  -- Aggiorna l'avvistamento con la valutazione e la data di revisione
  -- una volta che sono stati verificati i requisiti
  UPDATE avvistamento
     SET valutazione = p_valutazione,
         data_revisione = p_data_revisione,
         codice_tessera_revisore = p_codice_tessera_revisore
   WHERE codice_avvistamento = p_codice_avvistamento;
  COMMIT;
EXCEPTION
  WHEN avvistamento_not_found THEN
    raise_application_error(
      -20007,
      'L''avvistamento specificato non esiste.'
    );
    ROLLBACK;
  WHEN revisore_not_found THEN
    raise_application_error(
      -20008,
      'Il revisore specificato non esiste.'
    );
    ROLLBACK;
  WHEN revisore_precedente_designazione THEN
    raise_application_error(
      -20009,
      'La data di revisione non può essere precedente alla data di designazione del revisore.'
    );
    ROLLBACK;
  WHEN revisione_precedente_avvistamento THEN
    raise_application_error(
      -20010,
      'La data di revisione non può essere precedente alla data dell''avvistamento.'
    );
    ROLLBACK;
  WHEN revisione_cannot_be_confirmed THEN
    raise_application_error(
      -20018,
      'La revisione non può essere confermata se non sono associati media o condizioni ambientali, o se la specie è in stato di conservazione Criticamente Minacciata (CR) o In Pericolo (EN).'
    );
    ROLLBACK;
  WHEN revisione_must_be_not_confirmed THEN
    raise_application_error(
      -20021,
      'La revisione deve essere "non confermato" se non sono associati media o condizioni ambientali e la specie è in stato di conservazione Criticamente Minacciata (CR) o In Pericolo (EN).'
    );
    ROLLBACK;
  WHEN OTHERS THEN
    raise_application_error(
      -20020,
      'Errore durante la revisione dell''avvistamento.'
    );
    ROLLBACK;
END;
/