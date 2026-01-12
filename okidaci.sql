-- 1. Okidač za novu rezervacija na istu sobu koja već rezervirana + upit za prikaz  - - E.B.
DROP TRIGGER  trg_dupla_rezervacija_sobe;

DELIMITER //

CREATE TRIGGER  trg_dupla_rezervacija_sobe
BEFORE INSERT ON rezervacija
FOR EACH ROW
BEGIN
    DECLARE brojac_rez  INT;
    
    SELECT COUNT(*) INTO brojac_rez
    FROM rezervacija
    WHERE soba_id =NEW.soba_id
      AND status != 'OTKAZANA'									
      AND NEW.pocetak_datum < kraj_datum 					      
      AND NEW.kraj_datum > pocetak_datum;
      
    IF brojac_rez > 0 THEN
        SIGNAL SQLSTATE '45000'
        SET MESSAGE_TEXT = 'Greška: Soba je već rezervirana u odabranom terminu!';
    END IF;
END //

DELIMITER ;

-- 1. Upit
SELECT 
    r.id AS ID_Rezervacije,
    s.broj AS Broj_Sobe,
    CONCAT(g.ime, ' ', g.prezime) AS Gost,
	CONCAT(DATE_FORMAT(r.pocetak_datum, '%d.%m.'), '-', DATE_FORMAT(r.kraj_datum, '%d.%m.%Y')) AS Termin,
	r.status
FROM rezervacija r
JOIN soba s ON r.soba_id = s.id
JOIN gost g ON r.gost_nositelj_id = g.id
WHERE r.status IN ('POTVRDJENA', 'U_TIJEKU');


INSERT INTO rezervacija 
(gost_nositelj_id, zaposlenik_id, soba_id, promocija_id, datum_rezervacije, pocetak_datum, kraj_datum, broj_osoba, status, napomena) 
VALUES 
(1, 1, 16, NULL, NOW(), '2026-12-19', '2026-12-22', 1, 'POTVRDJENA', 'Test test');

-- ----------------------------------------------------------------------------------------------------------------------------------
-- 2. Promocija se smije unijeti u rezervaciju samo ako je aktivna i vremenski važeća + upit za prikaz - - E.B.
DROP TRIGGER trg_unos_provjera_valjanosti_promocije;
DELIMITER //

CREATE TRIGGER trg_unos_provjera_valjanosti_promocije
BEFORE INSERT ON rezervacija
FOR EACH ROW
BEGIN
    DECLARE v_aktivna INT;
    
    DECLARE v_promo_vrijedi_od DATE;
    DECLARE v_promo_vrijedi_do DATE;
    
    DECLARE v_rez_dolazak DATE;
    DECLARE v_rez_odlazak DATE;

    IF NEW.promocija_id IS NOT NULL THEN
        
        SELECT aktivna, datum_pocetka, datum_zavrsetka 
        INTO v_aktivna, v_promo_vrijedi_od, v_promo_vrijedi_do
        FROM promocija 
        WHERE id = NEW.promocija_id;

        SET v_rez_dolazak = NEW.pocetak_datum;
        SET v_rez_odlazak = NEW.kraj_datum;

        IF v_aktivna = 0 THEN
            SIGNAL SQLSTATE '45000'
            SET MESSAGE_TEXT = 'Greška: Odabrana promocija je neaktivna!';
        END IF;

        IF v_rez_dolazak < v_promo_vrijedi_od THEN
            SIGNAL SQLSTATE '45000'
            SET MESSAGE_TEXT = 'Greška: Rezervacija počinje prije nego što sama promocija vrijedi!';
        END IF;

        IF v_rez_odlazak > v_promo_vrijedi_do THEN
            SIGNAL SQLSTATE '45000'
            SET MESSAGE_TEXT = 'Greška: Rezervacija završava nakon što je promocija istekla!';
        END IF;
        
    END IF;
END //

DELIMITER ;

