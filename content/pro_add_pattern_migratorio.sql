/*
  Questa procedura automatizza l'inserimento di pattern migratori e degli
  habitat ad essi associati per una data specie.
  La procedura gestisce l'inserimento di:
    - Pattern Migratori: Viene inserito un nuovo pattern migratorio
    associato a una specie e a un habitat specifico.
    - Habitat: Un nuovo habitat viene inserito e associato al pattern
    migratorio specificato, solo se non esiste già.
    - Specie: Una nuova specie viene inserita, solo se non è già presente.

  Vengono costruiti automaticamente i pattern migratori e gli habitat
  di destinazione associati alle diverse specie.

  Per le specie stanziali, il pattern migratorio deve coprire l'intero anno.
  Questo significa che il periodo_inizio deve essere 1 (gennaio)
  e il periodo_fine deve essere 12 (dicembre).
  Tale vincolo è gestito dal trigger trg_check_year_pattern_migratori_stanziali.

  Se il pattern migratorio esiste già (duplicato), viene sollevata specificamente
  un'eccezione.
*/
CREATE OR REPLACE PROCEDURE add_pattern_migratorio (
  p_nome_scientifico    IN specie.nome_scientifico%TYPE,
  p_nome_comune         IN specie.nome_comune%TYPE,
  p_stato_conservazione IN specie.stato_conservazione%TYPE,
  p_famiglia            IN specie.famiglia%TYPE,
  p_url_verso           IN specie.url_verso%TYPE,
  p_url_immagine        IN specie.url_immagine%TYPE,
  p_motivo_migrazione   IN pattern_migratori.motivo_migrazione%TYPE,
  p_periodo_inizio      IN pattern_migratori.periodo_inizio%TYPE,
  p_periodo_fine        IN pattern_migratori.periodo_fine%TYPE,
  p_codice_eunis        IN habitat.codice_eunis%TYPE,
  p_nome_habitat        IN habitat.nome_habitat%TYPE,
  p_url_descrizione     IN habitat.url_descrizione%TYPE
) IS
  specie_exists  NUMBER;
  pattern_exists NUMBER;
  duplicate_pattern_migratorio EXCEPTION;
BEGIN
  -- Se la specie non esiste, la inseriamo
  INSERT INTO specie (
    nome_scientifico,
    nome_comune,
    stato_conservazione,
    famiglia,
    url_verso,
    url_immagine
  )
    SELECT p_nome_scientifico,
           p_nome_comune,
           p_stato_conservazione,
           p_famiglia,
           p_url_verso,
           p_url_immagine
      FROM dual
     WHERE NOT EXISTS (
      SELECT 1
        FROM specie
       WHERE nome_scientifico = p_nome_scientifico
    );

  -- se l'habitat non esiste, lo inseriamo
  INSERT INTO habitat (
    codice_eunis,
    nome_habitat,
    url_descrizione
  )
    SELECT p_codice_eunis,
           p_nome_habitat,
           p_url_descrizione
      FROM dual
     WHERE NOT EXISTS (
      SELECT 1
        FROM habitat
       WHERE codice_eunis = p_codice_eunis
    );

  -- verifica che il pattern migratorio non esista già
  SELECT COUNT(*)
    INTO pattern_exists
    FROM pattern_migratori
   WHERE nome_scientifico_specie = p_nome_scientifico
     AND codice_eunis_habitat = p_codice_eunis
     AND motivo_migrazione = p_motivo_migrazione;

  IF pattern_exists > 0 THEN
    RAISE duplicate_pattern_migratorio;
  END IF;

  -- Inserimento dei pattern migratori associati
  INSERT INTO pattern_migratori (
    nome_scientifico_specie,
    codice_eunis_habitat,
    motivo_migrazione,
    periodo_inizio,
    periodo_fine
  ) VALUES ( p_nome_scientifico,
             p_codice_eunis,
             p_motivo_migrazione,
             p_periodo_inizio,
             p_periodo_fine );

  COMMIT;
EXCEPTION
  WHEN duplicate_pattern_migratorio THEN
    raise_application_error(
      -20002,
      'Esiste già un pattern migratorio per questa specie e habitat.'
    );
    ROLLBACK;
  WHEN OTHERS THEN
    raise_application_error(
      -20003,
      'Errore durante l''inserimento della specie o dei pattern migratori'
    );
    ROLLBACK;
END;
/