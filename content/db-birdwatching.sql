/*
  La funzione conta e restituisce il numero di avvistamenti
  di un socio nello stato specificato dal parametro.
*/
CREATE OR REPLACE FUNCTION count_avvistamenti (
  par_codice_tessera IN avvistamento.codice_tessera_osservatore%TYPE,
  par_valutazione    IN avvistamento.valutazione%TYPE
) RETURN NUMBER AS
  var_count NUMBER := 0;
BEGIN
  SELECT COUNT(*)
    INTO var_count
    FROM avvistamento
   WHERE codice_tessera_osservatore = par_codice_tessera
     AND valutazione = par_valutazione;

  RETURN var_count;
END;

/*
  Questo trigger impedisce l'assegnazione di un badge se i relativi criteri non sono stati soddisfatti.
  Di seguito i requisiti specifici per ciascun badge:
    - Badge "Occhio di Colibrì": Assegnabile solo se il socio ha effettuato almeno 10 avvistamenti confermati.
    - Badge "Occhio di Kakapo": Assegnabile solo se il socio ha effettuato almeno un avvistamento confermato.
    - Badge "Custode della Natura": Assegnabile dopo almeno un avvistamento confermato di una specie in stato
      di conservazione Criticamente Minacciata (CR) o In Pericolo (EN).
*/
CREATE OR REPLACE TRIGGER trg_check_badge_assegnazione BEFORE
  INSERT ON badge
  FOR EACH ROW
DECLARE
  var_avvistamenti_confermati NUMBER := 0;
  var_exists_cr_en            NUMBER := 0;
  requirement_not_met_custode EXCEPTION;
  requirement_not_met_colibri EXCEPTION;
  requirement_not_met_kakapo EXCEPTION;
BEGIN
  IF :new.nome_badge = 'custode della natura' THEN
    -- Verifica se è stata effettuata almeno un'osservazione di una specie in stato CR o EN
    SELECT COUNT(*)
      INTO var_exists_cr_en
      FROM avvistamento a
     WHERE a.codice_tessera_osservatore = :new.codice_tessera_socio
       AND a.valutazione = 'confermato'
       AND EXISTS (
      SELECT 1
        FROM esemplare e
       WHERE e.codice_avvistamento = a.codice_avvistamento
         AND e.nome_scientifico_specie IN (
        SELECT nome_scientifico
          FROM specie s
         WHERE s.stato_conservazione IN ( 'CR',
                                          'EN' )
      )
    );

    IF var_exists_cr_en = 0 THEN
      RAISE requirement_not_met_custode;
    END IF;
  ELSE
    SELECT count_avvistamenti(
      :new.codice_tessera_socio,
      'confermato'
    )
      INTO var_avvistamenti_confermati
      FROM dual;

    IF
      :new.nome_badge = 'occhio di colibrì'
      AND var_avvistamenti_confermati < 10
    THEN
      RAISE requirement_not_met_colibri;
    ELSIF
      :new.nome_badge = 'occhio di kakapo'
      AND var_avvistamenti_confermati < 1
    THEN
      RAISE requirement_not_met_kakapo;
    END IF;

  END IF;
EXCEPTION
  WHEN requirement_not_met_custode THEN
    raise_application_error(
      -20022,
      'Il badge "Custode della natura" può essere assegnato solo dopo la prima osservazione di una specie in uno stato di conservazione Criticamente Minacciata (CR) o in Pericolo (EN).'
    );
  WHEN requirement_not_met_colibri THEN
    raise_application_error(
      -20023,
      'Il badge "Occhio di Colibrì" può essere assegnato solo dopo aver effettuato almeno 10 avvistamenti confermati.'
    );
  WHEN requirement_not_met_kakapo THEN
    raise_application_error(
      -20024,
      'Il badge "Occhio di Kakapo" può essere assegnato solo dopo il primo avvistamento confermato.'
    );
END;





/*  Procedura per inserire un media associato a un avvistamento.
  La procedura verifica che il codice_avvistamento esista prima di procedere
  con l'inserimento del media. Se il codice_avvistamento non esiste, viene sollevata
  un'eccezione.
*/
CREATE OR REPLACE PROCEDURE insert_media (
  p_codice_avvistamento IN media.codice_avvistamento%TYPE,
  p_titolo_media        IN media.titolo_media%TYPE,
  p_tipo_media          IN media.tipo_media%TYPE,
  p_url_media           IN media.url_media%TYPE,
  p_formato_media       IN media.formato_media%TYPE
) IS
  media_exists NUMBER;
BEGIN
  SELECT 1
    INTO media_exists
    FROM avvistamento
   WHERE codice_avvistamento = p_codice_avvistamento;

  INSERT INTO media (
    codice_avvistamento,
    titolo_media,
    tipo_media,
    url_media,
    formato_media
  ) VALUES ( p_codice_avvistamento,
             p_titolo_media,
             p_tipo_media,
             p_url_media,
             p_formato_media );

