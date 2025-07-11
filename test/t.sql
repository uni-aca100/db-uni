-- add avvistamento

SELECT *
  FROM avvistamento
 WHERE codice_tessera_osservatore = 'ABWMI2010LR0001';

SELECT *
  FROM avvistamento
 WHERE codice_tessera_osservatore = 'ABWMI2010LR0001'
 ORDER BY n_avvistamento;

DECLARE
  v_maturita          tb_esp_maturita := tb_esp_maturita(
    'adulto',
    'giovane'
  );
  v_condizioni_salute tb_esp_condizioni_salute := tb_esp_condizioni_salute(
    'sano',
    'malato'
  );
  v_sesso             tb_esp_sesso := tb_esp_sesso(
    'maschio',
    'femmina'
  );
BEGIN
  add_avvistamento(
    p_data_e_ora                 => TO_DATE('2024-06-10 09:30',
                   'YYYY-MM-DD HH24:MI'),
    p_codice_tessera_osservatore => 'ABWMI2010LR0001',
    p_plus_code                  => '8FVC9G8F+5V',
    p_nome_localita              => 'Parco Nazionale del Gran Paradiso',
    p_area_protetta              => 1,
    p_url_mappa                  => 'https://cloud.it/maps/gran_paradiso',
    p_nome_regione               => 'Piemonte',
    p_paese                      => 'Italia',
    p_maturita                   => v_maturita,
    p_condizioni_salute          => v_condizioni_salute,
    p_sesso                      => v_sesso,
    p_nome_scientifico_specie    => 'Aquila chrysaetos'
  );
END;
/

SELECT *
  FROM avvistamento
 WHERE codice_tessera_osservatore = 'ABWMI2010LR0001';

SELECT *
  FROM avvistamento
 WHERE codice_tessera_osservatore = 'ABWMI2010LR0001'
 ORDER BY n_avvistamento;


 -- pattern migratorio

 -- Visualizza tutti i pattern migratori per la specie appena inserita
SELECT *
  FROM pattern_migratori
 WHERE nome_scientifico_specie = 'Testudo test';

-- Visualizza tutti gli habitat associati alla specie appena inserita
SELECT *
  FROM specie_vive_in_habitat
 WHERE nome_scientifico_specie = 'Testudo test';

-- Visualizza tutte le specie presenti nel database
SELECT *
  FROM specie
 ORDER BY nome_scientifico;

BEGIN
  add_pattern_migratorio(
    p_nome_scientifico    => 'Testudo test',
    p_nome_comune         => 'Testuggine di Test',
    p_stato_conservazione => 'LC',
    p_famiglia            => 'Testudinidae',
    p_url_verso           => 'https://cloud.it/versi/testudo.mp3',
    p_url_immagine        => 'https://cloud.it/img/testudo.jpg',
    p_motivo_migrazione   => 'nidificazione',
    p_periodo_inizio      => 5,
    p_periodo_fine        => 7,
    p_codice_eunis        => 'Z9.9',
    p_nome_habitat        => 'Habitat di test',
    p_url_descrizione     => 'https://cloud.it/habitat/test'
  );
  dbms_output.put_line('Pattern migratorio inserito con successo!');
EXCEPTION
  WHEN OTHERS THEN
    dbms_output.put_line('Errore: ' || sqlerrm);
END;
/

-- Visualizza tutti i pattern migratori per la specie appena inserita
SELECT *
  FROM pattern_migratori
 WHERE nome_scientifico_specie = 'Testudo test';

-- Visualizza tutti gli habitat associati alla specie appena inserita
SELECT *
  FROM specie_vive_in_habitat
 WHERE nome_scientifico_specie = 'Testudo test';

-- Visualizza tutte le specie presenti nel database
SELECT *
  FROM specie
 ORDER BY nome_scientifico;


 -- revisone

BEGIN
  revisione_avvistamento(
    p_codice_tessera_osservatore => 'ABWMI2010LR0001',
    p_n_avvistamento             => 1,
    p_codice_tessera_revisore    => 'ABWFI2010SE0003',
    p_valutazione                => 'confermato',
    p_data_revisione             => TO_DATE('2024-06-15',
                         'YYYY-MM-DD')
  );
  dbms_output.put_line('Revisione avvistamento eseguita con successo!');
EXCEPTION
  WHEN OTHERS THEN
    dbms_output.put_line('Errore: ' || sqlerrm);
END;
/

-- assegnazione badge

-- Test: assegnazione di un badge a un socio
BEGIN
  assegnazione_badge(
    p_codice_tessera_socio => 'ABWMI2010LR0001',
    p_nome_badge           => 'occhio di Colibrì',
    p_data_assegnazione    => TO_DATE('2024-06-20',
                     'YYYY-MM-DD'),
    p_badge_url            => 'https://cloud.it/badge/ABWMI2010LR0001'
  );
  dbms_output.put_line('Badge assegnato con successo!');
EXCEPTION
  WHEN OTHERS THEN
    dbms_output.put_line('Errore: ' || sqlerrm);
END;
/

-- Verifica: badge assegnati al socio
SELECT *
  FROM badge
 WHERE codice_tessera_socio = 'ABWMI2010LR0001';

