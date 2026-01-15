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
