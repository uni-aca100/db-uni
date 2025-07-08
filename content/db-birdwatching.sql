--  DBMS: Oracle 19c 

/* Modello concettuale :

  Entità forti:
    - Socio:
      PK: codice_tessera
      Attributi: nome, cognome, email, telefono, data_nascita, data_iscrizione
      Specializzazioni totale e non disgiunta nei sottotipi:
      - Osservatore:
        PK: codice_tessera (ereditato da Socio)
        Attributi: nessuno specifico
      - Revisore:
        PK: codice_tessera (ereditato da Socio)
        Attributi: data_attribuzione.

    - Avvistamento:
      PK: codice_avvistamento
      Attributi:
        data_avvistamento,
        ora_avvistamento
        valutazione (confermato, possibile, non confermato),
        data_revisione (opzionale),
      FK: codice_tessera_osservatore (riferimento a Socio)
      FK: codice_tessera_revisore (riferimento a Socio, opzionale)
      FK: plus_code (riferimento a località_avvistamento)

    - Specie:
      PK: nome_scientifico
      Attributi:
        nome_comune,
        stato_conservazione,
        famiglia,
        url_verso,
        url_immagine

    - Regione:
      PK: codice_iso
      Attributi:
        nome_regione,
        paese,

    - località_avvistamento:
      PK: plus_code
      Attributi:
        nome,
        area_protetta (booleano),
        url_mappa,
      FK: codice_iso_regione (riferimento a Regione)

    - Habitat:
      PK: codice_EUNIS
      Attributi:
        nome_habitat,
        url_descrizione,
      
  Entità deboli:
    - Esemplare:
      PK: (codice_avvistamento, numero_esemplare)
      Attributi:
        maturità (adulto, giovane), 
        condizioni_salute (salute, ferito, malato),
        sesso (maschio, femmina, sconosciuto),
      FK: codice_avvistamento (riferimento a Avvistamento)
      FK: nome_scientifico_specie (riferimento a Specie)
    
    - Media:
      PK: (codice_avvistamento, titolo_media)
      Attributi:
        tipo_media (foto, video, audio),
        url_media,
        formato_media (jpg, png, mp4, mp3, wav),
        titolo_media,
      FK: codice_avvistamento (riferimento a Avvistamento)

    - Condizioni_Ambientali:
      PK: codice_avvistamento
      Attributi:
        meteo (sole, nuvoloso, pioggia, neve),
        temperatura (in gradi Celsius),
        umidità (percentuale),
        vento (veloce, moderato, debole, assente),
      FK: codice_avvistamento (riferimento a Avvistamento)

    - badge:
      PK: (nome_badge, codice_tessera_socio)
      Attributi:
        data_assegnazione,
        criterio_assegnazione (es: primo avvistamento, decimo avvistamento, prima osservazione di una specie in stato CR o EN),
        url_badge (opzionale, per badge con immagini),
      FK: codice_tessera_socio (riferimento a Socio)

  Relazioni:
    - Osservatore(Socio) (1,1) [effettua] (1,N) Avvistamento
      Un osservatore può effettuare più avvistamenti, ma ogni avvistamento
      è effettuato da un solo osservatore.
    
    - Revisore(Socio) (0,1) [valida] (0,N) Avvistamento 
      Un revisore può validare più avvistamenti, ma ogni avvistamento può essere
      validato da un solo revisore.

    - Avvistamento (1,1) [contiene] (1,N) Esemplare
      Un avvistamento può contenere più esemplari, ma ogni esemplare è associato
      a un solo avvistamento.

    - Avvistamento (1,1) [ha] (0,N) Media
      Un avvistamento può avere più media associati, ma ogni media è associato
      a un solo avvistamento.

    - Avvistamento (1,1) [ha] (0,1) Condizioni_Ambientali
      Un avvistamento può avere condizioni ambientali associate, ma non è obbligatorio.
      Ogni avvistamento può avere al massimo una condizione ambientale associata.

    - Avvistamento (1,N) [avviene_in] (1,1) località_avvistamento
      Un avvistamento può avvenire in una sola località_avvistamento, ma una località_avvistamento può
      essere associata a più avvistamenti.

    - località_avvistamento (1,N) [appartiene_a] (1,1) Regione
      Una località_avvistamento può appartenere a una sola regione, ma una regione può
      avere più località_avvistamento associate.

    - Specie (1,1) [possiede] (1,N) pattern_migratori
      Una specie può possedere più pattern migratori.
      Ogni pattern migratorio è associato a una sola specie.

    - Habitat (1,N) [è_associato_a] (0,N) pattern_migratori
      Un habitat può essere associato a più pattern migratori, ma un pattern migratorio è associato a un solo habitat.

    - Habitat (1,N) [è_presentato_in] (0,N) località_avvistamento
      Un habitat può essere presentato in più località_avvistamento,
      ma una località_avvistamento può presentare più habitat.

    - osservatore (1,1) [ha_ottenuto] (0,N) badge
      Un osservatore può ottenere più badge,
      ma ogni badge è associato a un solo osservatore.


  Entità di associazione:
    - pattern_migratori: (nome_scientifico_specie, codice_EUNIS_habitat, motivo_migrazione)
      PK: (nome_scientifico_specie, codice_EUNIS_habitat, motivo_migrazione)
      FK: nome_scientifico_specie (riferimento a Specie)
      FK: codice_EUNIS_habitat (riferimento a Habitat)
      Attributi:
        motivo_migrazione (es: nidificazione, svernamento, migrazione, stanziale)
        periodo_inizio (mese)
        periodo_fine (mese)

    - associazione_località_habitat (tra località_avvistamento e habitat)
      PK: (plus_code, codice_eunis)
      FK: plus_code (riferimento a località_avvistamento)
      FK: codice_eunis (riferimento a Habitat)
 */

  /* 
    Pattern codice tessera:
    prefisso fisso ABW
    Sigla città (2–3 lettere maiuscole)
    anno da cui è stato iscritto il socio (4 cifre)
    iniziale del nome (1 lettera maiuscola) e iniziale del cognome (1 lettera maiuscola)
    numero progressivo (4 cifre, con zeri iniziali)
    esempio: ABWMI2020AB0001
   
   Pattern codice avvistamento:
    codice tessera dell'osservatore (lunghezza 16)
    data dell'avvistamento (YYYYMMDD)
    numero progressivo (3 cifre, con zeri iniziali)
    esempio: ABWMI2020AB0001-20221012-001
    dove ABWMI2020AB0001 è il codice tessera dell'osservatore
    e 20221012-001 è la data dell'avvistamento (12 ottobre 2022) con il numero progressivo 001.
   */


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


