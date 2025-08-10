--  DBMS: Oracle 19c 
/*
Questa vista mostra le specie che vivono
in un habitat specifico nei diversi periodi dell'anno, includendo
il motivo della loro presenza (ad esempio, se stanziali, migratorie, ecc.).
*/
CREATE OR REPLACE VIEW specie_vive_in_habitat AS
  SELECT s.nome_scientifico AS nome_scientifico_specie,
          s.nome_comune AS nome_comune_specie,
          h.nome_habitat,
          h.codice_eunis,
          h.url_descrizione AS url_habitat,
          p.motivo_migrazione AS motivo,
          p.periodo_inizio,
          p.periodo_fine
  FROM specie s
  JOIN pattern_migratorio p
    ON s.nome_scientifico = p.nome_scientifico_specie
  JOIN habitat h
    ON p.codice_eunis_habitat = h.codice_eunis;

-- view per proteggere i dati sensibili dei soci
CREATE OR REPLACE VIEW socio_pubblico AS
  SELECT codice_tessera,
          nome,
          cognome
    FROM socio;

-- view per visualizzare la distribuzione degli avvistamenti per specie
CREATE OR REPLACE VIEW distribuzione_avvistamenti_per_specie AS
  SELECT
    s.nome_scientifico AS nome_scientifico_specie,
    s.nome_comune AS nome_comune_specie,
    r.paese,
    r.nome_regione AS regione,
    COUNT(e.numero_esemplare) AS n_esemplari
  FROM avvistamento a
  JOIN esemplare e ON a.n_avvistamento = e.n_avvistamento
    AND e.codice_tessera_osservatore = a.codice_tessera_osservatore
  JOIN specie s ON e.nome_scientifico_specie = s.nome_scientifico
  JOIN localita_avvistamento la ON a.plus_code = la.plus_code
  JOIN regione r ON la.nome_regione = r.nome_regione
    AND r.paese = la.paese
  GROUP BY s.nome_scientifico, s.nome_comune, r.paese, r.nome_regione;