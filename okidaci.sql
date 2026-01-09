-- ----------------------------------------------------------------------------------------------------------------------------------
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
