/*
  Questa procedura è usata per assegnare i badge ai soci.
  L'assegnazione avviene in base a specifici requisiti che i soci devono soddisfare.
  Se questi requisiti non vengono soddisfatti, la procedura solleva un'eccezione dedicata.

  La procedura accetta i seguenti parametri:
    - p_codice_tessera_socio: il codice della tessera del socio a cui assegnare il badge (solo se esistente).
    - p_nome_badge: il nome del badge da assegnare.
    - p_data_assegnazione: la data in cui il badge viene assegnato (default è la data corrente).
    - p_badge_url: l'URL del badge.

  Per l'assegnazione dei badge, la procedura considera le tabelle dei badge e del revisore,
  oltre a quelle degli avvistamenti e delle specie per la verifica dei requisiti.
  I requisiti per ogni badge:
    Badge "Occhio di Colibrì": Può essere assegnato solo se il socio ha effettuato almeno 10 avvistamenti confermati.
    Badge "Occhio di Kakapo": Può essere assegnato solo se il socio ha effettuato almeno un avvistamento confermato.
    Badge "Custode della Natura": Assegnabile dopo almeno un avvistamento confermato di una specie in stato di conservazione Criticamente Minacciata (CR) o In Pericolo (EN).
*/
CREATE OR REPLACE PROCEDURE assegnazione_badge (
  p_codice_tessera_socio IN socio.codice_tessera%TYPE,
  p_nome_badge           IN badge.nome_badge%TYPE,
  p_data_assegnazione    IN badge.data_assegnazione%TYPE DEFAULT sysdate,
  p_badge_url            IN badge.url_badge%TYPE
) IS
  var_avvistamenti_confermati NUMBER := 0;
  var_exists_cr_en            NUMBER := 0;
  var_socio_exists            NUMBER := 0;
  requirement_not_met_custode EXCEPTION;
  requirement_not_met_colibri EXCEPTION;
  requirement_not_met_kakapo EXCEPTION;
  socio_not_found EXCEPTION;
BEGIN
  -- Verifica se il socio esiste
  SELECT COUNT(*)
    INTO var_socio_exists
    FROM socio
   WHERE codice_tessera = p_codice_tessera_socio;

  IF var_socio_exists = 0 THEN
    RAISE socio_not_found;
  END IF;

  -- Verifica se i requisiti per il badge da assegnare sono soddisfatti 
  IF p_nome_badge = 'custode della natura' THEN
    -- Verifica se è stata effettuata almeno un'osservazione di una specie in stato CR o EN
    SELECT COUNT(*)
      INTO var_exists_cr_en
      FROM avvistamento a
     WHERE a.codice_tessera_osservatore = p_codice_tessera_socio
       AND a.valutazione = 'confermato'
       AND EXISTS (
      SELECT 1
        FROM esemplare e
       WHERE e.codice_tessera_osservatore = a.codice_tessera_osservatore
         AND e.n_avvistamento = a.n_avvistamento
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
    SELECT COUNT(*)
      INTO var_avvistamenti_confermati
      FROM avvistamento
     WHERE codice_tessera_osservatore = p_codice_tessera_socio
       AND valutazione = 'confermato';

    IF (
      p_nome_badge = 'occhio di Colibrì'
      AND var_avvistamenti_confermati < 10
    ) THEN
      RAISE requirement_not_met_colibri;
    END IF;
    IF (
      p_nome_badge = 'occhio di Kakapo'
      AND var_avvistamenti_confermati < 1
    ) THEN
      RAISE requirement_not_met_kakapo;
    END IF;
  END IF;

  -- Inserimento del badge se i requisiti sono soddisfatti
  INSERT INTO badge (
    codice_tessera_socio,
    nome_badge,
    data_assegnazione,
    url_badge
  ) VALUES ( p_codice_tessera_socio,
             p_nome_badge,
             p_data_assegnazione,
             p_badge_url );
  COMMIT;
EXCEPTION
  WHEN socio_not_found THEN
    raise_application_error(
      -20020,
      'Il socio con il codice tessera specificato non esiste.'
    );
    ROLLBACK;
  WHEN requirement_not_met_custode THEN
    raise_application_error(
      -20022,
      'Il badge "Custode della natura" può essere assegnato solo dopo la prima osservazione di una specie in uno stato di conservazione Criticamente Minacciata (CR) o in Pericolo (EN).'
    );
    ROLLBACK;
  WHEN requirement_not_met_colibri THEN
    raise_application_error(
      -20023,
      'Il badge "Occhio di Colibrì" può essere assegnato solo dopo aver effettuato almeno 10 avvistamenti confermati.'
    );
    ROLLBACK;
  WHEN requirement_not_met_kakapo THEN
    raise_application_error(
      -20024,
      'Il badge "Occhio di Kakapo" può essere assegnato solo dopo il primo avvistamento confermato.'
    );
    ROLLBACK;
END;