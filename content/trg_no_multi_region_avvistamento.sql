/*
  Questo trigger implementa il vincolo di integrità dinamico:
  Non è consentito che lo stesso osservatore effettui avvistamenti
  in regioni diverse nello stesso giorno.
*/
CREATE OR REPLACE TRIGGER trg_no_multi_region_avvistamento
BEFORE INSERT OR UPDATE ON avvistamento
FOR EACH ROW
DECLARE
    var_count_regioni NUMBER;
    var_new_regione regione.nome_regione%TYPE;
    var_new_nazione regione.nazione%TYPE;
    deny_daily_multi_region EXCEPTION;
BEGIN
    -- trova la regione dell'avvistamento corrente
    SELECT r.nome_regione, r.nazione
    INTO var_new_regione, var_new_nazione
    FROM localita_avvistamento l
    JOIN regione r
        ON r.nome_regione = l.nome_regione AND r.nazione = l.nazione
    WHERE l.plus_code = :NEW.plus_code;

    -- verifica se l'osservatore ha già effettuato un avvistamento in una
    -- regione diversa nello stesso giorno
    SELECT COUNT(DISTINCT l.nome_regione)
    INTO var_count_regioni
    FROM avvistamento a
    JOIN localita_avvistamento l
        ON a.plus_code = l.plus_code
    JOIN regione r
        ON r.nome_regione = l.nome_regione and r.nazione = l.nazione
    WHERE trunc(a.data_e_ora) = trunc(:NEW.data_e_ora)
        AND a.codice_tessera_osservatore = :NEW.codice_tessera_osservatore
        AND a.n_avvistamento != :NEW.n_avvistamento
        AND (r.nome_regione != var_new_regione OR r.nazione != var_new_nazione);

    IF var_count_regioni > 0 THEN
        RAISE deny_daily_multi_region;
    END IF;
EXCEPTION
    WHEN no_data_found THEN
        RAISE_APPLICATION_ERROR(-20000, 'L''avvistamento non esiste o la località non è valida.');
    WHEN deny_daily_multi_region THEN
        RAISE_APPLICATION_ERROR(-20001, 'Non è consentito effettuare avvistamenti in regioni diverse nello stesso giorno.');
END;
/