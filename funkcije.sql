USE novi_projekt;

DELIMITER //
CREATE FUNCTION izracunaj_cijenu_smjestaja( p_soba_id INT, p_datum_dolaska DATE, p_datum_odlaska DATE) RETURNS DECIMAL(10,2)
DETERMINISTIC
BEGIN
	DECLARE v_ukupna_cijena DECIMAL(10,2) DEFAULT 0;
    DECLARE v_tip_sobe_id INT;
    
    -- prvo koji je tip sobe na temelju IDja
    SELECT tip_sobe_id INTO v_tip_sobe_id
    FROM soba WHERE id = p_soba_id;
    
    -- drugo cijena se racuna od ulaska do izlaska i cjena ovisi o sobi
    SELECT SUM(cijena_nocenja * (DATEDIFF(LEAST(p_datum_odlaska, datum_do), GREATEST(p_datum_dolaska, datum_od))))
    INTO v_ukupna_cijena
    FROM cjenik_soba WHERE tip_sobe_id = v_tip_sobe_id
		AND aktivan = 1
        AND datum_od < p_datum_odlaska
        AND datum_do > p_datum_dolaska;
    
    RETURN IFNULL(v_ukupna_cijena, 0);
END //
DELIMITER ;

-- SELECT izracunaj_cijenu_smjestaja(1, '2026-12-12', '2026-12-20') AS cijena_boravka; -- zimska cijena single sobe
-- SELECT izracunaj_cijenu_smjestaja(1, '2026-7-12', '2026-7-20') AS cijena_boravka; -- ljetna cijena single sobe




DELIMITER // 


DELIMITER // 

CREATE FUNCTION pdv_koji_moramo_platiti_za_uslugu (p_usluga_id INT) RETURNS DECIMAL(10,2)
DETERMINISTIC
BEGIN
    DECLARE v_owed_VAT DECIMAL(10,2) DEFAULT 0.00;

    select (cijena_trenutna * 0.13) - COALESCE(SUM(nabavna_cijena * kolicina_potrosnje) * 0.05, 0) as owed_VAT
    from usluga
    left join normativ
        on usluga.id = usluga_id
    left join artikl
        on artikl.id = artikl_id
    where usluga.id = p_usluga_id
    group by usluga.id, cijena_trenutna
    INTO v_owed_VAT;

    RETURN IFNULL(v_owed_VAT, 0);
END //
DELIMITER ; 

select usluga.id, pdv_koji_moramo_platiti(usluga.id) as owed_VAT
from usluga;


DROP FUNCTION IF EXISTS pdv_za_godinu;
DELIMITER // 

CREATE FUNCTION pdv_za_godinu (p_godina INT) RETURNS DECIMAL(10,2)
DETERMINISTIC
BEGIN
    DECLARE v_pdv_nocenje DECIMAL(10,2) DEFAULT 0.00;
    DECLARE v_pdv_usluge_izvan_restorana DECIMAL(10,2) DEFAULT 0.00;
    DECLARE v_pdv_usluge_unutar_restorana DECIMAL(10,2) DEFAULT 0.00;


    select SUM(stavka_racuna.iznos_ukupno * 0.13)
    from racun
    join stavka_racuna
        on racun.id = stavka_racuna.racun_id
    where YEAR(datum_izdavanja) = p_godina
        and tip_stavke = 'NOCENJE'
    INTO v_pdv_nocenje;

    select SUM(pdv_koji_moramo_platiti_za_uslugu(usluga_id))
    from racun
    join stavka_racuna
        on racun.id = stavka_racuna.racun_id
    where YEAR(datum_izdavanja) = p_godina
        and tip_stavke = 'USLUGA'
        and usluga_id IS NOT NULL
    INTO v_pdv_usluge_izvan_restorana;

    select SUM(pdv_koji_moramo_platiti_za_uslugu(restoran_stavka.usluga_id))
    from racun
    join stavka_racuna
        on racun.id = stavka_racuna.racun_id
    join restoran_stavka
        on stavka_racuna.restoran_stavka_id = restoran_stavka.id
    where YEAR(datum_izdavanja) = p_godina
        and tip_stavke = 'USLUGA'
        and restoran_stavka_id IS NOT NULL
    INTO v_pdv_usluge_unutar_restorana;

    RETURN (v_pdv_nocenje + v_pdv_usluge_izvan_restorana + v_pdv_usluge_unutar_restorana);