CREATE TABLE socio (
  codice_tessera  VARCHAR2(16),
  nome            VARCHAR2(30) NOT NULL,
  cognome         VARCHAR2(30) NOT NULL,
  email           VARCHAR2(60) UNIQUE NOT NULL,
  telefono        VARCHAR2(15),
  data_nascita    DATE NOT NULL,
  data_iscrizione DATE DEFAULT sysdate NOT NULL,
  CONSTRAINT fm_cd_tessera CHECK ( REGEXP_LIKE ( codice_tessera,
                                                 '^ABW[A-Z]{2,3}[0-9]{4}[A-Z]{2}[0-9]{4}$' ) ),
  CONSTRAINT pk_socio PRIMARY KEY ( codice_tessera )
);

CREATE TABLE osservatore (
  codice_tessera VARCHAR2(16) NOT NULL,
  CONSTRAINT fk_osservatore_socio FOREIGN KEY ( codice_tessera )
    REFERENCES socio ( codice_tessera )
      ON DELETE CASCADE,
  CONSTRAINT pk_osservatore PRIMARY KEY ( codice_tessera )
);

CREATE TABLE revisore (
  codice_tessera    VARCHAR2(16) NOT NULL,
  data_attribuzione DATE DEFAULT sysdate NOT NULL,
  CONSTRAINT fk_revisore_socio FOREIGN KEY ( codice_tessera )
    REFERENCES socio ( codice_tessera )
      ON DELETE CASCADE,
  CONSTRAINT pk_revisore PRIMARY KEY ( codice_tessera )
);

