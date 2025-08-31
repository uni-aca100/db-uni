/*
  La funzione recupera lo stato corrente di un socio
  in base al codice tessera fornito.
*/
CREATE OR REPLACE FUNCTION socio_stato_corrente (
    p_codice_tessera IN stato.codice_tessera_socio%TYPE
) RETURN stato.tipo%TYPE AS
    var_stato stato.tipo%TYPE;
BEGIN
    SELECT tipo
    INTO var_stato
    FROM stato
    WHERE codice_tessera_socio = p_codice_tessera
    AND data_inizio = (SELECT MAX(data_inizio)
                       FROM stato
                       WHERE codice_tessera_socio = p_codice_tessera);
    RETURN var_stato;
EXCEPTION
    WHEN NO_DATA_FOUND THEN
        RETURN NULL;
    WHEN OTHERS THEN
        RAISE;
END;
/