END //
DELIMITER ; 

-- select pdv_za_godinu(2026) as pdv_za_2026;


-- ----------------------------------------------
-- Izracun marze jela

DROP FUNCTION IF EXISTS izracunaj_marzu_jela;

DELIMITER //

CREATE FUNCTION izracunaj_marzu_jela(p_usluga_id INT) RETURNS DECIMAL(10,2)
DETERMINISTIC
BEGIN
    DECLARE v_prodajna DECIMAL(10,2);
    DECLARE v_trosak_nabave DECIMAL(10,2);
    
    -- 1. Dohvati prodajnu cijenu
    SELECT cijena_trenutna INTO v_prodajna 
    FROM usluga WHERE id = p_usluga_id;
    
    -- 2. Izračunaj ukupni trošak sastojaka (suma normativa)
    SELECT COALESCE(SUM(n.kolicina_potrosnje * a.nabavna_cijena), 0) 
    INTO v_trosak_nabave
    FROM normativ n
    JOIN artikl a ON n.artikl_id = a.id
    WHERE n.usluga_id = p_usluga_id;
    
    -- 3. Vrati razliku (Maržu)
    -- Ako nema sastojaka (trošak 0), marža je jednaka cijeni
    RETURN (v_prodajna - v_trosak_nabave);
END //

DELIMITER ;


DROP FUNCTION IF EXISTS provjeri_dostupnost_sobe;
DELIMITER //
CREATE FUNCTION provjeri_dostupnost_sobe(p_soba_id INT, p_datum_dolaska DATE, p_datum_odlaska DATE) RETURNS BOOLEAN 
DETERMINISTIC
BEGIN
    DECLARE v_zauzetost_broj INT DEFAULT 0;
    
    SELECT COUNT(*) INTO v_zauzetost_broj
    FROM rezervacija
    WHERE soba_id = p_soba_id
        AND status != 'OTKAZANA'
        AND pocetak_datum < p_datum_odlaska
        AND kraj_datum > p_datum_dolaska;

    RETURN v_zauzetost_broj = 0;
END //

DELIMITER ;


-- Treba vratiti 0 jer se siječe sa starom rezervacijom

SELECT provjeri_dostupnost_sobe(2, '2026-01-16', '2026-01-19') AS Mogu_Li_Rezervirati;

SELECT soba.id, soba.broj, soba.kapacitet_osoba, provjeri_dostupnost_sobe(soba.id, '2026-01-16', '2026-01-19') FROM soba;

DROP FUNCTION IF EXISTS provjeri_dostupnost_kapaciteta;
DELIMITER //
CREATE FUNCTION provjeri_dostupnost_kapaciteta(p_broj_osoba INT, p_datum_dolaska DATE, p_datum_odlaska DATE) RETURNS BOOLEAN 
DETERMINISTIC
BEGIN
    DECLARE v_broj_slobodnih_soba INT DEFAULT 0;
    
    SELECT COUNT(*) INTO v_broj_slobodnih_soba
    FROM soba
    WHERE kapacitet_osoba >= p_broj_osoba
    AND provjeri_dostupnost_sobe(soba.id, p_datum_dolaska, p_datum_odlaska) = 1;

    RETURN v_broj_slobodnih_soba >= 1;
END //

DELIMITER ;