CREATE TABLE avvistamento (
  codice_avvistamento        VARCHAR2(29) NOT NULL,
  data_avvistamento          DATE NOT NULL,
  ora_avvistamento           VARCHAR2(5) NOT NULL,
  valutazione                VARCHAR2(20) CHECK ( valutazione IN ( 'confermato',
                                                    'possibile',
                                                    'non confermato' ) ),
  data_revisione             DATE,
  codice_tessera_osservatore VARCHAR2(16) NOT NULL,
  codice_tessera_revisore    VARCHAR2(16),
  plus_code                  VARCHAR2(12) NOT NULL,
  CONSTRAINT fm_cd_avvistamento CHECK ( REGEXP_LIKE ( codice_avvistamento,
                                                      '^[A-Z0-9]{16}-[0-9]{12}-[0-9]{3}$' ) ),
  CONSTRAINT pk_avvistamento PRIMARY KEY ( codice_avvistamento ),
  CONSTRAINT fk_avvistamento_osservatore FOREIGN KEY ( codice_tessera_osservatore )
    REFERENCES osservatore ( codice_tessera )
      ON DELETE CASCADE,
  CONSTRAINT fk_avvistamento_revisore FOREIGN KEY ( codice_tessera_revisore )
    REFERENCES revisore ( codice_tessera )
      ON DELETE SET NULL,
  CONSTRAINT fk_avvistamento_localita FOREIGN KEY ( plus_code )
    REFERENCES localita_avvistamento ( plus_code )
      ON DELETE CASCADE
);

CREATE TABLE specie (
  nome_scientifico    VARCHAR2(40) NOT NULL,
  nome_comune         VARCHAR2(40) NOT NULL,
  stato_conservazione VARCHAR2(20) CHECK ( stato_conservazione IN ( 'LC',
                                                                    'NT',
                                                                    'VU',
                                                                    'EN',
                                                                    'CR' ) ) NOT NULL,
  famiglia            VARCHAR2(40) NOT NULL,
  url_verso           VARCHAR2(100),
  url_immagine        VARCHAR2(100),
  CONSTRAINT pk_specie PRIMARY KEY ( nome_scientifico )
);

CREATE TABLE regione (
  codice_iso   VARCHAR2(3) NOT NULL,
  nome_regione VARCHAR2(40) NOT NULL,
  paese        VARCHAR2(40) NOT NULL,
  CONSTRAINT pk_regione PRIMARY KEY ( codice_iso )
);

CREATE TABLE localita_avvistamento (
  plus_code          VARCHAR2(12) NOT NULL,
  nome               VARCHAR2(40) NOT NULL,
  area_protetta      NUMBER(1) CHECK ( area_protetta IN ( 0,
                                                     1 ) ),
  url_mappa          VARCHAR2(100),
  codice_iso_regione VARCHAR2(3) NOT NULL,
  codice_eunis       VARCHAR2(10) NOT NULL,
  CONSTRAINT pk_localita_avvistamento PRIMARY KEY ( plus_code ),
  CONSTRAINT fk_localita_regione FOREIGN KEY ( codice_iso_regione )
    REFERENCES regione ( codice_iso )
      ON DELETE CASCADE
);

CREATE TABLE habitat (
  codice_eunis    VARCHAR2(10) NOT NULL,
  nome_habitat    VARCHAR2(40) NOT NULL,
  url_descrizione VARCHAR2(100),
  CONSTRAINT pk_habitat PRIMARY KEY ( codice_eunis )
);

CREATE TABLE esemplare (
  codice_avvistamento     VARCHAR2(28) NOT NULL,
  numero_esemplare        NUMBER(3) NOT NULL,
  maturita                VARCHAR2(8) CHECK ( maturita IN ( 'adulto',
                                             'giovane',
                                             'pulcino' ) ),
  condizioni_salute       VARCHAR2(8) CHECK ( condizioni_salute IN ( 'sano',
                                                               'malato',
                                                               'ferito' ) ),
  sesso                   VARCHAR2(12) CHECK ( sesso IN ( 'maschio',
                                        'femmina',
                                        'sconosciuto' ) ),
  nome_scientifico_specie VARCHAR2(40) NOT NULL,
  CONSTRAINT pk_esemplare PRIMARY KEY ( codice_avvistamento,
                                        numero_esemplare ),
  CONSTRAINT fk_esemplare_avvistamento FOREIGN KEY ( codice_avvistamento )
    REFERENCES avvistamento ( codice_avvistamento )
      ON DELETE CASCADE,
  CONSTRAINT fk_esemplare_specie FOREIGN KEY ( nome_scientifico_specie )
    REFERENCES specie ( nome_scientifico )
      ON DELETE CASCADE
);

