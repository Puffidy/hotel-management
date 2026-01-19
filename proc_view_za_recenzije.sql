USE novi_projekt;

ALTER TABLE recenzija ADD COLUMN odgovor_hotela TEXT DEFAULT NULL;

-- view koji prikazuje recenzije zaedno sa odgovorima hotela 
CREATE OR REPLACE VIEW pregled_recenzija_za_menadzera AS
SELECT 
    recenzija.rezervacija_id,
    CONCAT(gost.ime, ' ', gost.prezime) AS 'Ime gosta',
    recenzija.ocjena AS 'Ocjena',
    recenzija.komentar AS 'Komentar gosta',
    COALESCE(recenzija.odgovor_hotela, 'Nema odgovora') AS 'Odgovor hotela',
    CASE 
        WHEN recenzija.odgovor_hotela IS NULL THEN 'Potrebna akcija'
        ELSE 'Riješeno'
    END AS 'Status'
FROM recenzija
JOIN rezervacija ON recenzija.rezervacija_id = rezervacija.id
JOIN gost ON rezervacija.gost_nositelj_id = gost.id
ORDER BY recenzija.odgovor_hotela IS NOT NULL, recenzija.ocjena ASC;

SELECT * FROM pregled_recenzija_za_menadzera;


DROP PROCEDURE IF EXISTS odgovori_na_recenziju;

DELIMITER //
CREATE PROCEDURE odgovori_na_recenziju(IN p_rezervacija_id INT, IN p_tekst_odgovor TEXT)
BEGIN
    DECLARE v_postoji INT;

    -- provjera da li recenzija postoji
    SELECT COUNT(*) INTO v_postoji
    FROM recenzija
    WHERE rezervacija_id = p_rezervacija_id;

    IF v_postoji = 0 THEN
        SIGNAL SQLSTATE '45000'
        SET MESSAGE_TEXT = 'Recenzija za ovu rezervaciju ne postoji.';
    END IF;

    -- upisi odgovor
    UPDATE recenzija
    SET odgovor_hotela = p_tekst_odgovor
    WHERE rezervacija_id = p_rezervacija_id;

    -- prikazi rezultat da vidis kako izgleda
    SELECT
        rezervacija_id,
        komentar AS "Komentar gosta: ",
        odgovor_hotela AS "Odgovor hotela: "
    FROM recenzija
    WHERE rezervacija_id = p_rezervacija_id;

END //

DELIMITER ;

CALL odgovori_na_recenziju(10, 'Pozvali smo ekipu za deratizaciju, a sobarici smo povećali plaću zbog legendarnog humora.');