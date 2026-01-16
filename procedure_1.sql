USE novi_projekt;

-- ---------------------------------------------------------------------------------------------------
-- 1. Otvaranje narudžbe u restoranu
DROP PROCEDURE proc_otvori_narudzbu;

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

-- #################


CALL proc_otvori_narudzbu(28, 10, @novi_id);
SELECT @novi_id;

SELECT * FROM restoran_narudzba;

-- --------------------------------------------------------------------------------------------
-- 2. Dodavanje stavki na narudžbu
DROP PROCEDURE proc_dodaj_stavku;

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

-- ###########

CALL proc_dodaj_stavku(15, 12, 2);

SELECT * FROM restoran_stavka;

 -- ---------------------------------------------------------------
 -- 3. Početak pripreme narudžbe
 
 DROP PROCEDURE IF EXISTS proc_zapocni_pripremu;
 
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

-- #############
CALL proc_zapocni_pripremu(24, @poruka_rezultat);

SELECT * FROM restoran_stavka;
SELECT * FROM artikl;
SELECT * FROM usluga;
SELECT * FROM normativ;

 -- ---------------------------------------------------------------
 -- 4. Posluživanje narudžbe
 
 DROP PROCEDURE proc_posluzi_stavku;
 
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

CALL proc_posluzi_stavku(24, @poruka_rezultat);

SELECT * FROM restoran_stavka;
SELECT * FROM artikl WHERE id=3;
SELECT * FROM usluga WHERE id=12;
SELECT * FROM normativ WHERE artikl_id=3 AND usluga_id=12;

 -- ---------------------------------------------------------------
 -- 5. Naplata naruđbe
 
DROP PROCEDURE IF EXISTS proc_naplati_narudzbu;

DELIMITER //

