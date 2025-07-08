/*  Procedura per inserire un media associato a un avvistamento.
  La procedura verifica che il codice_avvistamento esista prima di procedere
  con l'inserimento del media. Se il codice_avvistamento non esiste, viene sollevata
  un'eccezione.
*/
CREATE OR REPLACE PROCEDURE insert_media (
  p_codice_avvistamento IN media.codice_avvistamento%TYPE,
  p_titolo_media        IN media.titolo_media%TYPE,
  p_tipo_media          IN media.tipo_media%TYPE,
  p_url_media           IN media.url_media%TYPE,
  p_formato_media       IN media.formato_media%TYPE
) IS
  media_exists NUMBER;
BEGIN
  SELECT 1
    INTO media_exists
    FROM avvistamento
   WHERE codice_avvistamento = p_codice_avvistamento;

  INSERT INTO media (
    codice_avvistamento,
    titolo_media,
    tipo_media,
    url_media,
    formato_media
  ) VALUES ( p_codice_avvistamento,
             p_titolo_media,
             p_tipo_media,
             p_url_media,
             p_formato_media );

EXCEPTION
  WHEN no_data_found THEN
    raise_application_error(
      -20002,
      'Il codice avvistamento specificato non esiste.'
    );
  WHEN OTHERS THEN
    raise_application_error(
      -20004,
      'Errore durante l''inserimento del media'
    );
END;