USE novi_projekt;
-- --------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
-- 1. Nova rezervacija na istu sobu koja već rezervirana
DELIMITER //

CREATE TRIGGER trg_dupla_rezervacija_sobe
BEFORE INSERT ON rezervacija
FOR EACH ROW
BEGIN
    DECLARE brojac_rez  INT;
    
    SELECT COUNT(*) INTO brojac_rez
    FROM rezervacija
    WHERE soba_id = NEW.soba_id
      AND status != 'OTKAZANA'
      AND NEW.pocetak_datum < kraj_datum 					      
      AND NEW.kraj_datum > pocetak_datum;
      
    IF brojac_rez > 0 THEN
        SIGNAL SQLSTATE '45000'
        SET MESSAGE_TEXT = 'Greška: Soba je već rezervirana u odabranom terminu!';
    END IF;
END //

DELIMITER ;
-- ##########
SELECT * FROM rezervacija WHERE status NOT IN ('ZAVRSENA', 'OTKAZANA');

INSERT INTO rezervacija (gost_nositelj_id, zaposlenik_id, soba_id, promocija_id, datum_rezervacije, pocetak_datum, kraj_datum, broj_osoba, status, napomena) 
VALUES  				(1, 1, 7, NULL, NOW(), '2026-04-12', '2026-04-13', 1, 'POTVRDJENA', 'Test');
-- ##########
INSERT INTO promocija (id, naziv, kod_kupona, popust_postotak, datum_pocetka, datum_zavrsetka, aktivna) VALUES 
(999, 'Testna Neaktivna Promocija', 'FAIL100', 50.00, '2020-01-01', '2030-12-31', 0);

INSERT INTO rezervacija 
(gost_nositelj_id, zaposlenik_id, soba_id, promocija_id, datum_rezervacije, pocetak_datum, kraj_datum, broj_osoba, status) VALUES 
(1, 1, 1, 999, NOW(), '2026-08-01', '2026-08-05', 2, 'POTVRDJENA');

INSERT INTO rezervacija 
(gost_nositelj_id, zaposlenik_id, soba_id, promocija_id, datum_rezervacije, pocetak_datum, kraj_datum, broj_osoba, status)
VALUES 
(1, 1, 1, 1, '2026-07-15 12:00:00', '2026-08-01', '2026-08-05', 2, 'POTVRDJENA');
-- --------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
-- 2. Provjera valjanosti unosa rezervacije i promocije - ne/aktivna, vremeski period
DELIMITER //

CREATE TRIGGER trg_unos_provjera_valjanosti_promocije
BEFORE INSERT ON rezervacija
FOR EACH ROW
BEGIN
    DECLARE v_aktivna BOOLEAN;
    DECLARE v_datum_pocetka DATE;
    DECLARE v_datum_zavrsetka DATE;

    IF NEW.promocija_id IS NOT NULL THEN
        
        SELECT aktivna, datum_pocetka, datum_zavrsetka 
        INTO v_aktivna, v_datum_pocetka, v_datum_zavrsetka
        FROM promocija 
        WHERE id = NEW.promocija_id;

        IF v_aktivna = 0 THEN
            SIGNAL SQLSTATE '45000'
            SET MESSAGE_TEXT = 'Greška: Odabrana promocija nije aktivna!';
        END IF;

        IF DATE(NEW.datum_rezervacije) < v_datum_pocetka OR DATE(NEW.datum_rezervacije) > v_datum_zavrsetka THEN
            SIGNAL SQLSTATE '45000'
            SET MESSAGE_TEXT = 'Greška: Promocija je nevažeća na odabrani datum rezervacije!';
        END IF;
        
    END IF;
END //

DELIMITER ;
-- #########
INSERT INTO promocija (id, naziv, kod_kupona, popust_postotak, datum_pocetka, datum_zavrsetka, aktivna) VALUES 
(999, 'Testna Neaktivna Promocija', 'FAIL100', 50.00, '2020-01-01', '2030-12-31', 0);

SELECT 
    p.id AS promocija_id, 
    p.naziv AS naziv_promocije,
    p.datum_pocetka AS pocetak, 
    p.datum_zavrsetka AS kraj,
    GROUP_CONCAT(r.id) AS popis_rezervacija_id
FROM 
    promocija p
LEFT JOIN 
    rezervacija r ON p.id = r.promocija_id
GROUP BY 
    p.id, p.naziv;

INSERT INTO rezervacija 
(gost_nositelj_id, zaposlenik_id, soba_id, promocija_id, datum_rezervacije, pocetak_datum, kraj_datum, broj_osoba, status) VALUES 
(1, 1, 1, 999, NOW(), '2026-08-01', '2026-08-05', 2, 'POTVRDJENA');

INSERT INTO rezervacija 
(gost_nositelj_id, zaposlenik_id, soba_id, promocija_id, datum_rezervacije, pocetak_datum, kraj_datum, broj_osoba, status)
VALUES 
(1, 1, 1, 1, '2026-07-15 12:00:00', '2026-08-01', '2026-08-05', 2, 'POTVRDJENA');
-- ---------------------------------------------------------------------------------------------------------------------------------- ----------------------------------------------------------------------------------------------------------------------------------
-- 3. Provjera valjanosti ažuriranja promocije za rezervaciju - ne/aktivna, vremeski period
DELIMITER // 

CREATE TRIGGER trg_ažuriranje_provjera_valjanosti_promocije
BEFORE UPDATE ON rezervacija
FOR EACH ROW
BEGIN
    DECLARE v_aktivna BOOLEAN;
    DECLARE v_datum_pocetka DATE;
    DECLARE v_datum_zavrsetka DATE;

    IF NEW.promocija_id IS NOT NULL AND (OLD.promocija_id IS NULL OR NEW.promocija_id != OLD.promocija_id) THEN
        
        SELECT aktivna, datum_pocetka, datum_zavrsetka 
        INTO v_aktivna, v_datum_pocetka, v_datum_zavrsetka
        FROM promocija 
        WHERE id = NEW.promocija_id;

        IF v_aktivna = 0 THEN
            SIGNAL SQLSTATE '45000'
            SET MESSAGE_TEXT = 'Greška: Odabrana promocija je neaktivna!';
        END IF;

        IF DATE(NEW.datum_rezervacije) < v_datum_pocetka OR DATE(NEW.datum_rezervacije) > v_datum_zavrsetka THEN
            SIGNAL SQLSTATE '45000'
            SET MESSAGE_TEXT = 'Greška: Odabrana promocija je nevazeća za datum ove rezervacije!';
        END IF;
        
    END IF;
END //

DELIMITER ;

SELECT 

    r.id AS ID_Rezervacije,
    r.datum_rezervacije AS Datum_Kreiranja_Rez,
    r.pocetak_datum AS Boravak_Od,
    r.kraj_datum AS Boravak_Do,
    
    p.id AS ID_Promocije,
    p.naziv AS Naziv_Promocije,
    p.datum_pocetka AS Promo_Vrijedi_OD,        
    p.datum_zavrsetka AS Promo_Vrijedi_DO  

FROM 
    rezervacija r
JOIN 
    promocija p ON r.promocija_id = p.id
ORDER BY 
    r.id;

UPDATE rezervacija 
SET promocija_id = 1 
WHERE id = 9;

UPDATE rezervacija 
SET promocija_id = 999 
WHERE id = 9;
-- ---------------------------------------------------------------------------------------------------------------------------------- ----------------------------------------------------------------------------------------------------------------------------------