-- 02.08 je zauzeta soba za 4 osobe sa ovim testnim podacima 
INSERT INTO rezervacija (id, gost_nositelj_id, zaposlenik_id, soba_id, promocija_id, datum_rezervacije, pocetak_datum, kraj_datum, vrijeme_check_in, vrijeme_check_out, broj_osoba, status, napomena) VALUES
(41, 1, 1, 36, NULL, '2026-05-01 10:00:00', '2026-08-01', '2026-08-05', NULL, NULL, 4, 'POTVRDJENA', 'Test Data - Room 36'),
(42, 2, 1, 37, NULL, '2026-05-01 10:05:00', '2026-07-28', '2026-08-03', NULL, NULL, 4, 'POTVRDJENA', 'Test Data - Room 37'),
(43, 3, 2, 40, NULL, '2026-05-01 10:10:00', '2026-07-20', '2026-08-10', NULL, NULL, 4, 'POTVRDJENA', 'Test Data - Room 40'),
(44, 4, 2, 41, NULL, '2026-05-01 10:15:00', '2026-08-01', '2026-08-03', NULL, NULL, 4, 'POTVRDJENA', 'Test Data - Room 41'),
(45, 5, 3, 43, NULL, '2026-05-01 10:20:00', '2026-07-31', '2026-08-04', NULL, NULL, 4, 'POTVRDJENA', 'Test Data - Room 43'),
(46, 6, 3, 45, NULL, '2026-05-01 10:25:00', '2026-08-01', '2026-08-03', NULL, NULL, 4, 'POTVRDJENA', 'Test Data - Room 45'),
(47, 1, 4, 46, NULL, '2026-05-01 10:30:00', '2026-06-01', '2026-09-01', NULL, NULL, 4, 'POTVRDJENA', 'Test Data - Room 46'),
(48, 2, 4, 50, NULL, '2026-05-01 10:35:00', '2026-07-30', '2026-08-05', NULL, NULL, 4, 'POTVRDJENA', 'Test Data - Room 50');

SELECT provjeri_dostupnost_kapaciteta(4, '2026-08-01', '2026-08-03') AS Mogu_Li_Rezervirati_Kapacitet;


DROP FUNCTION IF EXISTS dohvati_ukupan_iznos_rezervacije;
-- funkcija koja dohvaća ukupan iznos rezervacije -- ova funkcija je jednostavna ali cemo je iskoristi u proceduri i napraviti transakciju od iste 
DELIMITER //
CREATE FUNCTION dohvati_ukupan_iznos_rezervacije(p_rezervacija_id INT) RETURNS DECIMAL(10,2)
DETERMINISTIC
READS SQL DATA
BEGIN
    DECLARE v_ukupno DECIMAL (10,2);

    -- varijable za izracun boravisne
    DECLARE v_iznos_boravisne DECIMAL(10,2) DEFAULT 0.00;
    DECLARE v_broj_osoba INT;
    DECLARE v_broj_nocenja INT;
    DECLARE v_cijena_bp DECIMAL(10,2) DEFAULT 2.00;


    -- stavke iz tablice stavka_racuna usluge, smjestaj, ostalo
    SELECT COALESCE(SUM(stavka_racuna.iznos_ukupno), 0)
    INTO v_ukupno
    FROM stavka_racuna
    JOIN racun ON stavka_racuna.racun_id = racun.id
    WHERE racun.rezervacija_id = p_rezervacija_id;

    -- izracun boravisne pristojbe
    SELECT rezervacija.broj_osoba, 
           DATEDIFF(rezervacija.kraj_datum, rezervacija.pocetak_datum),
           COALESCE(cjenik_soba.boravisna_pristojba_po_osobi, 2.00)
    INTO v_broj_osoba, v_broj_nocenja, v_cijena_bp
    FROM rezervacija
    JOIN soba ON rezervacija.soba_id = soba.id
    JOIN cjenik_soba ON soba.tip_sobe_id = cjenik_soba.tip_sobe_id
    WHERE rezervacija.id = p_rezervacija_id
    LIMIT 1;

    SET v_iznos_boravisne = v_broj_osoba * v_broj_nocenja * v_cijena_bp;

    RETURN (v_ukupno + v_iznos_boravisne);
END //
DELIMITER ;

-- select dohvati_ukupan_iznos_rezervacije(1) as ukupno_za_rezervaciju_1;