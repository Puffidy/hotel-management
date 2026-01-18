USE novi_projekt;

-- ---------------------------------------------------------------------------------------------------
-- 1. Otvaranje narudžbe u restoranu

DELIMITER //

CREATE PROCEDURE proc_otvori_narudzbu(
	IN p_zaposlenik_id INT,
	IN p_stol_id INT,
	OUT p_nova_narudzba_id INT)
BEGIN
	DECLARE v_postoji_otvorena INT DEFAULT 0;
        
	SELECT COUNT(*) INTO v_postoji_otvorena
    FROM restoran_narudzba
    WHERE restoran_stol_id = p_stol_id AND status = 'OTVORENA';
    
    IF v_postoji_otvorena > 0 THEN
		SIGNAL SQLSTATE '45001' SET MESSAGE_TEXT = 'Greška: Stol već ima otvorenu narudžbu!';
	ELSE
		INSERT INTO restoran_narudzba (zaposlenik_id, restoran_stol_id, datum_otvaranja, status)
        VALUES (p_zaposlenik_id, p_stol_id, NOW(), 'OTVORENA');
		
        SET p_nova_narudzba_id = LAST_INSERT_ID();
	END IF;
END //

DELIMITER ;

-- --------------------------------------------------------------------------------------------
-- 2. Dodavanje stavki na narudžbu

DELIMITER //

CREATE PROCEDURE proc_dodaj_stavku(
	IN p_narudzba_id INT,
    IN p_usluga_id INT,
    IN p_kolicina INT)
BEGIN
	DECLARE v_cijena_u_trenutku DECIMAL(10,2);
    DECLARE v_status_narudzbe VARCHAR(20);
    
    SELECT status INTO v_status_narudzbe
    FROM restoran_narudzba WHERE id = p_narudzba_id;
    
    IF v_status_narudzbe != 'OTVORENA' THEN
		SIGNAL SQLSTATE '45002' SET MESSAGE_TEXT = 'Greška: ne mogu dodati stavku na zatvorenu narudžbu!';
	END IF;
    
    SELECT cijena_trenutna INTO v_cijena_u_trenutku
    FROM usluga WHERE id = p_usluga_id;
    
    INSERT INTO restoran_stavka (narudzba_id, usluga_id, kolicina, cijena_u_trenutku, status_pripreme)
    VALUES (p_narudzba_id, p_usluga_id, p_kolicina, v_cijena_u_trenutku, 'NARUCENO');

END //

DELIMITER ;

 -- ---------------------------------------------------------------
 -- 3. Početak pripreme narudžbe
 
 
 DELIMITER //
 
 CREATE PROCEDURE proc_zapocni_pripremu( 
	IN p_stavka_id INT,
    OUT p_poruka VARCHAR (100)
    )
BEGIN
	DECLARE v_usluga_id INT;
    DECLARE v_kolicina_naruceno INT;
    DECLARE v_trenutni_status VARCHAR(20);
    DECLARE v_nedovoljno_zaliha INT DEFAULT 0;
    
    DECLARE EXIT HANDLER FOR SQLEXCEPTION
    BEGIN
		ROLLBACK;
        SET p_poruka = 'Greška: Došlo je do problema u bazi.';
	END;
    
    START TRANSACTION;
    
    SELECT usluga_id, kolicina, status_pripreme
    INTO v_usluga_id, v_kolicina_naruceno, v_trenutni_status
    FROM restoran_stavka
    WHERE id = p_stavka_id;
    
    IF v_usluga_id IS NULL THEN
		SET p_poruka = 'Greška: Stavka ne postoji!';
        ROLLBACK;
	ELSEIF v_trenutni_status != 'NARUCENO' THEN
		SET p_poruka = CONCAT('Greška: Ne mogu pripremiti stavku koja je u statusu ', v_trenutni_status);
        ROLLBACK;
	ELSE 
		SELECT COUNT(*) INTO v_nedovoljno_zaliha
        FROM normativ n
        JOIN artikl a ON n.artikl_id = a.id
        WHERE n.usluga_id = v_usluga_id
			AND (a.stanje_zaliha - (n.kolicina_potrosnje * v_kolicina_naruceno)) < 0;
            
		IF v_nedovoljno_zaliha > 0 THEN
			SET p_poruka = 'Greška: Nema dovoljno namirnica na skladištu za ovu narudžbu!';
            ROLLBACK;
		ELSE
			UPDATE artikl a
            JOIN normativ n ON a.id = n.artikl_id
            SET a.stanje_zaliha = a.stanje_zaliha - (n.kolicina_potrosnje * v_kolicina_naruceno)
            WHERE n.usluga_id = v_usluga_id;
            
            UPDATE restoran_stavka
            SET status_pripreme = 'PRIPREMA'
            WHERE id = p_stavka_id;
            
            SET p_poruka = 'Namirnice rezervirane, priprema započeta.';
            COMMIT;
		END IF;
	END IF;
