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
-- 5. Automatski unos svih novih rezervacija u "log_rezervacija" - - E.B.

DELIMITER //
CREATE TRIGGER trg_unos_log_rezervacija
AFTER INSERT ON rezervacija
FOR EACH ROW
BEGIN
    INSERT INTO log_rezervacije (rezervacija_id, stari_status, novi_status, korisnik_db)
    VALUES (NEW.id, NULL, NEW.status, USER());
END //
DELIMITER ;

INSERT INTO rezervacija 
(gost_nositelj_id, zaposlenik_id, soba_id, promocija_id, datum_rezervacije, pocetak_datum, kraj_datum, broj_osoba, status, napomena) 
VALUES 
(45, 1, 15, NULL, NOW(), '2026-11-01', '2026-11-05', 1, 'POTVRDJENA', 'Log test');

UPDATE rezervacija 
SET kraj_datum = '2026-01-12' 
WHERE id = 1;

-- 5. Upit
SELECT 
    l.rezervacija_id AS 'ID Rez',
    l.id AS 'ID Log',
    CONCAT(g.ime, ' ', g.prezime) AS 'Nositelj Rezervacije',
    
    DATE_FORMAT(l.vrijeme_promjene, '%d.%m.%Y %H:%i:%s') AS 'Vrijeme Promjene',
    
    CONCAT(
        IFNULL(l.stari_status, 'NOVA'), 
        '-->', 
        l.novi_status
    ) AS 'Tijek Promjene Statusa',
    
    IF(l.novi_status = 'OTKAZANA', 'Otkazana', 
        IF(l.novi_status = 'U_TIJEKU', 'U tijeku', 
            CONCAT(DATEDIFF(r.kraj_datum, r.pocetak_datum), ' dana')
        )
    ) AS 'Trajanje Boravka',
    
   l.korisnik_db AS 'Izvršio Korisnik'

FROM 
    log_rezervacije l
JOIN 
    rezervacija r ON l.rezervacija_id = r.id
JOIN 
    gost g ON r.gost_nositelj_id = g.id
ORDER BY 
    l.vrijeme_promjene DESC, l.id DESC
    ;
-- ----------------------------------------------------------------------------------------------------------------------------------
-- 6. Automatski unos svih ažuriranja postojećih rezervacija u "log_rezervacija"  - - E.B.

DELIMITER //
CREATE TRIGGER trg_azuriranje_log_rezervacija
AFTER UPDATE ON rezervacija
FOR EACH ROW
BEGIN
    IF OLD.status != NEW.status THEN
        INSERT INTO log_rezervacije (rezervacija_id, stari_status, novi_status, korisnik_db)
        VALUES (NEW.id, OLD.status, NEW.status, USER());
    END IF;
END //
DELIMITER ;

UPDATE rezervacija 
SET 
    pocetak_datum = '2026-12-24',  
    kraj_datum = '2026-12-30',
    soba_id = 20,
    napomena = 'Gost zatražio promjenu termina pa otkazao',
    status = 'OTKAZANA'
WHERE id = 43;

-- 6. Upit
SELECT 
    l.rezervacija_id AS 'ID',
    CONCAT(g.ime, ' ', g.prezime) AS 'Gost',
    
    CONCAT(IFNULL(l.stari_status, 'NOVA'), ' --> ', l.novi_status) AS 'Povijest Promjene Statusa',
    DATE_FORMAT(l.vrijeme_promjene, '%H:%i:%s') AS 'Vrijeme Promjene',
    
    DATE_FORMAT(r.pocetak_datum, '%d.%m.%Y') AS 'Trenutni Datum Dolaska',
    r.napomena AS 'Trenutna Napomena (Zadnja)'

FROM 
    log_rezervacije l
JOIN 
    rezervacija r ON l.rezervacija_id = r.id
JOIN 
    gost g ON r.gost_nositelj_id = g.id
WHERE 
    l.rezervacija_id = 43
ORDER BY 
    l.id DESC
LIMIT 1;



-- ---------------------------------------------------------------------------------------------------------------------------------- 
-- 7. Automatski unos svih brisanja postojećih rezervacija u "log_rezervacija"  - - E.B.

ALTER TABLE log_rezervacije DROP FOREIGN KEY fk_rezervacija_id;  -- PITAJ EUGENA