INSERT INTO promocija(id, naziv, kod_kupona, popust_postotak, datum_pocetka, datum_zavrsetka,aktivna) VALUES
(999, 'NEAKTIVNA', 'TESTNA', 10.00, '2025-12-01', '2026-02-28',0); 

-- 2. Upit
SELECT 
    p.id AS ID_Promo,
    p.naziv AS Naziv_Promocije,
    DATE_FORMAT(p.datum_pocetka, '%d.%m.%Y') AS Vrijedi_Od,
    DATE_FORMAT(p.datum_zavrsetka, '%d.%m.%Y') AS Vrijedi_Do,
    p.aktivna AS Aktivna,
    
    IF(p.aktivna = 1, 'Da', 'Ne') AS Aktivna,
    
    COUNT(r.id) AS Ukupno_Iskoristeno,
    
    GROUP_CONCAT(r.id) AS ID_Rezervacija_Lista
FROM 
    promocija p
LEFT JOIN 
    rezervacija r ON p.id = r.promocija_id
GROUP BY 
    p.id, p.naziv, p.datum_pocetka, p.datum_zavrsetka, p.aktivna
ORDER BY 
    p.id;

INSERT INTO rezervacija 
(gost_nositelj_id, zaposlenik_id, soba_id, promocija_id, datum_rezervacije, pocetak_datum, kraj_datum, broj_osoba, status, napomena) 
VALUES 
(1, 1, 7, 999, NOW(), '2026-01-20', '2026-01-22', 2, 'POTVRDJENA', 'Test neaktivna proba');

INSERT INTO rezervacija 
(gost_nositelj_id, zaposlenik_id, soba_id, promocija_id, datum_rezervacije, pocetak_datum, kraj_datum, broj_osoba, status, napomena) 
VALUES 
(1, 1, 7, 1, NOW(), '2026-02-22', '2026-03-01', 2, 'POTVRDJENA', 'Test after');

INSERT INTO rezervacija 
(gost_nositelj_id, zaposlenik_id, soba_id, promocija_id, datum_rezervacije, pocetak_datum, kraj_datum, broj_osoba, status, napomena) 
VALUES 
(1, 1, 7, 3, NOW(), '2026-02-22', '2026-03-05', 2, 'POTVRDJENA', 'Test before');

-- ----------------------------------------------------------------------------------------------------------------------------------
-- 3. Promocija se smije ažurirati u postojećoj rezervaciji samo ako je aktivna i vremenski važeća + upit - - E.B.

drop trigger trg_ažuriranje_rezervacije_provjera_valjanosti_promocije;

DELIMITER //

CREATE TRIGGER  trg_ažuriranje_rezervacije_provjera_valjanosti_promocije
BEFORE UPDATE ON rezervacija
FOR EACH ROW
BEGIN
    DECLARE v_aktivna INT;
    
    DECLARE v_promo_vrijedi_od DATE;
    DECLARE v_promo_vrijedi_do DATE;

    DECLARE v_rez_dolazak DATE;
    DECLARE v_rez_odlazak DATE;

    IF NEW.promocija_id IS NOT NULL THEN
        
        SELECT aktivna, datum_pocetka, datum_zavrsetka 
        INTO v_aktivna, v_promo_vrijedi_od, v_promo_vrijedi_do
        FROM promocija 
        WHERE id=NEW.promocija_id;

        SET v_rez_dolazak=NEW.pocetak_datum;
        SET v_rez_odlazak=NEW.kraj_datum;


        IF v_aktivna = 0 THEN
            SIGNAL SQLSTATE '45000'
            SET MESSAGE_TEXT = 'Greška: Odabrana promocija je neaktivna!';
        END IF;


        IF v_rez_dolazak < v_promo_vrijedi_od THEN
            SIGNAL SQLSTATE '45000'
            SET MESSAGE_TEXT = 'Greška: Rezervacija počinje prije nego što sama promocija počinje vrijediti!';
        END IF;

        IF v_rez_odlazak > v_promo_vrijedi_do THEN
            SIGNAL SQLSTATE '45000'
            SET MESSAGE_TEXT = 'Greška: Rezervacija završava nakon što je promocija istekla!';
        END IF;
        
    END IF;