END //
 
DELIMITER ;

 -- ---------------------------------------------------------------
 -- 4. Posluživanje narudžbe
 

 
 DELIMITER //
 
 CREATE PROCEDURE proc_posluzi_stavku(
	IN p_stavka_id INT,
    OUT p_poruka VARCHAR(100)
    )
BEGIN
	DECLARE v_usluga_id INT;
    DECLARE v_kolicina_naruceno INT;
    DECLARE v_trenutni_status VARCHAR(20);
    DECLARE v_nedovoljno_zaliha INT DEFAULT 0;
    
    DECLARE EXIT HANDLER FOR SQLEXCEPTION
    BEGIN
		ROLLBACK;
        SET p_poruka = 'Greška: Došlo je do problema u bazi.';
	END;
    
    START TRANSACTION;
    
    SELECT usluga_id, kolicina, status_pripreme
    INTO v_usluga_id, v_kolicina_naruceno, v_trenutni_status
    FROM restoran_stavka
    WHERE id = p_stavka_id;
    
    IF v_trenutni_status = 'PRIPREMA' THEN
		UPDATE restoran_stavka SET status_pripreme = 'POSLUZENO' WHERE id = p_stavka_id;
        SET p_poruka = 'Jelo posluženo (zalihe su skinute ranije).';
        COMMIT;

    -- SCENARIJ 2: Stavka je tek NARUCENA (Npr. piće koje preskače pripremu) -> MORAMO SKINITI ZALIHE
    ELSEIF v_trenutni_status = 'NARUCENO' THEN
        -- Provjera zaliha
        SELECT COUNT(*) INTO v_nedovoljno_zaliha
        FROM normativ n
        JOIN artikl a ON n.artikl_id = a.id
        WHERE n.usluga_id = v_usluga_id
          AND (a.stanje_zaliha - (n.kolicina_potrosnje * v_kolicina_naruceno)) < 0;

        IF v_nedovoljno_zaliha > 0 THEN
            SET p_poruka = 'Greška: Nema dovoljno artikala na zalihi za posluživanje!';
            ROLLBACK;
        ELSE
            -- Skidanje zaliha
            UPDATE artikl a
            JOIN normativ n ON a.id = n.artikl_id
            SET a.stanje_zaliha = a.stanje_zaliha - (n.kolicina_potrosnje * v_kolicina_naruceno)
            WHERE n.usluga_id = v_usluga_id;

            -- Update statusa
            UPDATE restoran_stavka SET status_pripreme = 'POSLUZENO' WHERE id = p_stavka_id;
            SET p_poruka = 'Posluženo i skinuto sa zaliha (direktna narudžba).';
            COMMIT;
        END IF;

    ELSEIF v_trenutni_status = 'POSLUZENO' THEN
        SET p_poruka = 'Info: Već je posluženo.';
        ROLLBACK;
    ELSE
        SET p_poruka = 'Greška: Nepoznat status.';
        ROLLBACK;
    END IF;
END //

DELIMITER ;

 -- ---------------------------------------------------------------
 -- 5. Naplata naruđbe