CREATE TABLE media (
  codice_avvistamento VARCHAR2(28) NOT NULL,
  titolo_media        VARCHAR2(40) NOT NULL,
  tipo_media          VARCHAR2(6) CHECK ( tipo_media IN ( 'foto',
                                                 'video',
                                                 'audio' ) ),
  url_media           VARCHAR2(100) NOT NULL,
  formato_media       VARCHAR2(4) CHECK ( formato_media IN ( 'jpg',
                                                       'png',
                                                       'mp4',
                                                       'mp3',
                                                       'wav' ) ),
  CONSTRAINT pk_media PRIMARY KEY ( codice_avvistamento,
                                    titolo_media ),
  CONSTRAINT fk_media_avvistamento FOREIGN KEY ( codice_avvistamento )
    REFERENCES avvistamento ( codice_avvistamento )
);

CREATE TABLE condizioni_ambientali (
  codice_avvistamento VARCHAR2(28) NOT NULL,
  meteo               VARCHAR2(10) CHECK ( meteo IN ( 'sole',
                                        'nuvoloso',
                                        'pioggia',
                                        'neve' ) ),
  temperatura         NUMBER(3,1),
  umidita             NUMBER(3,1),
  vento               VARCHAR2(10) CHECK ( vento IN ( 'veloce',
                                        'moderato',
                                        'debole',
                                        'assente' ) ),
  CONSTRAINT pk_condizioni_ambientali PRIMARY KEY ( codice_avvistamento ),
  CONSTRAINT fk_condizioni_avvistamento FOREIGN KEY ( codice_avvistamento )
    REFERENCES avvistamento ( codice_avvistamento )
      ON DELETE CASCADE
);

-- periodo è espresso in mesi
CREATE TABLE pattern_migratori (
  nome_scientifico_specie VARCHAR2(40) NOT NULL,
  codice_eunis_habitat    VARCHAR2(10) NOT NULL,
  motivo_migrazione       VARCHAR2(15) CHECK ( motivo_migrazione IN ( 'stanziale',
                                                                'nidificazione',
                                                                'svernamento',
                                                                'migrazione' ) ),
  periodo_inizio          NUMERIC(2) CHECK ( periodo_inizio BETWEEN 1 AND 12 ) NOT NULL,
  periodo_fine            NUMERIC(2) CHECK ( periodo_fine BETWEEN 1 AND 12 ) NOT NULL,
  CONSTRAINT pk_pattern_migratori PRIMARY KEY ( nome_scientifico_specie,
                                                codice_eunis_habitat,
                                                motivo_migrazione ),
  CONSTRAINT fk_pattern_migratori_specie FOREIGN KEY ( nome_scientifico_specie )
    REFERENCES specie ( nome_scientifico )
      ON DELETE CASCADE,
  CONSTRAINT fk_pattern_migratori_habitat FOREIGN KEY ( codice_eunis_habitat )
    REFERENCES habitat ( codice_eunis )
      ON DELETE CASCADE
);

CREATE TABLE badge (
  nome_badge            VARCHAR2(25) CHECK ( nome_badge IN ( 'occhio di Kakapo',
                                                  'occhio di Colibrì',
                                                  'custode della natura' ) ) NOT NULL,
  codice_tessera_socio  VARCHAR2(16) NOT NULL,
  data_assegnazione     DATE DEFAULT sysdate NOT NULL,
  criterio_assegnazione VARCHAR2(50) CHECK ( criterio_assegnazione IN ( 'primo avvistamento confermato',
                                                                        'decimo avvistamento confermato',
                                                                        'prima osservazione di una specie CR o EN' ) ) NOT NULL
                                                                        ,
  url_badge             VARCHAR2(100),
  CONSTRAINT pk_badge PRIMARY KEY ( nome_badge,
                                    codice_tessera_socio ),
  CONSTRAINT fk_badge_socio FOREIGN KEY ( codice_tessera_socio )
    REFERENCES socio ( codice_tessera )
      ON DELETE CASCADE
);