END //

DELIMITER ;

-- 3. Upit
SELECT 
    r.id AS ID_Rez,
    CONCAT(g.ime, ' ', g.prezime) AS Nositelj,

    DATE_FORMAT(r.pocetak_datum, '%d.%m.%Y') AS Boravak_Od,
    DATE_FORMAT(r.kraj_datum, '%d.%m.%Y') AS Boravak_Do,
    
    IFNULL(p.naziv, 'Nema promocije') AS Trenutna_Promo
    
FROM 
    rezervacija r
JOIN 
    gost g ON r.gost_nositelj_id=g.id
LEFT JOIN 
    promocija p ON r.promocija_id=p.id
WHERE 
    r.status IN ('POTVRDJENA', 'U_TIJEKU')
ORDER BY 
    r.id;


UPDATE rezervacija 
SET promocija_id =999 
WHERE id = 16;

UPDATE rezervacija 
SET promocija_id = 2 
WHERE id =25;


UPDATE rezervacija 
SET promocija_id = 4 
WHERE id =38;

-- ----------------------------------------------------------------------------------------------------------------------------------
-- 4. Check in vrijeme striktno od 14:00h pa nadalje kod prijave gosta tj. ažuriranja relacije rezervacija - - E.B.
 drop trigger trg_provjera_checkin_time;
DELIMITER //

CREATE TRIGGER trg_provjera_checkin_time
BEFORE UPDATE ON rezervacija
FOR EACH ROW
BEGIN
    IF NEW.vrijeme_check_in IS NOT NULL AND OLD.vrijeme_check_in IS NULL THEN
        
        IF HOUR(NEW.vrijeme_check_in) <= 14 THEN
            SIGNAL SQLSTATE '45000'
            SET MESSAGE_TEXT = 'Greška: Check-in nije dozvoljen prije 14:00 sati!';
        END IF;
        
    END IF;
END //

DELIMITER ;

INSERT INTO rezervacija 
(gost_nositelj_id, zaposlenik_id, soba_id, promocija_id, datum_rezervacije, pocetak_datum, kraj_datum, vrijeme_check_in, vrijeme_check_out, broj_osoba, status, napomena) VALUES 
(5, 1, 48, NULL, '2025-12-20 10:00:00', '2026-01-11', '2026-01-15', '2026-01-11 15:30:00', NULL, 2, 'U_TIJEKU', 'Dummy gost 1 - Već u sobi'),
(6, 2, 49, NULL, '2025-12-25 11:00:00', '2026-01-12', '2026-01-16', '2026-01-12 14:15:00', NULL, 2, 'U_TIJEKU', 'Dummy gost 2 - Upravo stigli');

-- 4. Upit
SELECT 
    r.id AS ID_Rez,
    CONCAT(g.ime, ' ', g.prezime) AS Gost,
    DATE_FORMAT(pocetak_datum, '%d.%m.%Y') AS Dolazak,
    
    IFNULL(
        DATE_FORMAT(vrijeme_check_in, '%H:%i'), 
        'Čeka se dolazak'
    ) AS Vrijeme_prijave,
    status
FROM rezervacija r
JOIN gost g ON r.gost_nositelj_id = g.id
WHERE status IN ('POTVRDJENA', 'U_TIJEKU')
ORDER BY r.id
LIMIT  10;

UPDATE rezervacija 
SET vrijeme_check_in= '2026-07-19 13:59:59', 
    status = 'U_TIJEKU'
WHERE id = 18;

UPDATE rezervacija 
SET vrijeme_check_in = '2026-07-19 14:00:01', 
    status = 'U_TIJEKU'
WHERE id = 20;
-- ----------------------------------------------------------------------------------------------------------------------------------