EXCEPTION
  WHEN no_data_found THEN
    raise_application_error(
      -20002,
      'Il codice avvistamento specificato non esiste.'
    );
  WHEN OTHERS THEN
    raise_application_error(
      -20004,
      'Errore durante l''inserimento del media'
    );
END;


/*
  Questa procedura automatizza l'inserimento di pattern migratori e degli
  habitat ad essi associati per una data specie.
  La procedura gestisce l'inserimento di:
    - Pattern Migratori: Viene inserito un nuovo pattern migratorio
    associato a una specie e a un habitat specifico.
    - Habitat: Un nuovo habitat viene inserito e associato al pattern
    migratorio specificato, solo se non esiste già.
    - Specie: Una nuova specie viene inserita, solo se non è già presente.

  Vengono costruiti automaticamente i pattern migratori e gli habitat
  di destinazione associati alle diverse specie.

  Per le specie stanziali, il pattern migratorio deve coprire l'intero anno.
  Questo significa che il periodo_inizio deve essere 1 (gennaio)
  e il periodo_fine deve essere 12 (dicembre).
  Tale vincolo è gestito dal trigger trg_check_year_pattern_migratori_stanziali.

  Se il pattern migratorio esiste già (duplicato), viene sollevata specificamente
  un'eccezione.
*/
CREATE OR REPLACE PROCEDURE add_pattern_migratorio (
  p_nome_scientifico    IN specie.nome_scientifico%TYPE,
  p_nome_comune         IN specie.nome_comune%TYPE,
  p_stato_conservazione IN specie.stato_conservazione%TYPE,
  p_famiglia            IN specie.famiglia%TYPE,
  p_url_verso           IN specie.url_verso%TYPE,
  p_url_immagine        IN specie.url_immagine%TYPE,
  p_motivo_migrazione   IN pattern_migratorio.motivo_migrazione%TYPE,
  p_periodo_inizio      IN pattern_migratorio.periodo_inizio%TYPE,
  p_periodo_fine        IN pattern_migratorio.periodo_fine%TYPE,
  p_codice_eunis        IN habitat.codice_eunis%TYPE,
  p_nome_habitat        IN habitat.nome_habitat%TYPE,
  p_url_descrizione     IN habitat.url_descrizione%TYPE
) IS
  specie_exists  NUMBER;
  pattern_exists NUMBER;
  duplicate_pattern_migratorio EXCEPTION;
BEGIN
  -- Se la specie non esiste, la inseriamo
  INSERT INTO specie (
    nome_scientifico,
    nome_comune,
    stato_conservazione,
    famiglia,
    url_verso,
    url_immagine
  )
    SELECT p_nome_scientifico,
           p_nome_comune,
           p_stato_conservazione,
           p_famiglia,
           p_url_verso,
           p_url_immagine
      FROM dual
     WHERE NOT EXISTS (
      SELECT 1
        FROM specie
       WHERE nome_scientifico = p_nome_scientifico
    );

  -- se l'habitat non esiste, lo inseriamo
  INSERT INTO habitat (
    codice_eunis,
    nome_habitat,
    url_descrizione
  )
    SELECT p_codice_eunis,
           p_nome_habitat,
           p_url_descrizione
      FROM dual
     WHERE NOT EXISTS (
      SELECT 1
        FROM habitat
       WHERE codice_eunis = p_codice_eunis
    );

  -- verifica che il pattern migratorio non esista già
  SELECT COUNT(*)
    INTO pattern_exists
    FROM pattern_migratori
   WHERE nome_scientifico_specie = p_nome_scientifico
     AND codice_eunis_habitat = p_codice_eunis
     AND motivo_migrazione = p_motivo_migrazione;

  IF pattern_exists > 0 THEN
    RAISE duplicate_pattern_migratorio;
  END IF;

  -- Inserimento dei pattern migratori associati
  INSERT INTO pattern_migratori (
    nome_scientifico_specie,
    codice_eunis_habitat,
    motivo_migrazione,
    periodo_inizio,
    periodo_fine
  ) VALUES ( p_nome_scientifico,
             p_codice_eunis,
             p_motivo_migrazione,
             p_periodo_inizio,
             p_periodo_fine );

  COMMIT;
EXCEPTION
  WHEN duplicate_pattern_migratorio THEN
    raise_application_error(
      -20002,
      'Esiste già un pattern migratorio per questa specie e habitat.'
    );
    ROLLBACK;
  WHEN OTHERS THEN
    raise_application_error(
      -20003,
      'Errore durante l''inserimento della specie o dei pattern migratori'
    );
    ROLLBACK;
END;


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
  revisore_precedente_avvistamento EXCEPTION;
  revisione_cannot_be_confirmed EXCEPTION;
  revisione_must_be_not_confirmed EXCEPTION;
  var_data_designazione_revisore  revisore.data_assegnazione%TYPE;
  var_media_count                 NUMBER := 0;
  var_condizioni_ambientali_count NUMBER := 0;
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
  SELECT data_assegnazione
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
  WHEN revisore_precedente_avvistamento THEN
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