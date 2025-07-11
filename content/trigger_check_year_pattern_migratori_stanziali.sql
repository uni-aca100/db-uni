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
/