CREATE TABLE associazione_localita_habitat (
  plus_code    VARCHAR2(12) NOT NULL,
  codice_eunis VARCHAR2(10) NOT NULL,
  CONSTRAINT pk_associazione_localita_habitat PRIMARY KEY ( plus_code,
                                                            codice_eunis ),
  CONSTRAINT fk_associazione_localita FOREIGN KEY ( plus_code )
    REFERENCES localita_avvistamento ( plus_code )
      ON DELETE CASCADE,
  CONSTRAINT fk_associazione_habitat FOREIGN KEY ( codice_eunis )
    REFERENCES habitat ( codice_eunis )
      ON DELETE CASCADE
);

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
     AND stato = par_valutazione;

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


CREATE OR REPLACE TYPE tbe_maturita AS
  TABLE OF esemplare.maturita%TYPE;
CREATE OR REPLACE TYPE tbe_sesso AS
  TABLE OF esemplare.sesso%TYPE;
CREATE OR REPLACE TYPE tbe_condizioni_salute AS
  TABLE OF esemplare.condizioni_salute%TYPE;

/*  
  La seguente procedura automatizza l'inserimento degli avvistamenti, coinvolgendo oltre la tabella di
  avvistamento le tabelle osservatore (inserito se non esiste), esemplare (inserito),
  localita_avvistamento (inserito se non esiste), regione (inserito se non esiste) a seconda
  delle loro dipendenze.
  media e condizioni_ambientali essendo opzionali possono essere fornite in un secondo momento, con
  una operazione di inserimento manuale, non è necessario appesantire ulteriormente la procedura.
*/
CREATE OR REPLACE PROCEDURE add_avvistamento (
  p_data_avvistamento           IN avvistamento.data_avvistamento%TYPE,
  p_ora_avvistamento            IN avvistamento.ora_avvistamento%TYPE,
  p_codice_tessera_osservatore  IN avvistamento.codice_tessera_osservatore%TYPE,
  p_nome_osservatore            IN socio.nome%TYPE,
  p_cognome_osservatore         IN socio.cognome%TYPE,
  p_email_osservatore           IN socio.email%TYPE,
  p_telefono_osservatore        IN socio.telefono%TYPE,
  p_data_nascita_osservatore    IN socio.data_nascita%TYPE,
  p_data_iscrizione_osservatore IN socio.data_iscrizione%TYPE,
  p_plus_code                   IN avvistamento.plus_code%TYPE,
  p_nome_localita               IN localita_avvistamento.nome%TYPE,
  p_area_protetta               IN localita_avvistamento.area_protetta%TYPE,
  p_url_mappa                   IN localita_avvistamento.url_mappa%TYPE,
  p_codice_eunis                IN localita_avvistamento.codice_eunis%TYPE,
  p_codice_iso_regione          IN localita_avvistamento.codice_iso_regione%TYPE,
  p_nome_regione                IN regione.nome_regione%TYPE,
  p_paese                       IN regione.paese%TYPE,
  p_maturita                    IN tbe_maturita,
  p_condizioni_salute           IN tbe_condizioni_salute,
  p_sesso                       IN tbe_sesso,
  p_nome_scientifico_specie     IN esemplare.nome_scientifico_specie%TYPE
) AS
  var_codice_avvistamento  avvistamento.codice_avvistamento%TYPE;
  var_n_avvistamento_today NUMBER := 0;
