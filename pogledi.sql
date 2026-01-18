/***********POGLED ZA TRENUTNO STANJE SOBA*************/
CREATE OR REPLACE VIEW trenutno_stanje_soba AS
SELECT
    s.id AS soba_id,
    s.broj AS broj_sobe,
    CASE
        /*Ako postoji barem jedna aktivna rezervacija za danas*/
        WHEN EXISTS (
            SELECT 1
            FROM rezervacija r
            WHERE r.soba_id = s.id
              /*Današnji datum mora biti unutar perioda boravka*/
              AND CURDATE() BETWEEN r.pocetak_datum AND r.kraj_datum
              /*Rezervacija mora biti važeća*/
              AND r.status IN ('POTVRDJENA', 'U_TIJEKU')
        )
        THEN 'ZAUZETA'      /*Soba je zauzeta*/
        ELSE s.status      /*Inače koristi osnovni status iz tablice soba*/
    END AS trenutno_stanje
FROM soba s;
SELECT * FROM trenutno_stanje_soba;

/************POGLED ZA RAČUN PO REZERVACIJI***************/

CREATE OR REPLACE VIEW racun_po_rezervaciji AS
SELECT
    r.id AS rezervacija_id,
    r.status AS status_rezervacije,
    g.id AS gost_id,
	/*Ime i prezime gosta*/
    CONCAT(g.ime, ' ', g.prezime) AS ime_prezime_gosta,
    s.broj AS broj_sobe,
	/*Broji koliko je računa izdano za ovu rezervaciju*/
    COUNT(DISTINCT ra.id) AS broj_racuna,
    /*Ukupni iznos svih stavki na svim računima*/ 
    COALESCE(SUM(sr.iznos_ukupno), 0) AS ukupni_iznos /*osigurava da rezultat nije NULL*/
FROM rezervacija r
JOIN gost g ON g.id = r.gost_nositelj_id
JOIN soba s ON s.id = r.soba_id
LEFT JOIN racun ra ON ra.rezervacija_id = r.id
LEFT JOIN stavka_racuna sr ON sr.racun_id = ra.id
/*Grupiranje po rezervaciji*/
GROUP BY
    r.id,
    r.status,
    g.id,
    s.broj;
SELECT * FROM racun_po_rezervaciji;
/*****************POGLED ZA PROVJERE ZALIHA****************/
CREATE OR REPLACE VIEW low_stock_alert AS
SELECT
    a.id AS artikl_id,
    a.naziv AS artikl,
    a.stanje_zaliha,
    a.jedinica_mjere,
    a.nabavna_cijena,
    CASE
        WHEN a.stanje_zaliha = 0 THEN 'NEMA ZALIHE'
        WHEN a.stanje_zaliha <= 5 THEN 'KRITICNO NISKO'
        ELSE 'OK'
    END AS status_zalihe
FROM artikl a
	/*Samo roba koja je kritična ili je nema*/
WHERE a.stanje_zaliha <= 5;
SELECT * FROM low_stock_alert;

/******************Najbolji gosti po potrosnji ************************/
CREATE OR REPLACE VIEW najbolji_gosti_potrosnja AS
SELECT
    g.id AS gost_id,
	/*Puno ime gosta*/
    CONCAT(g.ime, ' ', g.prezime) AS gost,
    g.vip_status,
	/*Završene rezervacije*/
    COUNT(DISTINCT r.id) AS broj_rezervacija,
	/*Ukupna potrošnja kroz sve stavke računa*/
    COALESCE(SUM(sr.iznos_ukupno), 0) AS ukupna_potrosnja
FROM gost g
JOIN rezervacija r ON r.gost_nositelj_id = g.id
JOIN racun ra ON ra.rezervacija_id = r.id
JOIN stavka_racuna sr ON sr.racun_id = ra.id
/*Samo završene rezervacije*/
WHERE r.status = 'ZAVRSENA'
/*Grupiranje po gostu*/
GROUP BY g.id, g.vip_status;
SELECT * FROM najbolji_gosti_potrosnja LIMIT 10;

/***********************EVIDENCIJA CIJENA SOBA*************************/
CREATE OR REPLACE VIEW evidencija_cijena_soba AS
SELECT
    cs.id AS cjenik_id,
    ts.naziv AS tip_sobe,
    cs.datum_od,
    cs.datum_do,
    cs.cijena_nocenja,
    cs.boravisna_pristojba_po_osobi,
    cs.aktivan
FROM cjenik_soba cs
JOIN tip_sobe ts ON ts.id = cs.tip_sobe_id
ORDER BY ts.naziv, cs.datum_od DESC;
SELECT * FROM evidencija_cijena_soba;

/******************NEPLAĆENI RAČUNI***********************/
CREATE OR REPLACE VIEW neplaceni_racuni AS
SELECT
    r.id AS racun_id,
    r.tip_racuna,
    r.rezervacija_id,
    r.datum_izdavanja,
    r.iznos_ukupno
