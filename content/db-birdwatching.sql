--  DBMS: Oracle 19c 
/*
  Vista per mostrare le specie che vivono in un habitat specifico,
  nei vari periodi dell'anno, includendo il motivo.
*/
CREATE OR REPLACE VIEW specie_vive_in_habitat AS
  SELECT s.nome_scientifico AS nome_scientifico_specie,
         s.nome_comune AS nome_comune_specie,
         h.nome_habitat,
         h.codice_eunis,
         h.url_descrizione AS url_habitat,
         p.motivo_migrazione AS motivo,
         p.periodo_inizio,
         p.periodo_fine
    FROM specie s
    JOIN pattern_migratori p
  ON s.nome_scientifico = p.nome_scientifico_specie
    JOIN habitat h
  ON p.codice_eunis_habitat = h.codice_eunis;

/*
  procedura per validare un avvistamento da parte di un revisore
  la gestione dei vincoli dinamici è effettuata tramite trigger (trg_prevent_revisione)
  avremo potuto implementare la logica di controllo direttamente qui.
*/
CREATE OR REPLACE PROCEDURE make_revisione (
  p_codice_avvistamento     IN avvistamento.codice_avvistamento%TYPE,
  p_codice_tessera_revisore IN revisore.codice_tessera%TYPE,
  p_valutazione             IN avvistamento.valutazione%TYPE
) AS
BEGIN
  UPDATE avvistamento
     SET valutazione = p_valutazione,
         data_revisione = sysdate,
         codice_tessera_revisore = p_codice_tessera_revisore
   WHERE codice_avvistamento = p_codice_avvistamento;
END;


/*
  Trigger per impedire che un revisore validi i propri avvistamenti.
  Un revisore non può validare gli avvistamenti che ha effettuato come osservatore.
  Per prevenire che possa approfittarsi della sua posizione all'interno dell'associazione
*/
CREATE OR REPLACE TRIGGER trg_no_auto_revisione BEFORE
  UPDATE OF valutazione ON avvistamento
  FOR EACH ROW
DECLARE
  auto_revisione EXCEPTION;
BEGIN
  IF :new.codice_tessera_revisore = :old.codice_tessera_osservatore THEN
    RAISE auto_revisione;
  END IF;
EXCEPTION
  WHEN auto_revisione THEN
    raise_application_error(
      -20001,
      'Il revisore non può validare i propri avvistamenti.'
    );
END;

/*
  Trigger per impedire che un revisore modifichi la valutazione di un avvistamento
  già validato da un altro revisore.
  non è consentito che un revisore modifichi le revisioni effettuate da altri revisori.
  Il responsabile della revisione deve essere unico per ogni avvistamento
*/
CREATE OR REPLACE TRIGGER trg_no_modifica_revisione_altrui BEFORE
  UPDATE OF valutazione ON avvistamento
  FOR EACH ROW
DECLARE
  revisione_altrui EXCEPTION;
BEGIN
  IF :new.codice_tessera_revisore != :old.codice_tessera_revisore THEN
    RAISE revisione_altrui;
  END IF;
EXCEPTION
  WHEN revisione_altrui THEN
    raise_application_error(
      -20003,
      'Il revisore non può modificare le valutazioni di un avvistamento già validato da un altro revisore.'
    );
END;

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
  old_avvistamento    avvistamento.data_avvistamento%TYPE;
BEGIN
  -- Recupera la data di iscrizione del socio osservatore
  SELECT data_iscrizione
    INTO var_data_iscrizione
    FROM socio
   WHERE codice_tessera = :new.codice_tessera_osservatore;

  -- Se la data dell'avvistamento è precedente alla data di iscrizione, solleva errore
  IF :new.data_avvistamento < var_data_iscrizione THEN
    RAISE old_avvistamento;
  END IF;
