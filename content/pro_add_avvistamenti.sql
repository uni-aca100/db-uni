/*
  Questi tipi sono utilizzati per i campi che accettano
  più valori, come maturità, sesso e condizioni di salute degli esemplari.
*/
CREATE OR REPLACE TYPE tb_esp_maturita AS
    TABLE OF VARCHAR2(10);
/
CREATE OR REPLACE TYPE tb_esp_sesso AS
    TABLE OF VARCHAR2(12);
/
CREATE OR REPLACE TYPE tb_esp_condizioni_salute AS
    TABLE OF VARCHAR2(10);
/

/*  
  Procedura Automatica di Inserimento Avvistamenti Questa procedura automatizza
  l'inserimento degli avvistamenti, gestendo anche le tabelle correlate. Vengono coinvolte:
    - Avvistamento (inserito sempre)
    - Osservatore (inserito solo se non già esistente)
    - Esemplare (inserito sempre, con molteplici valori per maturità, sesso e condizioni di salute)
    - Località_avvistamento (inserita solo se non già esistente)
    - Regione (inserita solo se non già esistente).
  Il codice generato è quindi stampato a video.

  La procedura fallisce se l'osservatore non è un socio già iscritto.

  La procedura accetta i seguenti parametri:
    - p_data_e_ora: Data e ora dell'avvistamento
    - p_codice_tessera_osservatore: Codice della tessera del socio osservatore
    - p_plus_code: Plus code della località di avvistamento
    - p_nome_localita: Nome della località di avvistamento
    - p_area_protetta: Area protetta della località di avvistamento
    - p_url_mappa: URL della mappa della località di avvistamento
    - p_nome_regione: Nome della regione della località di avvistamento
    - p_paese: Paese della regione della località di avvistamento
    - p_maturita: Tabella con le maturità degli esemplari (può contenere più valori)
    - p_condizioni_salute: Tabella con le condizioni di salute degli esemplari (può contenere più valori)
    - p_sesso: Tabella con i sessi degli esemplari (può contenere più valori)
    - p_nome_scientifico_specie: Nome scientifico della specie degli esemplari

  Le informazioni relative a media, dispositivo di richiamo e condizioni_ambientali sono opzionali e
  possono essere aggiunte in un secondo momento tramite inserimento manuale,
  evitando così di appesantire ulteriormente questa procedura.
*/
CREATE OR REPLACE PROCEDURE add_avvistamento (
    p_data_e_ora                 IN avvistamento.data_e_ora%TYPE,
    p_codice_tessera_osservatore IN avvistamento.codice_tessera_osservatore%TYPE,
    p_plus_code                  IN avvistamento.plus_code%TYPE,
    p_nome_localita              IN localita_avvistamento.nome%TYPE,
    p_area_protetta              IN localita_avvistamento.area_protetta%TYPE,
    p_url_mappa                  IN localita_avvistamento.url_mappa%TYPE,
    p_nome_regione               IN regione.nome_regione%TYPE,
    p_paese                      IN regione.paese%TYPE,
    p_maturita                   IN tb_esp_maturita,
    p_condizioni_salute          IN tb_esp_condizioni_salute,
    p_sesso                      IN tb_esp_sesso,
    p_nome_scientifico_specie    IN esemplare.nome_scientifico_specie%TYPE
) AS
    var_n_avvistamenti NUMBER := 0;
    socio_exists       NUMBER := 0;
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
        nome_regione,
        paese
    )
        SELECT p_nome_regione,
               p_paese
          FROM dual
         WHERE NOT EXISTS (
            SELECT 1
              FROM regione
             WHERE nome_regione = p_nome_regione
               AND paese = p_paese
        );

  -- Inserimento della località di avvistamento se non esiste
    INSERT INTO localita_avvistamento (
        plus_code,
        nome,
        area_protetta,
        url_mappa,
        nome_regione,
        paese
    )
        SELECT p_plus_code,
               p_nome_localita,
               p_area_protetta,
               p_url_mappa,
               p_nome_regione,
               p_paese
          FROM dual
         WHERE NOT EXISTS (
            SELECT 1
              FROM localita_avvistamento
             WHERE plus_code = p_plus_code
        );

  -- Calcola il nuovo numero di avvistamento per l'osservatore
    SELECT nvl(
        max(n_avvistamento),
        0
    ) + 1
      INTO var_n_avvistamenti
      FROM avvistamento
     WHERE codice_tessera_osservatore = p_codice_tessera_osservatore;

  -- Inserimento dell'avvistamento
    INSERT INTO avvistamento (
        n_avvistamento,
        data_e_ora,
        codice_tessera_osservatore,
        plus_code
    ) VALUES ( var_n_avvistamenti,
               p_data_e_ora,
               p_codice_tessera_osservatore,
               p_plus_code );

  -- inserimento esemplari
    FOR i IN 1..p_maturita.count LOOP
        INSERT INTO esemplare (
            codice_tessera_osservatore,
            n_avvistamento,
            numero_esemplare,
            maturita,
            condizioni_salute,
            sesso,
            nome_scientifico_specie
        ) VALUES ( p_codice_tessera_osservatore,
                   var_n_avvistamenti,
                   i,
                   p_maturita(i),
                   p_condizioni_salute(i),
                   p_sesso(i),
                   p_nome_scientifico_specie );
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
/