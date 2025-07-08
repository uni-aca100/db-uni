/*
  funzione per la generazione univoca del codice di tessera per un socio.
  Pattern codice tessera:
    prefisso fisso ABW
    Sigla città (2–3 lettere maiuscole)
    anno da cui è stato iscritto il socio (4 cifre)
    iniziale del nome (1 lettera maiuscola) e iniziale del cognome (1 lettera maiuscola)
    numero progressivo (4 cifre, con zeri iniziali)
    esempio: ABWMI2020AB0001
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