FROM racun r
WHERE r.status_racuna = 'OTVOREN' 
ORDER BY r.datum_izdavanja DESC;
SELECT *FROM neplaceni_racuni;


-- -----------------------------------------
-- 1. pregled svih racuna

CREATE OR REPLACE VIEW pregled_svih_racuna AS
SELECT 
    r.id AS racun_id,
    r.tip_racuna,
    r.status_racuna,
    r.iznos_ukupno,
    r.nacin_placanja,
    r.datum_izdavanja,
    r.rezervacija_id,
    
    COALESCE(CONCAT(g.ime, ' ', g.prezime), 'Vanjski Gost') AS gost_nositelj
FROM racun r
LEFT JOIN rezervacija rez ON r.rezervacija_id = rez.id
LEFT JOIN gost g ON rez.gost_nositelj_id = g.id;

-- ---------------------------------------------
-- 2. pregled zaliha skladista

CREATE OR REPLACE VIEW pregled_zaliha_skladiste AS
SELECT 
    a.id AS artikl_id,
    a.naziv,
    a.stanje_zaliha,
    a.jedinica_mjere,
    a.nabavna_cijena,
    
    (a.stanje_zaliha * a.nabavna_cijena) AS ukupna_vrijednost
FROM artikl a;

-- ---------------------------------------
-- 3. pregled svih rezrvacija

CREATE OR REPLACE VIEW pregled_svih_rezervacija AS
SELECT 
    r.id AS rezervacija_id,
    CONCAT(g.ime, ' ', g.prezime) AS gost,
    s.broj AS soba,
    r.pocetak_datum,
    r.kraj_datum,
    r.status,
    r.broj_osoba,
    r.napomena
FROM rezervacija r
JOIN gost g ON r.gost_nositelj_id = g.id
JOIN soba s ON r.soba_id = s.id
ORDER BY r.pocetak_datum DESC;

-- -------------------------------------------
-- 4. pogled za meni

CREATE OR REPLACE VIEW view_meni_restoran AS
SELECT id, naziv, cijena_trenutna, kategorija_id
FROM usluga 
WHERE kategorija_id IN (1, 2); -- 1=Hrana, 2=Piće

-- ------------------------------------------------
-- 5. pogled narudzbi kuhinja

CREATE OR REPLACE VIEW view_kuhinja_display AS
SELECT 
    rs.id AS stavka_id,
    rs.narudzba_id,
    u.naziv AS naziv_jela,
    rs.kolicina,
    rs.status_pripreme,
    u.kategorija_id
FROM restoran_stavka rs
JOIN usluga u ON rs.usluga_id = u.id
WHERE rs.status_pripreme IN ('NARUCENO', 'PRIPREMA');

-- -------------------------------------------------
-- 6. pogled otvorene narudzbe

CREATE OR REPLACE VIEW view_otvorene_narudzbe_total AS
SELECT 
    rn.id AS narudzba_id,
    rs.broj_stola,
    rs.lokacija,   
    COALESCE(SUM(rst.kolicina * rst.cijena_u_trenutku), 0) AS total_iznos
FROM restoran_narudzba rn
JOIN restoran_stol rs ON rn.restoran_stol_id = rs.id
LEFT JOIN restoran_stavka rst ON rn.id = rst.narudzba_id
WHERE rn.status = 'OTVORENA'
GROUP BY rn.id, rs.broj_stola, rs.lokacija;

-- --------------------------------------------
-- 7. pogled soba za ciscenje

CREATE OR REPLACE VIEW view_sobe_za_ciscenje AS
SELECT s.id, s.broj, ts.naziv AS tip_sobe, s.status
FROM soba s
JOIN tip_sobe ts ON s.tip_sobe_id = ts.id
WHERE s.status = 'CISCENJE';

-- --------------------------------------------------------------
-- 8. pogled aktivnih rezervacija

CREATE OR REPLACE VIEW view_aktivne_rezervacije AS
SELECT 
    r.id AS rezervacija_id, 
    s.broj AS broj_sobe, 
    g.ime, 
    g.prezime 
FROM rezervacija r
JOIN soba s ON r.soba_id = s.id
JOIN gost g ON r.gost_nositelj_id = g.id
WHERE r.status = 'U_TIJEKU';

-- -------------------------------------------------------
-- 9. pogled dodatne usluge

CREATE OR REPLACE VIEW view_dodatne_usluge AS
SELECT id, naziv, cijena_trenutna 
FROM usluga 
WHERE kategorija_id IN (3, 4); -- 3=Wellness, 4=Ostalo

-- ----------------------------------------------------
-- 10. aktivni kvarovi

CREATE OR REPLACE VIEW view_aktivni_kvarovi AS
SELECT 
    n.id AS nalog_id,
    CONCAT(z.ime, ' ', z.prezime) AS serviser,
    s.broj AS broj_sobe,
    n.soba_id, -- Treba nam ID sobe za akcije (UPDATE)
    n.opis AS opis_kvara,
    n.datum_naloga,
    n.rijeseno