DELIMITER //
CREATE TRIGGER trg_brisanje_log_rezervacija
AFTER DELETE ON rezervacija
FOR EACH ROW
BEGIN
    INSERT INTO log_rezervacije (rezervacija_id, stari_status, novi_status, korisnik_db)
    VALUES (OLD.id, OLD.status, 'OBRISANO', USER());
END //
DELIMITER ;

INSERT INTO rezervacija 
(gost_nositelj_id, zaposlenik_id, soba_id, promocija_id, datum_rezervacije, pocetak_datum, kraj_datum, broj_osoba, status, napomena) 
VALUES 
(10, 1, 50, NULL, NOW(),'2026-02-01','2027-02-01',1,'POTVRDJENA', 'Gost ostaje godinu dana? Typo?');


SET SQL_SAFE_UPDATES = 1;

DELETE FROM rezervacija 
WHERE gost_nositelj_id = 10 
  AND napomena LIKE 'Typo%';
  
SELECT 
    l.id AS 'ID Log',
    l.rezervacija_id AS 'ID Obrisane Rezervacije',
    
    DATE_FORMAT(l.vrijeme_promjene, '%d.%m.%Y %H:%i') AS 'Vrijeme brisanja',
    
    CONCAT(l.stari_status, ' --> ', l.novi_status) AS 'Status promjena',
    
    IFNULL(CONCAT(g.ime, ' ', g.prezime), 'Podaci trajno uklonjeni') AS 'Originalni Nositelj',
    
    l.korisnik_db AS 'Obrisao korisnik',
    
	CONCAT(TIMESTAMPDIFF(MINUTE, l.vrijeme_promjene, NOW()), ' min') AS 'Proteklo od brisanja'

FROM 
    log_rezervacije l

LEFT JOIN 
    rezervacija r ON l.rezervacija_id = r.id
LEFT JOIN 
    gost g ON r.gost_nositelj_id = g.id
WHERE 
    l.novi_status = 'OBRISANO'
ORDER BY 
    l.vrijeme_promjene DESC;





-- --------------------------------------------------------------------------------------------------------------
-- 8. Automatski unos besplatnog čišćenja na stavka_računu ukoliko  je boravak bio duži od tri dana  - - E.B.

DROP TRIGGER trg_besplatno_ciscenje_dugi_boravak;

DELIMITER //

CREATE TRIGGER trg_besplatno_ciscenje_dugi_boravak
BEFORE INSERT ON stavka_racuna
FOR EACH ROW
BEGIN
    DECLARE v_naziv_usluge VARCHAR(50);
    DECLARE v_rezervacija_id INT;
    DECLARE v_trajanje_dana INT;

    IF NEW.usluga_id IS NOT NULL THEN
        SELECT naziv INTO v_naziv_usluge 
        FROM usluga 
        WHERE id = NEW.usluga_id;

        IF v_naziv_usluge = 'Završno čišćenje' THEN
            
            SELECT rezervacija_id INTO v_rezervacija_id
            FROM racun
            WHERE id = NEW.racun_id;

            SELECT DATEDIFF(kraj_datum, pocetak_datum) INTO v_trajanje_dana
            FROM rezervacija
            WHERE id = v_rezervacija_id;

            IF v_trajanje_dana > 3 THEN
                SET NEW.cijena_jedinicna = 0.00;

                SET NEW.iznos_ukupno = 0.00; 

                SET NEW.opis = CONCAT(NEW.opis, ' (GRATIS -Boravak duži od 3 dana)');
            END IF;
            
        END IF;
    END IF;
END //
DELIMITER ;


INSERT INTO stavka_racuna (racun_id, usluga_id, tip_stavke, opis, kolicina, cijena_jedinicna, iznos_ukupno) 
VALUES (1, 31, 'USLUGA', 'Čišćenje redovno', 1, 30.00, 30.00);

INSERT INTO stavka_racuna (racun_id, usluga_id, tip_stavke, opis, kolicina, cijena_jedinicna, iznos_ukupno) 
VALUES (7, 31, 'USLUGA', 'Čišćenje redovno', 1, 30.00, 30.00);

