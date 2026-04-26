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
