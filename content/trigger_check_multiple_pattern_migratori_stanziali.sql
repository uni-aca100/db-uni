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
   WHERE codice_eunis_habitat = :new.codice_eunis_habitat
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