BEGIN
  -- Inserimento del socio osservatore se non esiste
  INSERT INTO socio (
    codice_tessera,
    nome,
    cognome,
    email,
    telefono,
    data_nascita,
    data_iscrizione
  )
    SELECT p_codice_tessera_osservatore,
           p_nome_osservatore,
           p_cognome_osservatore,
           p_email_osservatore,
           p_telefono_osservatore,
           p_data_nascita_osservatore,
           p_data_iscrizione_osservatore
      FROM dual
     WHERE NOT EXISTS (
      SELECT 1
        FROM socio
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

  -- troviamo il numero di avvistamenti effettuati oggi
  SELECT COUNT(*)
    INTO var_n_avvistamento_today
    FROM avvistamento
   WHERE codice_tessera_osservatore = p_codice_tessera_osservatore
     AND trunc(data_avvistamento) = trunc(sysdate);

  -- generazione del codice avvistamento
  var_codice_avvistamento := p_codice_tessera_osservatore
                             || '-'
                             || to_char(
    p_data_avvistamento,
    'YYYYMMDD'
  )
                             || '-'
                             || to_char(
    var_n_avvistamento_today + 1,
    'FM000'
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

/*  Procedura per inserire una nuova specie (coinvolge 3 tabelle).
  La procedura verifica che il nome_scientifico non esista già nella tabella specie.
  Se esiste, viene sollevata un'eccezione. inoltre, si inserisce l'habitat (se non esiste già)
  
*/
CREATE OR REPLACE PROCEDURE insert_specie (
  p_nome_scientifico     IN specie.nome_scientifico%TYPE,
  p_nome_comune          IN specie.nome_comune%TYPE,
  p_stato_conservazione  IN specie.stato_conservazione%TYPE,
  p_famiglia             IN specie.famiglia%TYPE,
  p_url_verso            IN specie.url_verso%TYPE,
  p_url_immagine         IN specie.url_immagine%TYPE,
  p_pattern_migratorio   IN pattern_migratorio%TYPE,
  p_codice_eunis_habitat IN pattern_migratorio.codice_eunis_habitat%TYPE,
  p_motivo_migrazione    IN pattern_migratorio.motivo_migrazione%TYPE,
  p_periodo_inizio       IN pattern_migratorio.periodo_inizio%TYPE,
  p_periodo_fine         IN pattern_migratorio.periodo_fine%TYPE,
  p_habitat              IN habitat%TYPE,
  p_codice_eunis         IN habitat.codice_eunis%TYPE,
  p_nome_habitat         IN habitat.nome_habitat%TYPE,
  p_url_descrizione      IN habitat.url_descrizione%TYPE
) IS
  specie_exists NUMBER;
BEGIN
  -- Verifica che il nome_scientifico non esista già
  SELECT COUNT(*)
    INTO specie_exists
    FROM specie
   WHERE nome_scientifico = p_nome_scientifico;

  -- Inserimento della nuova specie
  IF specie_exists > 0 THEN
    raise_application_error(
      -20001,
      'La specie con il nome scientifico specificato esiste già.'
    );
  END IF;
  INSERT INTO specie (
    nome_scientifico,
    nome_comune,
    stato_conservazione,
    famiglia,
    url_verso,
    url_immagine
  ) VALUES ( p_nome_scientifico,
             p_nome_comune,
             p_stato_conservazione,
             p_famiglia,
             p_url_verso,
             p_url_immagine );
  
  -- Inserimento dell'habitat se non esiste
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

  -- Inserimento dei pattern migratori associati (se non esistono già)
  INSERT INTO pattern_migratori (
    nome_scientifico_specie,
    codice_eunis_habitat,
    motivo_migrazione,
    periodo_inizio,
    periodo_fine
  )
    SELECT p_nome_scientifico,
           p_codice_eunis_habitat,
           p_motivo_migrazione,
           p_periodo_inizio,
           p_periodo_fine
      FROM dual
     WHERE NOT EXISTS (
      SELECT 1
        FROM pattern_migratori
       WHERE ( nome_scientifico_specie = p_nome_scientifico
         AND codice_eunis_habitat = p_codice_eunis_habitat
         AND motivo_migrazione = p_motivo_migrazione )
    );

EXCEPTION
  WHEN OTHERS THEN
    raise_application_error(
      -20003,
      'Errore durante l''inserimento della specie o dei pattern migratori'
    );
END;