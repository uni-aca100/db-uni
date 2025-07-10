/*
  Funzione per generare un codice avvistamento univoco.
  Pattern codice avvistamento:
    [A-Z0-9]{15} codice tessera dell'osservatore
    -
    [0-9]{8} data dell'avvistamento (YYYYMMDD)
    -
    [0-9]{3} n-esimo avvistamento effettuato dall'osservatore nella stessa data
    esempio: ABWMI2020AB0001-20221012-001
    dove ABWMI2020AB0001 è il codice tessera dell'osservatore
    e 20221012-001 è la data dell'avvistamento (12 ottobre 2022) con il numero di avvistamenti 001.
*/
CREATE OR REPLACE FUNCTION genera_codice_avvistamento (
  p_codice_tessera_osservatore IN avvistamento.codice_tessera_osservatore%TYPE,
  p_data_ora                   IN avvistamento.data_e_ora%TYPE
) RETURN avvistamento.codice_avvistamento%TYPE AS
  var_count_avvistamento_today NUMBER := 0;
  var_codice                   avvistamento.codice_avvistamento%TYPE;
BEGIN
  -- troviamo il numero di avvistamenti effettuati oggi
  SELECT COUNT(*)
    INTO var_count_avvistamento_today
    FROM avvistamento
   WHERE codice_tessera_osservatore = p_codice_tessera_osservatore
     AND trunc(data_e_ora) = trunc(p_data_ora);

  -- generazione del codice avvistamento
  var_codice := p_codice_tessera_osservatore
                || '-'
                || to_char(
    p_data_ora,
    'YYYYMMDD'
  )
                || '-'
                || to_char(
    var_count_avvistamento_today + 1,
    'FM000'
  );

  RETURN var_codice;
END;
/

/*
  funzione per la generazione univoca del codice di tessera per un socio.
  Pattern codice tessera:
    ABW (fisso)
    [A-Z]{2}: es. MI, RO ecc. (sigla città)
    [0-9]{4}: anno di iscrizione es. 2020
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