EXCEPTION
  WHEN no_data_found THEN
    raise_application_error(
      -20011,
      'Il socio osservatore non esiste.'
    );
  WHEN old_avvistamento THEN
    raise_application_error(
      -20012,
      'Non è consentito inserire avvistamenti precedenti alla data di iscrizione del
      socio osservatore.'
    );
END;

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

/*
  Questo trigger impedisce l'inserimento di pattern migratori multipli
  per lo stesso habitat di una specie stanziale.
*/
CREATE OR REPLACE TRIGGER trg_check_multiple_pattern_migratori_stanziali BEFORE
  INSERT OR UPDATE ON pattern_migratori
  FOR EACH ROW
DECLARE
  var_same_habitat_count NUMBER := 0;
  duplicate_pattern_migratorio EXCEPTION;
BEGIN

  /*
  contiamo quanti pattern migratori "stanziali" esistono per la
  stessa specie e lo stesso habitat nella tabella pattern_migratori.
  */
  SELECT COUNT(*)
    INTO var_same_habitat_count
    FROM pattern_migratori
   WHERE codice_eunis = :new.codice_eunis
     AND nome_scientifico_specie = :new.nome_scientifico_specie
     AND motivo_migrazione = 'stanziale';

  IF var_same_habitat_count > 0 THEN
    RAISE duplicate_pattern_migratorio;
  END IF;
EXCEPTION
  WHEN duplicate_pattern_migratorio THEN
    raise_application_error(
      -20015,
      'Esiste già un pattern migratorio per questo habitat per una specie stanziale.'
    );
END;

/*
  Questo trigger impedisce l'inserimento di un pattern migratorio per
  una specie stanziale la cui durata non copra l'intero anno.
  Questo perché una specie stanziale dev'essere presente nel suo
  habitat per tutti i dodici mesi.

  Ricorda che i campi "periodo inizio" e "periodo fine" sono espressi in mesi,
  con valori da 1 (gennaio) a 12 (dicembre).
*/
CREATE OR REPLACE TRIGGER trg_check_year_pattern_migratori_stanziali BEFORE
  INSERT OR UPDATE ON pattern_migratori
  FOR EACH ROW
DECLARE
  not_all_year_stanziale EXCEPTION;
BEGIN
  IF
    :new.motivo_migrazione = 'stanziale'
    AND ( :new.periodo_inizio != 1
    OR :new.periodo_fine != 12 )
  THEN
    RAISE not_all_year_stanziale;
  END IF;
EXCEPTION
  WHEN not_all_year_stanziale THEN
    raise_application_error(
      -20019,
      'Un pattern migratorio stanziale deve coprire l''intero anno.'
    );
END;


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


/*
  funzione per la generazione univoca del codice di tessera per un socio.
  Pattern codice tessera:
    prefisso fisso ABW
    Sigla città (2–3 lettere maiuscole)
    anno da cui è stato iscritto il socio (4 cifre)
    iniziale del nome (1 lettera maiuscola) e iniziale del cognome (1 lettera maiuscola)
    numero progressivo (4 cifre, con zeri iniziali)
    esempio: ABWMI2020AB0001
*/
CREATE OR REPLACE FUNCTION genera_codice_tessera (
  p_nome        IN socio.nome%TYPE,
  p_cognome     IN socio.cognome%TYPE,
  p_sigla_citta IN VARCHAR2
) RETURN socio.codice_tessera%TYPE AS
  var_codice                  socio.codice_tessera%TYPE;
  var_count_year_subscription NUMBER;
  var_initial_name            VARCHAR2(1);
  var_initial_surname         VARCHAR2(1);
BEGIN
  var_initial_name := substr(
    upper(p_nome),
    1,
    1
  );
  var_initial_surname := substr(
    upper(p_cognome),
    1,
    1
  );

  -- contiamo il numero di soci iscritti nell'anno corrente
  SELECT COUNT(*)
    INTO var_count_year_subscription
    FROM socio
   WHERE trunc(
    data_iscrizione,
    'YYYY'
  ) = trunc(
    sysdate,
    'YYYY'
  );

  var_codice := 'ABW'
                || upper(p_sigla_citta)
                || to_char(
    sysdate,
    'YYYY'
  )
                || var_initial_name
                || var_initial_surname
                || to_char(
    var_count_year_subscription + 1,
    'FM0000'
  );

  RETURN var_codice;
