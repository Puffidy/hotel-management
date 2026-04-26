USE novi_projekt;

-- ----------------------------------------------------------------------------------------------------------------------------------
-- 1. Okidač za novu rezervacija na istu sobu koja već rezervirana
DROP TRIGGER IF EXISTS  trg_dupla_rezervacija_sobe;

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

-- ----------------------------------------------------------------------------------------------------------------------------------
-- 2. Promocija se smije unijeti u rezervaciju samo ako je aktivna i vremenski važeća
DROP TRIGGER IF EXISTS trg_unos_provjera_valjanosti_promocije;
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

-- ----------------------------------------------------------------------------------------------------------------------------------
-- 3. Promocija se smije ažurirati u postojećoj rezervaciji samo ako je aktivna i vremenski važeća

drop trigger if exists trg_ažuriranje_rezervacije_provjera_valjanosti_promocije;

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

-- ----------------------------------------------------------------------------------------------------------------------------------
-- 4. Check in vrijeme striktno od 14:00h pa nadalje kod prijave gosta tj. ažuriranja relacije rezervacija
 drop trigger if exists trg_provjera_checkin_time;
DELIMITER //

CREATE TRIGGER trg_provjera_checkin_time
BEFORE UPDATE ON rezervacija
FOR EACH ROW
BEGIN
    IF NEW.vrijeme_check_in IS NOT NULL AND OLD.vrijeme_check_in IS NULL THEN

        IF TIME(NEW.vrijeme_check_in) <= '14:00:00' THEN
            SIGNAL SQLSTATE '45000'
            SET MESSAGE_TEXT = 'Greška: Check-in nije dozvoljen prije 14:00 sati!';
        END IF;

    END IF;
END //

DELIMITER ;

-- ----------------------------------------------------------------------------------------------------------------------------------
-- 5. Automatski unos svih novih rezervacija u "log_rezervacija"
DELIMITER //
CREATE TRIGGER trg_unos_log_rezervacija
AFTER INSERT ON rezervacija
FOR EACH ROW
BEGIN
    INSERT INTO log_rezervacije (rezervacija_id, stari_status, novi_status, korisnik_db)
    VALUES (NEW.id, NULL, NEW.status, USER());
END //
DELIMITER ;

-- ----------------------------------------------------------------------------------------------------------------------------------
-- 6. Automatski unos ažuriranja statusa postojećih rezervacija u "log_rezervacija"

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

-- ----------------------------------------------------------------------------------------------------------------------------------
-- 7. Automatski unos svih brisanja postojećih rezervacija u "log_rezervacija"

DELIMITER //
CREATE TRIGGER trg_brisanje_log_rezervacija
AFTER DELETE ON rezervacija
FOR EACH ROW
BEGIN
    INSERT INTO log_rezervacije (rezervacija_id, stari_status, novi_status, korisnik_db)
    VALUES (OLD.id, OLD.status, 'OBRISANO', USER());
END //
DELIMITER ;

-- --------------------------------------------------------------------------------------------------------------
-- 8. Automatski unos besplatnog čišćenja na stavka_računu ukoliko  je boravak bio duži od tri dana

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

-- Naknadni insert usluge čišćenje
INSERT INTO usluga (id, kategorija_id, naziv, opis, jedinica_mjere, cijena_trenutna)
VALUES (31, 1, 'Završno čišćenje', 'Čišćenje sobe nakon odlaska gosta', 'kom', 30.00);

-- ------------------------------------------------------------
-- 1. okidac provjera datum rezrvacije

DROP TRIGGER IF EXISTS trg_check_datumi_rezervacije;

DELIMITER //

CREATE TRIGGER trg_check_datumi_rezervacije
BEFORE INSERT ON rezervacija
FOR EACH ROW
BEGIN
    -- Provjera: Datum odlaska mora biti nakon datuma dolaska
    IF NEW.kraj_datum <= NEW.pocetak_datum THEN
        SIGNAL SQLSTATE '45000'
        SET MESSAGE_TEXT = 'Greška: Datum odlaska mora biti nakon datuma dolaska!';
    END IF;
END //

DELIMITER ;


-- ---------------------------------------------------------
-- 2. okidac za sprijecavanje ranog checkina

DROP TRIGGER IF EXISTS trg_sprijeci_rani_checkin;

DELIMITER //

CREATE TRIGGER trg_sprijeci_rani_checkin
BEFORE UPDATE ON rezervacija
FOR EACH ROW
BEGIN
    -- Provjera se vrši SAMO ako se status mijenja na 'U_TIJEKU' (dakle radi se Check-In)
    IF NEW.status = 'U_TIJEKU' AND OLD.status != 'U_TIJEKU' THEN

        -- Ako je današnji datum (CURDATE) manji od datuma početka rezervacije
        IF CURDATE() < NEW.pocetak_datum THEN
            SIGNAL SQLSTATE '45000'
            SET MESSAGE_TEXT = 'Greška: Check-in nije moguć prije datuma početka rezervacije!';
        END IF;

    END IF;
END //

DELIMITER ;

-- ------------------------------------
-- 3. okidac automatsko ciscenje sobe nakon checkouta

DELIMITER //

CREATE TRIGGER trg_auto_ciscenje_nakon_checkouta
AFTER UPDATE ON rezervacija
FOR EACH ROW
BEGIN
    -- Provjeravamo je li se status upravo promijenio u 'ZAVRSENA' (Check-out)
    IF NEW.status = 'ZAVRSENA' AND OLD.status != 'ZAVRSENA' THEN

        -- Automatski postavi status pripadajuće sobe na 'CISCENJE'
        UPDATE soba
        SET status = 'CISCENJE'
        WHERE id = NEW.soba_id;

    END IF;
END //

DELIMITER ;

-- ---------------------------------------
-- 4. okidac sprijeci rezervaciju ako je kvar ili ciscenje

DROP TRIGGER IF EXISTS trg_sprijeci_rezervaciju_kvar;

DELIMITER //

CREATE TRIGGER trg_sprijeci_rezervaciju_kvar
BEFORE INSERT ON rezervacija
FOR EACH ROW
BEGIN
    DECLARE v_status_sobe VARCHAR(20);

    -- Dohvati trenutni status sobe
    SELECT status INTO v_status_sobe
    FROM soba
    WHERE id = NEW.soba_id;

    -- Provjera: Je li soba pokvarena ILI se čisti?
    IF v_status_sobe IN ('IZVAN_FUNKCIJE', 'CISCENJE') THEN
        SIGNAL SQLSTATE '45000'
        SET MESSAGE_TEXT = 'Greška: Soba nije dostupna (Status je ČIŠĆENJE ili IZVAN FUNKCIJE)!';
    END IF;
END //

DELIMITER ;


DROP TRIGGER IF EXISTS kreiraj_racun_nakon_rezervacije;

DELIMITER //
CREATE TRIGGER kreiraj_racun_nakon_rezervacije
AFTER INSERT ON rezervacija
FOR EACH ROW
BEGIN
    INSERT INTO racun
        (rezervacija_id, tip_racuna, datum_izdavanja, iznos_ukupno, status_racuna, nacin_placanja)
    VALUES (NEW.id, 'HOTEL', NOW(), 0.00, 'OTVOREN', 'GOTOVINA');
    CALL dodaj_stavke_koje_fale_na_racun(NEW.id, LAST_INSERT_ID());
END //
DELIMITER ;
