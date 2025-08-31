/*
  funzione per la generazione univoca del codice della tessera di un socio.
  Pattern codice tessera:
    ABW (fisso per Associazione Bird Watching)
    [A-Z]{2}: es. MI, RO ecc. (sigla sede iscrizione)
    [0-9]{4}: anno iscrizione es. 2020
    [A-Z]: iniziale nome es. M (Marco)
    [A-Z]: iniziale cognome es. A (Ambrosio)
    [0-9]{4}: n-esimo socio iscritto nell'anno corrente (4 cifre)
    esempio: ABWMI2020MA0001
*/
CREATE OR REPLACE FUNCTION genera_codice_tessera (
    p_nome        IN socio.nome%TYPE,
    p_cognome     IN socio.cognome%TYPE,
    p_sigla_citta IN VARCHAR2
) RETURN socio.codice_tessera%TYPE AS
    var_codice                  socio.codice_tessera%TYPE;
    var_count_year_subscription NUMBER;
    var_initial_name            VARCHAR2(1);
    var_initial_surname         VARCHAR2(1);
BEGIN
    var_initial_name := substr(
        upper(p_nome),
        1,
        1
    );
    var_initial_surname := substr(
        upper(p_cognome),
        1,
        1
    );
   -- contiamo il numero di soci iscritti nell'anno corrente
    SELECT COUNT(*)
      INTO var_count_year_subscription
      FROM socio
     WHERE trunc(
        data_iscrizione,
        'YYYY'
    ) = trunc(
        sysdate,
        'YYYY'
    );
  -- generiamo il codice di tessera
    var_codice := 'ABW'
                  || upper(p_sigla_citta)
                  || to_char(
        sysdate,
        'YYYY'
    )
                  || var_initial_name
                  || var_initial_surname
                  || to_char(
        var_count_year_subscription + 1,
        'FM0000'
    );

    RETURN var_codice;
END;
/