DELIMITER //

CREATE PROCEDURE proc_naplati_narudzbu(
    IN p_narudzba_id INT,
    IN p_nacin_placanja VARCHAR(20),
    IN p_broj_sobe INT,
    OUT p_poruka VARCHAR(100)
)
main: BEGIN
    -- Varijable za logiku računa
    DECLARE v_status_narudzbe VARCHAR(20);
    DECLARE v_rezervacija_id INT DEFAULT NULL;
    DECLARE v_racun_id INT;
    DECLARE v_gost_ime VARCHAR(100);
    
    -- Varijable za KURSOR (čitanje stavki narudžbe)
    DECLARE v_naziv_usluge VARCHAR(50);
    DECLARE v_kolicina INT;
    DECLARE v_cijena DECIMAL(10,2);
    DECLARE v_stavka_ukupno DECIMAL(10,2);
    
    -- Varijabla za kontrolu petlje
    DECLARE done INT DEFAULT FALSE;
    
    -- 1. DEKLARACIJA KURSORA
    -- Dohvaćamo naziv, količinu i cijenu za svaku stavku te narudžbe
    DECLARE cur_stavke CURSOR FOR 
        SELECT u.naziv, rs.kolicina, rs.cijena_u_trenutku
        FROM restoran_stavka rs
        JOIN usluga u ON rs.usluga_id = u.id
        WHERE rs.narudzba_id = p_narudzba_id 
          AND rs.status_pripreme != 'STORNIRANO';
          
    -- Handler koji javlja kada kursor dođe do kraja podataka
    DECLARE CONTINUE HANDLER FOR NOT FOUND SET done = TRUE;

    -- Handler za greške (rollback transakcije)
    DECLARE EXIT HANDLER FOR SQLEXCEPTION 
    BEGIN
        ROLLBACK;
        SET p_poruka = 'Greška: Neuspjela naplata (SQL Error).';
    END;
    
    START TRANSACTION;
    
    -- A) Provjera statusa narudžbe
    SELECT status INTO v_status_narudzbe FROM restoran_narudzba WHERE id = p_narudzba_id;
    
    IF v_status_narudzbe IS NULL OR v_status_narudzbe != 'OTVORENA' THEN 
        SET p_poruka = 'Greška: Narudžba nije otvorena ili ne postoji.';
        ROLLBACK;
        LEAVE main;
    END IF;

    -- B) Pronalazak rezervacije ako je unesena soba
    IF p_broj_sobe IS NOT NULL THEN
        SELECT r.id, CONCAT(g.ime, ' ', g.prezime) 
        INTO v_rezervacija_id, v_gost_ime
        FROM rezervacija r 
        JOIN soba s ON r.soba_id = s.id 
        JOIN gost g ON r.gost_nositelj_id = g.id
        WHERE s.broj = p_broj_sobe AND r.status = 'U_TIJEKU';
        
        IF v_rezervacija_id IS NULL THEN
            SET p_poruka = CONCAT('Greška: U sobi ', p_broj_sobe, ' nema prijavljenih gostiju!');
            ROLLBACK;
            LEAVE main;
        END IF;
    END IF;

    -- C) Kreiranje ili dohvaćanje RAČUNA (Header)
    IF v_rezervacija_id IS NOT NULL THEN
        -- SCENARIJ: Gosti hotela (traži postojeći otvoren račun)
        SELECT id INTO v_racun_id 
        FROM racun 
        WHERE rezervacija_id = v_rezervacija_id 
          AND status_racuna = 'OTVOREN' 
          AND tip_racuna = 'HOTEL' 
        LIMIT 1;
        
        -- Ako nema računa, otvori novi
        IF v_racun_id IS NULL THEN
            INSERT INTO racun (tip_racuna, rezervacija_id, datum_izdavanja, nacin_placanja, iznos_ukupno, status_racuna)
            VALUES ('HOTEL', v_rezervacija_id, NOW(), 'VIRMANSKI', 0.00, 'OTVOREN');
            SET v_racun_id = LAST_INSERT_ID();
        END IF;
    ELSE
        -- SCENARIJ: Vanjski gosti (odmah novi račun)
        INSERT INTO racun (tip_racuna, rezervacija_id, datum_izdavanja, nacin_placanja, iznos_ukupno, status_racuna)
        VALUES ('RESTORAN', NULL, NOW(), p_nacin_placanja, 0.00, 'PLACENO');
        SET v_racun_id = LAST_INSERT_ID();
    END IF;

    -- D) KURSOR I PETLJA (Glavni dio promjene)
    -- Ovdje prebacujemo stavku po stavku iz narudžbe u račun
    
    OPEN cur_stavke; -- Otvaramo kursor
    
    read_loop: LOOP
        FETCH cur_stavke INTO v_naziv_usluge, v_kolicina, v_cijena;
        
        -- Ako nema više redaka, izađi iz petlje
        IF done THEN
            LEAVE read_loop;
        END IF;
        
        -- Izračun cijene za tu stavku
        SET v_stavka_ukupno = v_kolicina * v_cijena;
        
        -- INSERT pojedinačne stavke na račun
        INSERT INTO stavka_racuna (racun_id, tip_stavke, opis, kolicina, cijena_jedinicna, iznos_ukupno)
        VALUES (v_racun_id, 'USLUGA', v_naziv_usluge, v_kolicina, v_cijena, v_stavka_ukupno);
        
    END LOOP;
    
    CLOSE cur_stavke; -- Zatvaramo kursor
    
    -- E) Finalno ažuriranje ukupnog iznosa računa
    -- Zbrajamo sve stavke koje smo upravo unijeli (i one od prije ako je hotelski račun)
    UPDATE racun 
    SET iznos_ukupno = (SELECT SUM(iznos_ukupno) FROM stavka_racuna WHERE racun_id = v_racun_id)
    WHERE id = v_racun_id;

    -- F) Zatvaranje restoranske narudžbe
    UPDATE restoran_narudzba 
    SET status = 'PLACENO', datum_zatvaranja = NOW() 
    WHERE id = p_narudzba_id;
    
    SET p_poruka = CONCAT('Uspjeh: Račun naplaćen (ID Računa: ', v_racun_id, ')');
    COMMIT;