END;

/*
  Funzione per generare un codice avvistamento univoco.
  Pattern codice avvistamento:
    codice tessera dell'osservatore (lunghezza 16)
    data dell'avvistamento (YYYYMMDD)
    numero progressivo (3 cifre, con zeri iniziali)
    esempio: ABWMI2020AB0001-20221012-001
    dove ABWMI2020AB0001 è il codice tessera dell'osservatore
    e 20221012-001 è la data dell'avvistamento (12 ottobre 2022) con il numero progressivo 001.
*/
CREATE OR REPLACE FUNCTION genera_codice_avvistamento (
  p_codice_tessera_osservatore IN avvistamento.codice_tessera_osservatore%TYPE,
  p_data_avvistamento          IN avvistamento.data_avvistamento%TYPE
) RETURN avvistamento.codice_avvistamento%TYPE AS
  var_count_avvistamento_today NUMBER := 0;
  var_codice                   avvistamento.codice_avvistamento%TYPE;
BEGIN
  -- troviamo il numero di avvistamenti effettuati oggi
  SELECT COUNT(*)
    INTO var_count_avvistamento_today
    FROM avvistamento
   WHERE codice_tessera_osservatore = p_codice_tessera_osservatore
     AND trunc(data_avvistamento) = trunc(p_data_avvistamento);

  -- generazione del codice avvistamento
  var_codice := p_codice_tessera_osservatore
                || '-'
                || to_char(
    p_data_avvistamento,
    'YYYYMMDD'
  )
                || '-'
                || to_char(
    var_count_avvistamento_today + 1,
    'FM000'
  );

  RETURN var_codice;
END;

/*
  Tipi di dati per le tabelle che richiedono array di valori.
  Questi tipi sono utilizzati per gestire i campi che accettano
  più valori, come maturità, sesso e condizioni di salute degli esemplari.
*/
CREATE OR REPLACE TYPE tbe_maturita AS
  TABLE OF esemplare.maturita%TYPE;
CREATE OR REPLACE TYPE tbe_sesso AS
  TABLE OF esemplare.sesso%TYPE;
CREATE OR REPLACE TYPE tbe_condizioni_salute AS
  TABLE OF esemplare.condizioni_salute%TYPE;

/*  
  Procedura Automatica di Inserimento Avvistamenti Questa procedura automatizza
  l'inserimento degli avvistamenti, gestendo anche le tabelle correlate. Vengono coinvolte:
    - Avvistamento (inserito sempre)
    - Osservatore (inserito solo se non già esistente)
    - Esemplare (sempre inserito)
    - Località_avvistamento (inserita solo se non già esistente)
    - Regione (inserita solo se non già esistente).

  La procedura fallisce se l'osservatore non è un socio già iscritto.

  Le informazioni relative a media e condizioni_ambientali sono opzionali e
  possono essere aggiunte in un secondo momento tramite inserimento manuale,
  evitando così di appesantire ulteriormente questa procedura.
*/
CREATE OR REPLACE PROCEDURE add_avvistamento (
  p_data_avvistamento          IN avvistamento.data_avvistamento%TYPE,
  p_ora_avvistamento           IN avvistamento.ora_avvistamento%TYPE,
  p_codice_tessera_osservatore IN avvistamento.codice_tessera_osservatore%TYPE,
  p_plus_code                  IN avvistamento.plus_code%TYPE,
  p_nome_localita              IN localita_avvistamento.nome%TYPE,
  p_area_protetta              IN localita_avvistamento.area_protetta%TYPE,
  p_url_mappa                  IN localita_avvistamento.url_mappa%TYPE,
  p_codice_eunis               IN localita_avvistamento.codice_eunis%TYPE,
  p_codice_iso_regione         IN localita_avvistamento.codice_iso_regione%TYPE,
  p_nome_regione               IN regione.nome_regione%TYPE,
  p_paese                      IN regione.paese%TYPE,
  p_maturita                   IN tbe_maturita,
  p_condizioni_salute          IN tbe_condizioni_salute,
  p_sesso                      IN tbe_sesso,
  p_nome_scientifico_specie    IN esemplare.nome_scientifico_specie%TYPE
) AS
  var_codice_avvistamento  avvistamento.codice_avvistamento%TYPE;
  var_n_avvistamento_today NUMBER := 0;
  socio_exists             NUMBER := 0;
  socio_non_esistente EXCEPTION;
