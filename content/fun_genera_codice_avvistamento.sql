/*
  Funzione per generare un codice avvistamento univoco.
  Pattern codice avvistamento:
    codice tessera dell'osservatore (lunghezza 16)
    data dell'avvistamento (YYYYMMDD)
    numero progressivo (3 cifre, con zeri iniziali)
    esempio: ABWMI2020AB0001-20221012-001
    dove ABWMI2020AB0001 è il codice tessera dell'osservatore
    e 20221012-001 è la data dell'avvistamento (12 ottobre 2022) con il numero progressivo 001.
*/
CREATE OR REPLACE FUNCTION genera_codice_avvistamento (
  p_codice_tessera_osservatore IN avvistamento.codice_tessera_osservatore%TYPE,
  p_data_avvistamento          IN avvistamento.data_avvistamento%TYPE
) RETURN avvistamento.codice_avvistamento%TYPE AS
  var_count_avvistamento_today NUMBER := 0;
  var_codice                   avvistamento.codice_avvistamento%TYPE;
BEGIN
  -- troviamo il numero di avvistamenti effettuati oggi
  SELECT COUNT(*)
    INTO var_count_avvistamento_today
    FROM avvistamento
   WHERE codice_tessera_osservatore = p_codice_tessera_osservatore
     AND trunc(data_avvistamento) = trunc(p_data_avvistamento);

  -- generazione del codice avvistamento
  var_codice := p_codice_tessera_osservatore
                || '-'
                || to_char(
    p_data_avvistamento,
    'YYYYMMDD'
  )
                || '-'
                || to_char(
    var_count_avvistamento_today + 1,
    'FM000'
  );

  RETURN var_codice;
END;