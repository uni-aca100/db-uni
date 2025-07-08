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
      Un avvistamento può avere condizioni ambientali associate,
      ma non è obbligatorio.
      Ogni avvistamento può avere al massimo una condizione
      ambientale associata.

    - Avvistamento (1,N) [avviene_in] (1,1) località_avvistamento
      Un avvistamento può avvenire in una sola località_avvistamento,
      ma una località_avvistamento può essere associata a più avvistamenti.

    - località_avvistamento (1,N) [appartiene_a] (1,1) Regione
      Una località_avvistamento può appartenere a una sola regione,
      ma una regione può avere più località_avvistamento associate.

    - Specie (1,1) [possiede] (1,N) pattern_migratori
      Una specie può possedere più pattern migratori.
      Ogni pattern migratorio è associato a una sola specie.

    - Habitat (1,N) [è_associato_a] (1,N) pattern_migratori
      Un habitat può essere associato a più pattern migratori,
      ma un pattern migratorio è associato a un solo habitat.

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

-- DROP delle tabelle in ordine di dipendenza per evitare errori di vincoli
DROP TABLE associazione_localita_habitat CASCADE CONSTRAINTS;
DROP TABLE badge CASCADE CONSTRAINTS;
DROP TABLE pattern_migratori CASCADE CONSTRAINTS;
DROP TABLE condizioni_ambientali CASCADE CONSTRAINTS;
DROP TABLE media CASCADE CONSTRAINTS;
DROP TABLE esemplare CASCADE CONSTRAINTS;
DROP TABLE avvistamento CASCADE CONSTRAINTS;
DROP TABLE habitat CASCADE CONSTRAINTS;
DROP TABLE localita_avvistamento CASCADE CONSTRAINTS;
DROP TABLE regione CASCADE CONSTRAINTS;
DROP TABLE specie CASCADE CONSTRAINTS;
DROP TABLE revisore CASCADE CONSTRAINTS;
DROP TABLE osservatore CASCADE CONSTRAINTS;
DROP TABLE socio CASCADE CONSTRAINTS;

-- CREAZIONE TABELLE IN ORDINE DI DIPENDENZA

CREATE TABLE regione (
  codice_iso   VARCHAR2(3) NOT NULL,
  nome_regione VARCHAR2(40) NOT NULL,
  paese        VARCHAR2(40) NOT NULL,
  CONSTRAINT pk_regione PRIMARY KEY ( codice_iso )
);

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

CREATE TABLE habitat (
  codice_eunis    VARCHAR2(10) NOT NULL,
  nome_habitat    VARCHAR2(40) NOT NULL,
  url_descrizione VARCHAR2(100),
  CONSTRAINT pk_habitat PRIMARY KEY ( codice_eunis )
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

CREATE TABLE esemplare (
  codice_avvistamento     VARCHAR2(29) NOT NULL,
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
  codice_avvistamento VARCHAR2(29) NOT NULL,
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
  codice_avvistamento VARCHAR2(29) NOT NULL,
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

CREATE TABLE pattern_migratori (
  nome_scientifico_specie VARCHAR2(40) NOT NULL,
  codice_eunis_habitat    VARCHAR2(10) NOT NULL,
  motivo_migrazione       VARCHAR2(15) CHECK ( motivo_migrazione IN ( 'stanziale',
                                                                'nidificazione',
                                                                'svernamento',
                                                                'migrazione' ) ),
  periodo_inizio          NUMBER(2) CHECK ( periodo_inizio BETWEEN 1 AND 12 ) NOT NULL,
  periodo_fine            NUMBER(2) CHECK ( periodo_fine BETWEEN 1 AND 12 ) NOT NULL,
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