BEGIN
  -- Verifica se il socio osservatore esiste
  SELECT COUNT(*)
    INTO socio_exists
    FROM socio
   WHERE codice_tessera = p_codice_tessera_osservatore;

  IF socio_exists = 0 THEN
    RAISE socio_non_esistente;
  END IF; 

  -- Inserimento del socio osservatore se non esiste
  -- dovuto dal fatto che potrebbe essere la sua prima osservazione
  INSERT INTO osservatore ( codice_tessera )
    SELECT p_codice_tessera_osservatore
      FROM dual
     WHERE NOT EXISTS (
      SELECT 1
        FROM osservatore
       WHERE codice_tessera = p_codice_tessera_osservatore
    );
    
  -- Inserimento della regione se non esiste
  INSERT INTO regione (
    codice_iso,
    nome_regione,
    paese
  )
    SELECT p_codice_iso_regione,
           p_nome_regione,
           p_paese
      FROM dual
     WHERE NOT EXISTS (
      SELECT 1
        FROM regione
       WHERE codice_iso = p_codice_iso_regione
    );

  -- Inserimento della località di avvistamento se non esiste
  INSERT INTO localita_avvistamento (
    plus_code,
    nome,
    area_protetta,
    url_mappa,
    codice_iso_regione,
    codice_eunis
  )
    SELECT p_plus_code,
           p_nome_localita,
           p_area_protetta,
           p_url_mappa,
           p_codice_iso_regione,
           p_codice_eunis
      FROM dual
     WHERE NOT EXISTS (
      SELECT 1
        FROM localita_avvistamento
       WHERE plus_code = p_plus_code
    );

  var_codice_avvistamento := genera_codice_avvistamento(
    p_codice_tessera_osservatore,
    p_data_avvistamento
  );

  -- Inserimento dell'avvistamento
  INSERT INTO avvistamento (
    codice_avvistamento,
    data_avvistamento,
    ora_avvistamento,
    codice_tessera_osservatore,
    plus_code
  ) VALUES ( var_codice_avvistamento,
             p_data_avvistamento,
             p_ora_avvistamento,
             p_codice_tessera_osservatore,
             p_plus_code );

  -- inserimento esemplari
  FOR i IN 1..p_maturita.count LOOP
    INSERT INTO esemplare (
      codice_avvistamento,
      numero_esemplare,
      maturita,
      condizioni_salute,
      sesso,
      nome_scientifico_specie
    ) VALUES ( var_codice_avvistamento,
               i,
               p_maturita(i),
               p_condizioni_salute(i),
               p_sesso(i),
               p_nome_scientifico_specie(i) );
  END LOOP;
  COMMIT;
EXCEPTION
  WHEN socio_non_esistente THEN
    raise_application_error(
      -20016,
      'Il socio osservatore specificato non esiste.'
    );
    ROLLBACK;
  WHEN OTHERS THEN
    raise_application_error(
      -20017,
      'Errore durante l''inserimento dell''avvistamento o degli esemplari.'
    );
    ROLLBACK;
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