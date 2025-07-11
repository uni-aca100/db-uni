/*  Procedura per inserire un media associato a un avvistamento.
  La procedura verifica che l'avvistamento esista prima di procedere
  con l'inserimento del media. Se l'avvistamento non esiste, viene sollevata
  un'eccezione.
*/
CREATE OR REPLACE PROCEDURE insert_media (
  p_codice_tessera_osservatore IN media.codice_tessera_osservatore%TYPE,
  p_n_avvistamento             IN media.n_avvistamento%TYPE,
  p_titolo_media               IN media.titolo_media%TYPE,
  p_tipo_media                 IN media.tipo_media%TYPE,
  p_url_media                  IN media.url_media%TYPE,
  p_formato_media              IN media.formato_media%TYPE
) IS
  avvistamento_exists NUMBER;
BEGIN
  SELECT COUNT(*)
    INTO avvistamento_exists
    FROM avvistamento
   WHERE codice_tessera_osservatore = p_codice_tessera_osservatore
     AND n_avvistamento = p_n_avvistamento;

  IF avvistamento_exists = 0 THEN
    raise_application_error(
      -20002,
      'L''avvistamento specificato non esiste.'
    );
  END IF;
  INSERT INTO media (
    codice_tessera_osservatore,
    n_avvistamento,
    titolo_media,
    tipo_media,
    url_media,
    formato_media
  ) VALUES ( p_codice_tessera_osservatore,
             p_n_avvistamento,
             p_titolo_media,
             p_tipo_media,
             p_url_media,
             p_formato_media );

EXCEPTION
  WHEN OTHERS THEN
    raise_application_error(
      -20004,
      'Errore durante l''inserimento del media'
    );
END;
/