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

/*PROCEDURE-Ivona*/

/******************Prebacivanje statusa sobe na “SLOBODNA” ako je trenutno u statusu "CISCENJE"***************/
DELIMITER $$
CREATE PROCEDURE sp_ociscena_soba(IN p_soba_id INT)
BEGIN
    /* Ažuriranje statusa sobe samo ako je trenutno u statusu čišćenja */
    UPDATE soba
    SET status = 'SLOBODNA'
    WHERE id = p_soba_id
      AND status = 'CISCENJE';
END$$
DELIMITER ;
CALL sp_ociscena_soba(101);

/******************Dodavanje gosta na rezervaciju (pojednostavljeno)******************/
DELIMITER $$
CREATE PROCEDURE sp_dodaj_gosta_na_rezervaciju(
    IN p_rezervacija_id INT,
    IN p_gost_id INT
)
BEGIN
    /* Provjera da gost već nije na rezervaciji */
    IF NOT EXISTS (
        SELECT 1 FROM rezervacija_gost
        WHERE rezervacija_id = p_rezervacija_id
          AND gost_id = p_gost_id
    ) THEN
        /* Dodavanje gosta u rezervaciju */
        INSERT INTO rezervacija_gost(rezervacija_id, gost_id)
        VALUES(p_rezervacija_id, p_gost_id);
    END IF;

    /* Povećanje broja osoba u rezervaciji */
    UPDATE rezervacija
    SET broj_osoba = broj_osoba + 1
    WHERE id = p_rezervacija_id;
END$$
DELIMITER ;

-- CALL koji radi sa postojećim insertima iz tvog koda
CALL sp_dodaj_gosta_na_rezervaciju(1, 1);  -- rezervacija_id = 1, gost_id = 1


/*****************Primjena promocije na rezervaciju i dodavanje stavke popusta (pojednostavljeno)*********************/
DELIMITER $$
CREATE PROCEDURE sp_primijeni_promociju(
    IN p_rezervacija_id INT,   
    IN p_promocija_id INT      
)
BEGIN
    DECLARE v_popust DECIMAL(5,2);
    DECLARE v_racun_id INT;

    /* Dohvaćanje postotka popusta iz promocije ako je aktivna i u trenutnom datumu */
    SELECT popust_postotak
    INTO v_popust
    FROM promocija
    WHERE id = p_promocija_id
      AND aktivna = 1
      AND CURDATE() BETWEEN datum_pocetka AND datum_zavrsetka
    LIMIT 1;

    IF v_popust IS NULL THEN
        SIGNAL SQLSTATE '45000'
        SET MESSAGE_TEXT = 'Promocija nije aktivna ili ne postoji';
    END IF;

    /* Veži promociju na rezervaciju */
    UPDATE rezervacija
    SET promocija_id = p_promocija_id
    WHERE id = p_rezervacija_id;

    /* Dohvaćanje otvorenog računa za rezervaciju */
    SELECT id
    INTO v_racun_id
    FROM racun
    WHERE rezervacija_id = p_rezervacija_id
      AND status_racuna = 'OTVOREN'
    LIMIT 1;

    /* Ako postoji otvoreni račun, dodaj stavku popusta */
    IF v_racun_id IS NOT NULL THEN
        INSERT INTO stavka_racuna(
            racun_id,
            tip_stavke,
            opis,
            kolicina,
            cijena_jedinicna,
            iznos_ukupno
        )
        VALUES (
            v_racun_id,
            'OSTALO',
            CONCAT('Popust - promocija ', p_promocija_id),
            1,
            -v_popust,
            -v_popust
        );
    END IF;
END$$
DELIMITER ;

-- CALL koji radi sa postojećim insertima
CALL sp_primijeni_promociju(1, 1);  -- rezervacija_id = 1, promocija_id = 1


-- Procedura Alma
DROP PROCEDURE IF EXISTS dohvati_slobodne_sobe;
DELIMITER //

CREATE PROCEDURE dohvati_slobodne_sobe(IN p_broj_osoba INT, IN p_datum_dolaska DATE, IN p_datum_odlaska DATE)
BEGIN
    SELECT broj, kapacitet_osoba, naziv AS tip_sobe
    FROM soba
    LEFT JOIN tip_sobe ON soba.tip_sobe_id = tip_sobe.id
    WHERE provjeri_dostupnost_sobe(soba.id, p_datum_dolaska, p_datum_odlaska) = 1
    AND kapacitet_osoba >= p_broj_osoba;
END //

DELIMITER ;

CALL dohvati_slobodne_sobe(3, '2026-08-01', '2026-08-03');