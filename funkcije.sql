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