FROM servis_dnevni_nalog n
JOIN zaposlenik z ON n.zaposlenik_id = z.id
JOIN soba s ON n.soba_id = s.id
WHERE n.rijeseno = 0;

-- ------------------------------------------------------------
-- 11. pogled osoblja odrzavanja

CREATE OR REPLACE VIEW view_osoblje_odrzavanja AS
SELECT 
    z.id, 
    z.ime, 
    z.prezime,
    CONCAT(z.ime, ' ', z.prezime) AS puno_ime
FROM zaposlenik z
JOIN odjel o ON z.odjel_id = o.id
WHERE o.naziv = 'Odrzavanje';

-- ---------------------------------------------------
-- 13. pogled status soba boje

CREATE OR REPLACE VIEW view_status_soba_boje AS
SELECT 
    s.id,
    s.broj,
    ts.trenutno_stanje AS stanje,
    CASE 
        WHEN ts.trenutno_stanje = 'ZAUZETA' THEN '#ffcdd2'       -- Crvena
        WHEN ts.trenutno_stanje = 'SLOBODNA' THEN '#c8e6c9'      -- Zelena
        WHEN ts.trenutno_stanje = 'CISCENJE' THEN '#fff9c4'      -- Žuta
        WHEN ts.trenutno_stanje = 'IZVAN_FUNKCIJE' THEN '#e0e0e0' -- Siva
        ELSE '#ffffff'
    END AS hex_boja
FROM soba s

JOIN trenutno_stanje_soba ts ON s.id = ts.soba_id;

-- ------------------------------
-- 14. pogled soba dropdown

CREATE OR REPLACE VIEW view_sve_sobe_dropdown AS
SELECT 
    s.id, 
    s.broj, 
    t.naziv AS tip_sobe, 
    s.status
FROM soba s
JOIN tip_sobe t ON s.tip_sobe_id = t.id
ORDER BY s.broj;


-- -------------------------------------
-- 16. pogled stavke narudzbe

CREATE OR REPLACE VIEW view_stavke_narudzbe AS
SELECT 
    rs.narudzba_id,          
    u.naziv AS naziv_artikla,
    rs.kolicina,
    rs.cijena_u_trenutku AS cijena_jedinicna,
    (rs.kolicina * rs.cijena_u_trenutku) AS ukupno_stavka, 
    rs.status_pripreme
FROM restoran_stavka rs
JOIN usluga u ON rs.usluga_id = u.id;

-- ------------------------------------
-- 17. pogled detalji racuna

CREATE OR REPLACE VIEW view_detalji_racuna AS
SELECT 
    racun_id,
    tip_stavke,
    opis,
    kolicina,
    cijena_jedinicna,
    iznos_ukupno
FROM stavka_racuna;

-- ------------------------------------
-- 18. pogled recepti

CREATE OR REPLACE VIEW view_recepture_detaljno AS
SELECT 
    u.id AS jelo_id,
    u.naziv AS naziv_jela,
    a.naziv AS namirnica,
    n.kolicina_potrosnje,
    a.jedinica_mjere,
    a.nabavna_cijena AS cijena_po_jedinici,
    -- Izračun troška te namirnice u jelu (količina * nabavna cijena)
    ROUND(n.kolicina_potrosnje * a.nabavna_cijena, 2) AS trosak_sastojka
FROM usluga u
JOIN normativ n ON u.id = n.usluga_id
JOIN artikl a ON n.artikl_id = a.id
ORDER BY u.naziv, a.naziv;

-- -------------------------------------------
-- 19. pogled zaposlenici recepcija

CREATE OR REPLACE VIEW view_zaposlenici_recepcija AS
SELECT 
    id, 
    ime, 
    prezime, 
    CONCAT(ime, ' ', prezime) AS puno_ime,
    korisnicko_ime
FROM zaposlenik
WHERE odjel_id = 1; -- 1 = Recepcija

-- -----------------------------------------
-- 20. pogled zaposlenici konobari

CREATE OR REPLACE VIEW view_zaposlenici_konobari AS
SELECT 
    id, 
    ime, 
    prezime, 
    CONCAT(ime, ' ', prezime) AS puno_ime
FROM zaposlenik
WHERE odjel_id = 5; -- 5 = Restoran

-- ------------------------------------
-- 21. pogled zaposlenici domacinstvo

CREATE OR REPLACE VIEW view_zaposlenici_domacinstvo AS
SELECT 
    id, 
    ime, 
    prezime, 
    CONCAT(ime, ' ', prezime) AS puno_ime
FROM zaposlenik
WHERE odjel_id = 2; -- 2 = Domaćinstvo

-- -------------------------------------
-- 22. pogled zaposlenici tehničari

CREATE OR REPLACE VIEW view_zaposlenici_odrzavanje AS
SELECT 
    id, 
    ime, 
    prezime, 
    CONCAT(ime, ' ', prezime) AS puno_ime
FROM zaposlenik
WHERE odjel_id = 3;