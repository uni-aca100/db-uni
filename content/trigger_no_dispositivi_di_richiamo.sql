/*
  Questo trigger impedisce l'aggiunta di dispositivi di richiamo
  agli avvistamenti effettuati in aree protette.

Tale restrizione è dovuta a diversi fattori:
    L'uso di richiami artificiali è solitamente vietato nelle aree protette.
    Molte associazioni di ornitologia o conservazione hanno codici etici
    che sconsigliano o limitano fortemente l'uso di tali dispositivi.
*/

CREATE OR REPLACE TRIGGER trg_no_dispositivi_di_richiamo BEFORE
    INSERT OR UPDATE ON dispositivo_richiamo
    FOR EACH ROW
DECLARE
    var_area_protetta NUMBER;
    deny_dispositivo_richiamo EXCEPTION;
BEGIN
   -- verifica se la località dell'avvistamento è in un'area protetta
    SELECT l.area_protetta
      INTO var_area_protetta
      FROM avvistamento a
      JOIN localita_avvistamento l
    ON a.plus_code = l.plus_code
     WHERE a.codice_tessera_osservatore = :new.codice_tessera_osservatore
       AND a.n_avvistamento = :new.n_avvistamento;

    IF var_area_protetta = 1 THEN
        RAISE deny_dispositivo_richiamo;
    END IF;
EXCEPTION
    WHEN no_data_found THEN
        raise_application_error(
            -20028,
            'L''avvistamento non esiste.'
        );
    WHEN deny_dispositivo_richiamo THEN
        raise_application_error(
            -20029,
            'Non è possibile utilizzare dispositivi di richiamo in aree protette.'
        );
END;
/