-- 8. Upit
SELECT 
    CONCAT(g.ime, ' ', g.prezime) AS gost_nositelj,
    r.id AS br_racuna,
    DATE_FORMAT(rez.pocetak_datum, '%d.%m.%Y') AS check_in,
    DATE_FORMAT(rez.kraj_datum, '%d.%m.%Y') AS check_out,
    DATEDIFF(rez.kraj_datum, rez.pocetak_datum) AS trajanje_nocenja,
    sr.opis AS stavka_opis,
    CONCAT(FORMAT(u.cijena_trenutna, 2), ' €') AS redovna_cijena,
    CONCAT(FORMAT(sr.cijena_jedinicna, 2), ' €') AS naplacena_cijena,
    
    IF(DATEDIFF(rez.kraj_datum, rez.pocetak_datum) > 3 AND sr.cijena_jedinicna = 0, 
       'Gratis',
       
       IF(DATEDIFF(rez.kraj_datum, rez.pocetak_datum) <= 3 AND sr.cijena_jedinicna > 0,
          'Naplaćeno',
          
          'GREŠKA: Trigger ne šljaka!'
       )
    ) AS status

FROM stavka_racuna sr
JOIN racun r ON sr.racun_id = r.id
JOIN rezervacija rez ON r.rezervacija_id = rez.id
JOIN gost g ON rez.gost_nositelj_id = g.id
JOIN usluga u ON sr.usluga_id = u.id
WHERE u.naziv = 'Završno čišćenje'
ORDER BY r.id;


DELIMITER $$

/*
  Trigger: trg_racun_tip_konzistencija_ins
  Kada se okida: BEFORE INSERT na tablici racun
  Svrha: Osigurati konzistentnost između tip_racuna i rezervacija_id.

  Pravila:
  1) Ako je tip_racuna = 'HOTEL' → rezervacija_id MORA biti postavljen (NOT NULL).
     - Hotel račun uvijek pripada nekoj rezervaciji (smještaj).

  2) Ako je tip_racuna = 'RESTORAN' → rezervacija_id MORA biti NULL.
     - Restoran račun može biti za vanjskog gosta, pa ne smije imati vezu na rezervaciju.
*/
CREATE TRIGGER trg_racun_tip_konzistencija_ins
BEFORE INSERT ON racun
FOR EACH ROW
BEGIN
  -- Pravilo 1: HOTEL račun bez rezervacije nije dopušten
  IF NEW.tip_racuna = 'HOTEL' AND NEW.rezervacija_id IS NULL THEN
    SIGNAL SQLSTATE '45000'
      SET MESSAGE_TEXT = 'HOTEL racun mora imati rezervacija_id.';
  END IF;

  -- Pravilo 2: RESTORAN račun ne smije biti vezan uz rezervaciju
  IF NEW.tip_racuna = 'RESTORAN' AND NEW.rezervacija_id IS NOT NULL THEN
    SIGNAL SQLSTATE '45000'
      SET MESSAGE_TEXT = 'RESTORAN racun ne smije imati rezervacija_id.';
  END IF;
END$$

/*
  Trigger: trg_racun_tip_konzistencija_upd
  Kada se okida: BEFORE UPDATE na tablici racun
  Svrha: Ista provjera kao i na INSERT, ali prilikom izmjene postojećeg računa.

  Zašto treba i UPDATE trigger:
  - Da netko kasnije ne promijeni tip_racuna ili rezervacija_id i time “pokvari” logiku.
    Primjeri koje sprječava:
    - promjena HOTEL → RESTORAN uz zadržavanje rezervacija_id (ne smije)
    - promjena RESTORAN → HOTEL bez postavljanja rezervacija_id (ne smije)
*/
CREATE TRIGGER trg_racun_tip_konzistencija_upd
BEFORE UPDATE ON racun
FOR EACH ROW
BEGIN
  -- Pravilo 1: HOTEL račun mora imati rezervaciju
  IF NEW.tip_racuna = 'HOTEL' AND NEW.rezervacija_id IS NULL THEN
    SIGNAL SQLSTATE '45000'
      SET MESSAGE_TEXT = 'HOTEL racun mora imati rezervacija_id.';
  END IF;

  -- Pravilo 2: RESTORAN račun ne smije imati rezervaciju
  IF NEW.tip_racuna = 'RESTORAN' AND NEW.rezervacija_id IS NOT NULL THEN
    SIGNAL SQLSTATE '45000'
      SET MESSAGE_TEXT = 'RESTORAN racun ne smije imati rezervacija_id.';
  END IF;
END$$

DELIMITER ;
