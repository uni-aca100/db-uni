/*
  Questa procedura gestisce la registrazione di un nuovo socio.
  Automaticamente, viene generato un codice tessera univoco che viene poi
  utilizzato per inserire il socio nella tabella Socio.
  Il codice generato è quindi stampato a video.
  Affinché la procedura vada a buon fine, è necessario che il socio sia maggiorenne.

  parametri:
    p_nome: nome del socio
    p_cognome: cognome del socio
    p_email: email del socio
    p_data_nascita: data di nascita del socio
    p_telefono: telefono del socio (opzionale)
    p_sigla_citta: sigla sede iscrizione (es. MI, RO)
*/
CREATE OR REPLACE PROCEDURE iscrivi_nuovo_socio (
    p_nome         IN socio.nome%TYPE,
    p_cognome      IN socio.cognome%TYPE,
    p_email        IN socio.email%TYPE,
    p_data_nascita IN socio.data_nascita%TYPE,
    p_telefono     IN socio.telefono%TYPE DEFAULT NULL,
    p_sigla_citta  IN VARCHAR2
) AS
    var_codice_tessera  socio.codice_tessera%TYPE;
    var_data_iscrizione socio.data_iscrizione%TYPE := sysdate;
    var_age             NUMBER;
    not_older_than_18 EXCEPTION;
BEGIN

  -- Calcolo dell'età del socio, per verificare che il socio sia maggiorenne
    var_age := trunc(months_between(
        var_data_iscrizione,
        p_data_nascita
    ) / 12);
    IF var_age < 18 THEN
        RAISE not_older_than_18;
    END IF;

  -- Generazione del codice di tessera
    var_codice_tessera := genera_codice_tessera(
        p_nome,
        p_cognome,
        p_sigla_citta
    );

  -- Inserimento del nuovo socio
    INSERT INTO socio VALUES ( var_codice_tessera,
                               p_nome,
                               p_cognome,
                               p_email,
                               p_telefono,
                               p_data_nascita,
                               var_data_iscrizione );
    dbms_output.put_line('Nuovo socio iscritto con codice tessera: ' || var_codice_tessera);

    -- stato iniziale del socio come 'attivo' (la data è di default)
    INSERT INTO stato (codice_tessera_socio, tipo)
    VALUES (var_codice_tessera, 'attivo');
    COMMIT;
EXCEPTION
    WHEN not_older_than_18 THEN
        ROLLBACK;
        raise_application_error(
            -20030,
            'Il socio deve essere maggiorenne (almeno 18 anni)'
        );
    WHEN OTHERS THEN
        ROLLBACK;
        raise_application_error(
            -20031,
            'Errore durante l''iscrizione del nuovo socio'
        );
END;
/