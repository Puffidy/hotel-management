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



DROP FUNCTION IF EXISTS pdv_koji_moramo_platiti_za_uslugu;
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
    where YEAR(datum_izdavanja) = '2026'
        and tip_stavke = 'NOCENJE'
    INTO v_pdv_nocenje;

    select SUM(pdv_koji_moramo_platiti_za_uslugu(usluga_id))
    from racun
    join stavka_racuna
        on racun.id = stavka_racuna.racun_id
    where YEAR(datum_izdavanja) = '2026'
        and tip_stavke = 'USLUGA'
        and usluga_id IS NOT NULL
    INTO v_pdv_usluge_izvan_restorana;

    select SUM(pdv_koji_moramo_platiti_za_uslugu(restoran_stavka.usluga_id))
    from racun
    join stavka_racuna
        on racun.id = stavka_racuna.racun_id
    join restoran_stavka
        on stavka_racuna.restoran_stavka_id = restoran_stavka.id
    where YEAR(datum_izdavanja) = '2026'
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

