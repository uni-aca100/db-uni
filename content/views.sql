--  DBMS: Oracle 19c 
/*
  Questa vista mostra le specie che vivono in un habitat
  specifico nei diversi periodi dell'anno, includendo
  il motivo della loro presenza
  (ad esempio, se stanziali, migratorie, ecc.).
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
    JOIN pattern_migratori p
  ON s.nome_scientifico = p.nome_scientifico_specie
    JOIN habitat h
  ON p.codice_eunis_habitat = h.codice_eunis;