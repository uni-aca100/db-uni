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
/