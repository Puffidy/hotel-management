USE novi_projekt;

-- ------------------------------------------------------------------------------------------------------------------------------------------------------------------
-- 1. Otkazivanje rezervacije
DELIMITER //

CREATE PROCEDURE otkazi_rezervaciju(IN p_rezervacija_id INT)
BEGIN
    DECLARE v_trenutni_status VARCHAR(20);

    SELECT status INTO v_trenutni_status
    FROM rezervacija
    WHERE id = p_rezervacija_id;

    IF v_trenutni_status = 'POTVRDJENA' THEN
        
        UPDATE rezervacija 
        SET status = 'OTKAZANA' 
        WHERE id = p_rezervacija_id;
        
        SELECT CONCAT('Rezervacija ', p_rezervacija_id, ' je otkazana.') AS Msg;
        
    ELSE
        SELECT CONCAT('Rezervacija ', p_rezervacija_id, ' se ne može otkazati jer je u statusu: ', IFNULL(v_trenutni_status, 'NEPOSTOJI')) AS Msg;
        
    END IF;

END //

DELIMITER ;

CALL otkazi_rezervaciju(40);

SELECT * FROM rezervacija WHERE id = 40; 

CALL otkazi_rezervaciju(1);


-- ------------------------------------------------------------------------------------------------------------------------------------------------------------------
-- 2. Brisanje podataka iz loga kojima je prošlo više od 90 dana
DELIMITER //

CREATE PROCEDURE ocisti_stare_log_rez(
    IN p_starije_od_dana INT,
    OUT p_obrisano_redaka INT
)
BEGIN
    DECLARE v_granicni_datum DATETIME;

    SET v_granicni_datum = NOW() - INTERVAL p_starije_od_dana DAY;

    SELECT COUNT(*) INTO p_obrisano_redaka
    FROM log_rezervacije
    WHERE vrijeme_promjene < v_granicni_datum;

    SELECT 
        id AS 'ID Log',
        rezervacija_id AS 'ID Rez',
        stari_status,
        novi_status,
        korisnik_db,
        vrijeme_promjene AS 'Stari datum'
    FROM log_rezervacije
    WHERE vrijeme_promjene < v_granicni_datum;

    DELETE FROM log_rezervacije 
    WHERE vrijeme_promjene < v_granicni_datum;

END //

DELIMITER ;

-- UNOS DUMMY PODATAKA - PREBACITI U GLAVNI INSERT PRIJE ZAVRŠNOG PROIZVODA
INSERT INTO log_rezervacije (rezervacija_id, stari_status, novi_status, vrijeme_promjene, korisnik_db) VALUES 
(1, 'NOVA', 'POTVRDJENA', '2023-01-15 10:00:00', 'stari_admin'),
(2, 'POTVRDJENA', 'OTKAZANA', '2023-05-20 14:30:00', 'stari_admin'),
(3, 'U_TIJEKU', 'ZAVRSENA', '2023-08-01 09:00:00', 'stari_admin');

-- ISTO PREBACITI U GLAVNI DDL
SET SQL_SAFE_UPDATES = 0;

SELECT * FROM log_rezervacije ORDER BY vrijeme_promjene ASC;

SET @broj_obrisanih = 0;

CALL ocisti_stare_log_rez(90, @broj_obrisanih);

SELECT @broj_obrisanih AS 'Ukupno trajno obrisanih zapisa';