END //

DELIMITER ;

-- -----------------------------------------------
-- 6. Procedura za kreiranje nove rezervacije
DELIMITER //

CREATE PROCEDURE proc_kreiraj_rezervaciju(
    IN p_gost_id INT,
    IN p_soba_id INT,
    IN p_promocija_id INT, -- Može biti NULL
    IN p_datum_dolaska DATE,
    IN p_datum_odlaska DATE,
    IN p_broj_osoba INT,
    IN p_napomena TEXT,
    IN p_zaposlenik_id INT
)
BEGIN
    INSERT INTO rezervacija 
    (gost_nositelj_id, zaposlenik_id, soba_id, promocija_id, pocetak_datum, kraj_datum, broj_osoba, status, napomena)
    VALUES 
    (p_gost_id, p_zaposlenik_id, p_soba_id, p_promocija_id, p_datum_dolaska, p_datum_odlaska, p_broj_osoba, 'POTVRDJENA', p_napomena);
END //

DELIMITER ;

-- ----------------------------------------------------
-- 7. Procedura za unos novog gosta

DELIMITER //

CREATE PROCEDURE proc_kreiraj_gosta(
    IN p_ime VARCHAR(50),
    IN p_prezime VARCHAR(50),
    IN p_vrsta_dok_id INT,
    IN p_broj_dok VARCHAR(30),
    IN p_grad_id INT,
    IN p_adresa VARCHAR(100),
    IN p_drzava_id INT
)
BEGIN
    INSERT INTO gost 
    (ime, prezime, vrsta_dokumenta_id, broj_dokumenta, prebivaliste_grad_id, prebivaliste_adresa, drzavljanstvo_id)
    VALUES 
    (p_ime, p_prezime, p_vrsta_dok_id, p_broj_dok, p_grad_id, p_adresa, p_drzava_id);
