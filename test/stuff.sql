-- Ensure DBMS_OUTPUT is enabled for output to appear
   SET SERVEROUTPUT ON;

DECLARE
  v_maturita          tb_esp_maturita := tb_esp_maturita('adulto');
  v_condizioni_salute tb_esp_condizioni_salute := tb_esp_condizioni_salute('sano');
  v_sesso             tb_esp_sesso := tb_esp_sesso('maschio');
BEGIN
  add_avvistamento(
    p_data_avvistamento          => TO_DATE('2025-07-09',
                   'YYYY-MM-DD'),
    p_ora_avvistamento           => '08:30',
    p_codice_tessera_osservatore => 'ABWMI2020AB0001',
    p_plus_code                  => '8FVC9G8F+5W',
    p_nome_localita              => 'Parco Nord',
    p_area_protetta              => 1,
    p_url_mappa                  => 'https://maps.example.com/parco-nord',
    p_codice_eunis               => 'EUNIS123',
    p_codice_iso_regione         => 'ITC',
    p_nome_regione               => 'Lombardia',
    p_paese                      => 'Italia',
    p_maturita                   => v_maturita,
    p_condizioni_salute          => v_condizioni_salute,
    p_sesso                      => v_sesso,
    p_nome_scientifico_specie    => 'Falco peregrinus'
  );
END;
/