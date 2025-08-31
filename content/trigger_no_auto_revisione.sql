/*
  Trigger per impedire che un revisore validi i propri avvistamenti.
  Un revisore non può validare i propri avvistamenti.
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
/