END //

DELIMITER ;

-- ------------------------------------------------
-- 8. Procedura za Check-In


DELIMITER //

CREATE PROCEDURE proc_rezervacija_check_in(
    IN p_rezervacija_id INT
)
BEGIN
    UPDATE rezervacija 
    SET status = 'U_TIJEKU', 
        vrijeme_check_in = NOW() 
    WHERE id = p_rezervacija_id;
END //

DELIMITER ;

-- -------------------------------------------
-- 9. Procedura za Check-Out

DELIMITER //

CREATE PROCEDURE proc_rezervacija_check_out(
    IN p_rezervacija_id INT
)
BEGIN
    UPDATE rezervacija 
    SET status = 'ZAVRSENA', 
        vrijeme_check_out = NOW() 
    WHERE id = p_rezervacija_id;
END //

DELIMITER ;

-- -----------------------------------------------
-- 10. Dodavanje usluge na sobu

DELIMITER //

CREATE PROCEDURE proc_dodaj_uslugu_na_sobu(
    IN p_rezervacija_id INT,
    IN p_usluga_id INT,
    IN p_kolicina INT,
    IN p_napomena VARCHAR(100)
)
BEGIN
    DECLARE v_racun_id INT;
    DECLARE v_cijena DECIMAL(10,2);
    DECLARE v_naziv_usluge VARCHAR(50);
    DECLARE v_konacni_opis VARCHAR(100);

    SELECT cijena_trenutna, naziv INTO v_cijena, v_naziv_usluge 
    FROM usluga WHERE id = p_usluga_id;

    SET v_konacni_opis = COALESCE(NULLIF(p_napomena, ''), v_naziv_usluge);

    SELECT id INTO v_racun_id
    FROM racun 
    WHERE rezervacija_id = p_rezervacija_id 
      AND tip_racuna = 'HOTEL' 
      AND status_racuna = 'OTVOREN' 
    LIMIT 1;

    -- Ako račun ne postoji, otvori ga automatski
    IF v_racun_id IS NULL THEN
        INSERT INTO racun (tip_racuna, rezervacija_id, nacin_placanja, iznos_ukupno, status_racuna)
        VALUES ('HOTEL', p_rezervacija_id, 'VIRMANSKI', 0.00, 'OTVOREN');
        SET v_racun_id = LAST_INSERT_ID();
    END IF;
    
    INSERT INTO stavka_racuna (racun_id, usluga_id, tip_stavke, opis, kolicina, cijena_jedinicna, iznos_ukupno)
    VALUES (v_racun_id, p_usluga_id, 'USLUGA', v_konacni_opis, p_kolicina, v_cijena, v_cijena * p_kolicina);

    -- Ažuriraj ukupni iznos
    UPDATE racun 
    SET iznos_ukupno = (SELECT SUM(iznos_ukupno) FROM stavka_racuna WHERE racun_id = v_racun_id)
    WHERE id = v_racun_id;

END //

DELIMITER ;


-- ---------------------------------------
-- 13. procedura prijave kvara

DELIMITER //

CREATE PROCEDURE proc_prijavi_kvar(
    IN p_zaposlenik_id INT,
    IN p_soba_id INT,
    IN p_opis_kvara TEXT,
    IN p_korisnik_kriv INT -- 0 ili 1 (Boolean)
)
BEGIN
    -- A) Unos u dnevnik servisa
    INSERT INTO servis_dnevni_nalog (zaposlenik_id, soba_id, opis, korisnik_placa, datum_naloga, rijeseno)
    VALUES (p_zaposlenik_id, p_soba_id, p_opis_kvara, p_korisnik_kriv, NOW(), 0);

    -- B) Automatsko stavljanje sobe "IZVAN FUNKCIJE"
    UPDATE soba 
    SET status = 'IZVAN_FUNKCIJE' 
    WHERE id = p_soba_id;
END //

DELIMITER ;