-- Verifica: badge assegnati per tipo
SELECT nome_badge,
       COUNT(*) AS totale
  FROM badge
 GROUP BY nome_badge;

-- Verifica: badge assegnati con data
SELECT nome_badge,
       codice_tessera_socio,
       data_assegnazione
  FROM badge
 ORDER BY data_assegnazione DESC;

 -- iscrivi socio


-- Verifica: elenco dei soci appena iscritti
SELECT *
  FROM socio
 WHERE email = 'carlo.mattei@example.com';

-- Verifica: elenco di tutti i soci ordinati per data di iscrizione
SELECT codice_tessera,
       nome,
       cognome,
       data_iscrizione
  FROM socio
 ORDER BY data_iscrizione DESC;

BEGIN
  iscrivi_nuovo_socio(
    p_nome         => 'Carlo',
    p_cognome      => 'Mattei',
    p_email        => 'carlo.mattei@example.com',
    p_data_nascita => TO_DATE('1999-05-15',
                      'YYYY-MM-DD'),
    p_telefono     => '1234567890',
    p_sigla_citta  => 'NA'
  );
  dbms_output.put_line('Nuovo socio iscritto!');
EXCEPTION
  WHEN OTHERS THEN
    dbms_output.put_line('Errore: ' || sqlerrm);
END;
/

-- Verifica: elenco dei soci appena iscritti
SELECT *
  FROM socio
 WHERE email = 'carlo.mattei@example.com';

-- Verifica: elenco di tutti i soci ordinati per data di iscrizione
SELECT codice_tessera,
       nome,
       cognome,
       data_iscrizione
  FROM socio
 ORDER BY data_iscrizione DESC;

 -- test trigger trg_check_data
 -- Caso positivo: avvistamento dopo la data di iscrizione
BEGIN
  INSERT INTO avvistamento (
    codice_tessera_osservatore,
    n_avvistamento,
    data_e_ora,
    valutazione,
    plus_code
  ) VALUES ( 'ABWMI2010LR0001',
             99,
             TO_DATE('2024-07-01 10','YYYY-MM-DD HH24'),
             'confermato',
             '8FVC9G8F+5V' );
  dbms_output.put_line('Avvistamento inserito correttamente.');
EXCEPTION
  WHEN OTHERS THEN
    dbms_output.put_line('Errore: ' || sqlerrm);
END;
/

-- Caso negativo: avvistamento prima della data di iscrizione
BEGIN
  INSERT INTO avvistamento (
    codice_tessera_osservatore,
    n_avvistamento,
    data_e_ora,
    valutazione,
    plus_code
  ) VALUES ( 'ABWMI2010LR0001',
             100,
             TO_DATE('2010-01-01 10','YYYY-MM-DD HH24'),
             'confermato',
             '8FVC9G8F+5V' );
  dbms_output.put_line('Avvistamento inserito (ERRORE: non dovrebbe essere possibile).');
EXCEPTION
  WHEN OTHERS THEN
    dbms_output.put_line('Trigger attivato correttamente: ' || sqlerrm);
END;
/

-- trg_check_località 
-- Caso positivo: località valida per la specie e periodo
BEGIN
  INSERT INTO avvistamento (
    codice_tessera_osservatore,
    n_avvistamento,
    data_e_ora,
    valutazione,
    plus_code
  ) VALUES ( 'ABWMI2010LR0001',
             207,
             TO_DATE('2024-05-15 10','YYYY-MM-DD HH24'),
             'confermato',
             '8FVC9G7F+2W' );
  INSERT INTO esemplare (
    codice_tessera_osservatore,
    n_avvistamento,
    numero_esemplare,
    maturita,
    condizioni_salute,
    sesso,
    nome_scientifico_specie
  ) VALUES ( 'ABWMI2010LR0001',
             207,
             1,
             'adulto',
             'sano',
             'maschio',
             'Passer italiae' );
  dbms_output.put_line('Avvistamento ed esemplare inseriti correttamente (caso positivo).');
EXCEPTION
  WHEN OTHERS THEN
    dbms_output.put_line('Errore (caso positivo): ' || sqlerrm);
END;
/

-- Caso negativo: località NON valida per la specie e periodo
BEGIN
  INSERT INTO avvistamento (
    codice_tessera_osservatore,
    n_avvistamento,
    data_e_ora,
    valutazione,
    plus_code
  ) VALUES ( 'ABWMI2010LR0001',
             208,
             TO_DATE('2024-01-15 10','YYYY-MM-DD HH24'),
             'confermato',
             '8FVC9G8F+5V' );
  INSERT INTO esemplare (
    codice_tessera_osservatore,
    n_avvistamento,
    numero_esemplare,
    maturita,
    condizioni_salute,
    sesso,
    nome_scientifico_specie
  ) VALUES ( 'ABWMI2010LR0001',
             208,
             1,
             'adulto',
             'sano',
             'maschio',
             'Aquila chrysaetos' );
  dbms_output.put_line('Avvistamento ed esemplare inseriti (ERRORE: non dovrebbe essere possibile).');
EXCEPTION
  WHEN OTHERS THEN
    dbms_output.put_line('Trigger attivato correttamente (caso negativo): ' || sqlerrm);
END;
/