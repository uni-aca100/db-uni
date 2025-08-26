
/*
  La procedura consente a un socio di aggiungere un media associato
  a un avvistamento già esistente (altrimenti fallisce).
  I media possono essere di tipo foto, video o audio.
  Tuttavia, se l’osservatore ha effettuato già almeno 3 avvistamenti
  della stessa specie nella stessa località negli ultimi 5 giorni, sarà possibile
  aggiungere al massimo un solo media di tipo video e uno di tipo audio.
  Non sono previsti limiti per le foto.

  Vengono coinvolte le tabelle:
    - Media
    - Avvistamento (per la verifica dell'esistenza)
    - Esemplare (per la verifica della specie)
*/
create or replace procedure add_media (
    p_codice_tessera_osservatore IN avvistamento.codice_tessera_osservatore%TYPE,
    p_n_avvistamento             IN avvistamento.n_avvistamento%TYPE,
    p_titolo_media               IN media.titolo_media%TYPE,
    p_tipo                       IN media.tipo%TYPE,
    p_url_media                  IN media.url_media%TYPE,
    p_formato                    IN media.formato%TYPE
)
AS
  var_avvistamento avvistamento%ROWTYPE;
  var_specie esemplare.nome_scientifico_specie%TYPE;
  var_count_avvistamenti_specie NUMBER := 0;
  var_count_p_tipo NUMBER := 0;
  var_count_audio NUMBER := 0;
  media_type_limit_reached EXCEPTION;
BEGIN
  -- Verifica se l'avvistamento esiste, se esiste lo carica in var_avvistamento
  select *
  into var_avvistamento
  from avvistamento
  where codice_tessera_osservatore = p_codice_tessera_osservatore
    and n_avvistamento = p_n_avvistamento;

  -- tutti gli esemplari sono della stessa specie in un avvistamento
  -- otteniamo la specie dell'avvistamento
  select max(e.nome_scientifico_specie) into var_specie
  from avvistamento a join esemplare e on a.n_avvistamento = e.n_avvistamento
    and a.codice_tessera_osservatore = e.codice_tessera_osservatore
  where a.codice_tessera_osservatore = p_codice_tessera_osservatore
    and a.n_avvistamento = p_n_avvistamento;

  -- Controlla il numero di avvistamenti della stessa specie nella stessa
  -- località negli ultimi 5 giorni
  select count(*) into var_count_avvistamenti_specie
  from avvistamento a
  join esemplare e on a.n_avvistamento = e.n_avvistamento
    and a.codice_tessera_osservatore = e.codice_tessera_osservatore
    -- vogliamo contare solo gli avvistamenti di una specie non il numero di esemplari
    -- quindi prendiamo solo il primo esemplare di ogni avvistamento
    and e.numero_esemplare = 1
  where a.codice_tessera_osservatore = p_codice_tessera_osservatore
    and a.data_e_ora >= sysdate - 5
    and a.plus_code = var_avvistamento.plus_code
    and e.nome_scientifico_specie = var_specie;

  -- se ci sono già 3 avvistamenti e il media non è una foto
  -- allora verifichiamo che sia possibile inserire il media
  -- (al massimo un video e un audio) altrimenti solleviamo un'eccezione
  IF var_count_avvistamenti_specie >= 3 and p_tipo != 'foto' THEN
    select count(*) into var_count_p_tipo
    from media
    where codice_tessera_osservatore = p_codice_tessera_osservatore
      and n_avvistamento = p_n_avvistamento
      and tipo = p_tipo;

    if var_count_p_tipo > 0 then
      raise media_type_limit_reached;
    end if;
  end if;

  INSERT INTO media
  VALUES (
    p_codice_tessera_osservatore,
    p_titolo_media,
    p_tipo,
    p_url_media,
    p_formato,
    p_n_avvistamento
  );
  COMMIT;

EXCEPTION
    WHEN NO_DATA_FOUND THEN
        RAISE_APPLICATION_ERROR(-20041, 'Avvistamento non trovato per il codice tessera e numero avvistamento forniti.');
        ROLLBACK;
    WHEN media_type_limit_reached THEN
        RAISE_APPLICATION_ERROR(-20042, 'Limite per il tipo di media specificato è stato raggiunto.');
        ROLLBACK;
END;
