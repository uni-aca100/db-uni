-- Ensure DBMS_OUTPUT is enabled for output to appear
   SET SERVEROUTPUT ON;

DECLARE
  v_maturita          tb_esp_maturita := tb_esp_maturita('adulto');
  v_condizioni_salute tb_esp_condizioni_salute := tb_esp_condizioni_salute('sano');
  v_sesso             tb_esp_sesso := tb_esp_sesso('maschio');
BEGIN
  add_avvistamento(
    p_data_e_ora                 => TO_DATE('2025-07-09 10',
                   'YYYY-MM-DD HH24'),
    p_codice_tessera_osservatore => 'ABWMI2020AB0001',
    p_plus_code                  => '8FVC9G8F+5W',
    p_nome_localita              => 'Parco Nord',
    p_area_protetta              => 1,
    p_url_mappa                  => 'https://maps.example.com/parco-nord',
    p_nome_regione               => 'Lombardia',
    p_paese                      => 'Italia',
    p_maturita                   => v_maturita,
    p_condizioni_salute          => v_condizioni_salute,
    p_sesso                      => v_sesso,
    p_nome_scientifico_specie    => 'Falco peregrinus'
  );
END;
/

DECLARE BEGIN
  -- Esempio di utilizzo della procedura iscrivi_nuovo_socio
  iscrivi_nuovo_socio(
    p_nome         => 'Carlo',
    p_cognome      => 'Mattei',
    p_email        => 'carlo.mattei@example.com',
    p_data_nascita => TO_DATE('1999-05-15',
                      'YYYY-MM-DD'),
    p_telefono     => '1234567890',
    p_sigla_citta  => 'NA'
  );
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