CREATE PROCEDURE proc_naplati_narudzbu(
    IN p_narudzba_id INT,
    IN p_nacin_placanja VARCHAR(20),
    IN p_broj_sobe INT,
    OUT p_poruka VARCHAR(100)
)
main: BEGIN  -- <--- Dodali smo oznaku "main" kako bi LEAVE znao sto napusta
    
    -- Ispravljen tipfeler (bilo je inznos)
    DECLARE v_ukupni_iznos DECIMAL(10,2);
    DECLARE v_status_narudzbe VARCHAR(20);
    DECLARE v_rezervacija_id INT DEFAULT NULL;
    DECLARE v_racun_id INT;
    DECLARE v_gost_ime VARCHAR(100);
    
    -- Ispravljen tipfeler (bilo je SQLEXEPTION)
    DECLARE EXIT HANDLER FOR SQLEXCEPTION 
    BEGIN
        ROLLBACK;
        SET p_poruka = 'Greška: Neuspjela naplata (SQL Error).';
    END;
    
    START TRANSACTION;
    
    -- provjera statusa narudžbe
    SELECT status INTO v_status_narudzbe
    FROM restoran_narudzba
    WHERE id = p_narudzba_id;
    
    -- Ako narudžba ne postoji ili nije otvorena
    IF v_status_narudzbe IS NULL OR v_status_narudzbe != 'OTVORENA' THEN
        SET p_poruka = 'Greška: Narudžba nije otvorena ili ne postoji.';
        ROLLBACK;
        LEAVE main; -- Izlazimo iz procedure
    ELSE
        -- izračun ukupnog iznosa
        SELECT SUM(kolicina * cijena_u_trenutku) INTO v_ukupni_iznos
        FROM restoran_stavka
        WHERE narudzba_id = p_narudzba_id AND status_pripreme != 'STORNIRANO';
        
        -- Ako je iznos 0 ili NULL
        IF v_ukupni_iznos IS NULL OR v_ukupni_iznos = 0 THEN
            -- Ispravljeno PLAĆENO u PLACENO (bez kvačice radi konzistentnosti)
            UPDATE restoran_narudzba SET status = 'PLACENO', datum_zatvaranja = NOW() WHERE id = p_narudzba_id;
            SET p_poruka = 'Narudžba zatvorena (iznos 0).';
            COMMIT;
            LEAVE main; -- Izlazimo jer nemamo što naplatiti
        ELSE
            -- Logika za određivanje plaćanja (Soba ili Restoran)
            
            -- 1. Pokušaj naći rezervaciju ako je unesen broj sobe
            IF p_broj_sobe IS NOT NULL THEN
                SELECT r.id, CONCAT(g.ime, ' ', g.prezime)
                INTO v_rezervacija_id, v_gost_ime
                FROM rezervacija r
                JOIN soba s ON r.soba_id = s.id
                JOIN gost g ON r.gost_nositelj_id = g.id
                WHERE s.broj = p_broj_sobe
                  AND r.status = 'U_TIJEKU';
                  
                -- Ako soba ne postoji ili nema gosta
                IF v_rezervacija_id IS NULL THEN
                    SET p_poruka = CONCAT('Greška: U sobi ', p_broj_sobe, ' trenutno nema prijavljenih gostiju!');
                    ROLLBACK;
                    LEAVE main; -- <--- Ovdje sada LEAVE main radi ispravno
                END IF;
            END IF;
            
            -- 2. Odabir scenarija naplate
            IF v_rezervacija_id IS NOT NULL THEN
                -- SCENARIJ A: GOST HOTELA (Na sobu)
                
                -- Nađi postojeći otvoren račun sobe
                SELECT id INTO v_racun_id
                FROM racun
                WHERE rezervacija_id = v_rezervacija_id AND status_racuna = 'OTVOREN' AND tip_racuna = 'HOTEL'
                LIMIT 1;

                -- Ako nema računa, otvori novi HOTEL račun
                IF v_racun_id IS NULL THEN
                    INSERT INTO racun (tip_racuna, rezervacija_id, datum_izdavanja, nacin_placanja, iznos_ukupno, status_racuna)
                    VALUES ('HOTEL', v_rezervacija_id, NOW(), 'VIRMANSKI', 0.00, 'OTVOREN');
                    SET v_racun_id = LAST_INSERT_ID();
                END IF;

                -- Dodaj stavku na taj račun
                INSERT INTO stavka_racuna (racun_id, tip_stavke, opis, kolicina, cijena_jedinicna, iznos_ukupno)
                VALUES (v_racun_id, 'USLUGA', CONCAT('Restoran - Narudžba #', p_narudzba_id), 1, v_ukupni_iznos, v_ukupni_iznos);
                
                -- Ažuriraj ukupni iznos računa
                UPDATE racun SET iznos_ukupno = IFNULL(iznos_ukupno, 0) + v_ukupni_iznos WHERE id = v_racun_id;

                SET p_poruka = CONCAT('Uspjeh: Naplaćeno na sobu ', p_broj_sobe, ' (Gost: ', v_gost_ime, ')');
                
            ELSE
                -- SCENARIJ B: VANJSKI GOST (Direktna naplata)
                
                INSERT INTO racun (tip_racuna, rezervacija_id, datum_izdavanja, nacin_placanja, iznos_ukupno, status_racuna)
                VALUES ('RESTORAN', NULL, NOW(), p_nacin_placanja, v_ukupni_iznos, 'PLACENO');
                
                SET v_racun_id = LAST_INSERT_ID();

                INSERT INTO stavka_racuna (racun_id, tip_stavke, opis, kolicina, cijena_jedinicna, iznos_ukupno)
                VALUES (v_racun_id, 'USLUGA', CONCAT('Restoran - Narudžba #', p_narudzba_id), 1, v_ukupni_iznos, v_ukupni_iznos);

                SET p_poruka = CONCAT('Uspjeh: Naplaćeno vanjskom gostu. Račun ID: ', v_racun_id);
            END IF;

            -- Zajednički korak: Zatvori restoransku narudžbu
            UPDATE restoran_narudzba 
            SET status = 'PLACENO', datum_zatvaranja = NOW()
            WHERE id = p_narudzba_id;

            COMMIT;
        END IF;
    END IF;
        
END // -- Kraj procedure

DELIMITER ;
