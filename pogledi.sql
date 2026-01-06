/*
--POGLEDI
*/
/* Trenutno stanje soba */
	CREATE OR REPLACE VIEW trenutno_stanje_soba AS
	SELECT
		s.id AS soba_id,
		s.broj AS broj_sobe,
		CASE
			WHEN r.id IS NOT NULL THEN 'ZAUZETA'
			ELSE s.status
		END AS trenutno_stanje
	FROM soba s
	JOIN tip_sobe ts ON ts.id = s.tip_sobe_id
	LEFT JOIN rezervacija r
		ON r.soba_id = s.id
		AND CURDATE() BETWEEN r.pocetak_datum AND r.kraj_datum
		AND r.status IN ('POTVRDJENA','U_TIJEKU')
	LEFT JOIN gost g ON g.id = r.gost_nositelj_id;
/* Implementacija pogleda*/
	SELECT * FROM trenutno_stanje_soba;

/*Aktivni gosti u hotelu*/
	CREATE OR REPLACE VIEW aktivni_gosti_u_hotelu AS
	SELECT
		g.id AS gost_id,
		g.ime,
		g.prezime,
		g.vip_status,
		
		r.id AS rezervacija_id,
		r.status AS status_rezervacije,

		s.id AS soba_id,
		s.broj AS broj_sobe

	FROM rezervacija r
	JOIN rezervacija_gost rg ON rg.rezervacija_id = r.id
	JOIN gost g ON g.id = rg.gost_id
	JOIN soba s ON s.id = r.soba_id
	JOIN tip_sobe ts ON ts.id = s.tip_sobe_id
	JOIN zaposlenik z ON z.id = r.zaposlenik_id
	JOIN odjel o ON o.id = z.odjel_id
	JOIN vrsta_dokumenta vd ON vd.id = g.vrsta_dokumenta_id

	WHERE
		CURDATE() BETWEEN r.pocetak_datum AND r.kraj_datum
		AND r.status IN ('POTVRDJENA','U_TIJEKU')
		AND r.vrijeme_check_out IS NULL;
/*Implementacija za aktivne goste*/
	SELECT * FROM aktivni_gosti_u_hotelu;

/*Racun po rezervaciji*/
	CREATE OR REPLACE VIEW racun_po_rezervaciji AS
	SELECT
		r.id AS rezervacija_id,
		r.status AS status_rezervacije,

		g.id AS gost_id,
		CONCAT(g.ime, ' ', g.prezime) AS Ime_Prezime_Gosta,

		s.broj AS broj_sobe,

		COUNT(DISTINCT ra.id) AS broj_racuna,
		SUM(sr.iznos_ukupno) AS ukupni_iznos

	FROM rezervacija r
	JOIN gost g ON g.id = r.gost_nositelj_id
	JOIN soba s ON s.id = r.soba_id

	LEFT JOIN racun ra ON ra.rezervacija_id = r.id
	LEFT JOIN stavka_racuna sr ON sr.racun_id = ra.id

	GROUP BY
		r.id,
		r.pocetak_datum,
		r.kraj_datum,
		r.status,
		g.id,
		s.broj;
/*Implementacija racuna po rezervaciji*/
	SELECT * FROM racun_po_rezervaciji;
/*Low stock alert */
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
	WHERE a.stanje_zaliha <= 5;
	SELECT * FROM low_stock_alert;

/*Gosti sa najvećom potrošnjom*/
	CREATE OR REPLACE VIEW najbolji_gosti_potrosnja AS
	SELECT
		g.id AS gost_id,
		CONCAT(g.ime, ' ', g.prezime) AS gost,
		g.vip_status,
		COUNT(DISTINCT r.id) AS broj_rezervacija,
		SUM(sr.iznos_ukupno) AS ukupna_potrosnja
	FROM gost g
	JOIN rezervacija r ON r.gost_nositelj_id = g.id
	JOIN racun ra ON ra.rezervacija_id = r.id
	JOIN stavka_racuna sr ON sr.racun_id = ra.id
	WHERE r.status = 'ZAVRSENA'
	GROUP BY g.id, g.vip_status;

/*Implementacija za top 10 najvećih potrošača*/
	SELECT *
	FROM najbolji_gosti_potrosnja
	ORDER BY ukupna_potrosnja DESC
	LIMIT 10;

/*Neplaćeni računi*/
CREATE OR REPLACE VIEW neplaceni_racuni AS
	SELECT
		ra.id AS racun_id,
		ra.rezervacija_id,
		ra.datum_izdavanja,
		ra.nacin_placanja,
		SUM(sr.iznos_ukupno) AS iznos_za_naplatu,
		CONCAT(g.ime, ' ', g.prezime) AS gost,
		s.broj AS broj_sobe
	FROM racun ra
	JOIN rezervacija r ON r.id = ra.rezervacija_id
	JOIN gost g ON g.id = r.gost_nositelj_id
	JOIN soba s ON s.id = r.soba_id
	LEFT JOIN stavka_racuna sr ON sr.racun_id = ra.id
	WHERE ra.iznos_ukupno IS NULL
	GROUP BY
		ra.id,
		ra.rezervacija_id,
		ra.nacin_placanja,
		g.ime,
		g.prezime,
		s.broj;
/*Implementacija neplaceni racuni*/
	SELECT * FROM neplaceni_racuni;

/*Ocjene*/
	CREATE OR REPLACE VIEW ocjene_hotela AS
	SELECT
		COUNT(r.id) AS broj_recenzija,
		ROUND(AVG(r.ocjena), 2) AS prosjecna_ocjena,
		MIN(r.ocjena) AS najniza_ocjena,
		MAX(r.ocjena) AS najvisa_ocjena
	FROM recenzija r;
/*Implementacija view-a*/
	SELECT * FROM ocjene_hotela;

/*Sve recenzije*/
	CREATE OR REPLACE VIEW sve_recenzije AS
	SELECT
		rec.id AS recenzija_id,
		rec.ocjena,
		rec.komentar,
		rec.datum_recenzije,

		r.id AS rezervacija_id,

		g.id AS gost_id,
		CONCAT(g.ime, ' ', g.prezime) AS gost,
		g.vip_status

	FROM recenzija rec
	JOIN rezervacija r ON r.id = rec.rezervacija_id
	JOIN gost g ON g.id = r.gost_nositelj_id
	JOIN soba s ON s.id = r.soba_id
	JOIN tip_sobe ts ON ts.id = s.tip_sobe_id
	ORDER BY rec.datum_recenzije DESC;
/*Implementacija pogleda*/
	SELECT * FROM sve_recenzije;

/*Daily check in check out*/
	CREATE OR REPLACE VIEW checkin_checkout_daily AS
	SELECT
		r.id AS rezervacija_id,
		CONCAT(g.ime, ' ', g.prezime) AS gost,
		g.vip_status,
		s.broj AS broj_sobe,
		r.broj_osoba,
		r.status AS status_rezervacije,
		r.vrijeme_check_in,
		r.vrijeme_check_out,
		CASE
			WHEN r.pocetak_datum = CURDATE() THEN 'CHECK-IN'
			WHEN r.kraj_datum = CURDATE() THEN 'CHECK-OUT'
			ELSE 'BORAVI'
		END AS tip_dnevnog_statusa

	FROM rezervacija r
	JOIN gost g ON g.id = r.gost_nositelj_id
	JOIN soba s ON s.id = r.soba_id
	JOIN tip_sobe ts ON ts.id = s.tip_sobe_id
	WHERE CURDATE() BETWEEN r.pocetak_datum AND r.kraj_datum
	   OR r.pocetak_datum = CURDATE()
	   OR r.kraj_datum = CURDATE()
	ORDER BY tip_dnevnog_statusa, r.pocetak_datum, s.broj;
/*Pogled*/
	SELECT * FROM checkin_checkout_daily;
    
/*Stol i narduzbe za taj stol*/
CREATE OR REPLACE VIEW stol_narudzba AS
SELECT
    rs.id AS stol_id,
    rs.broj_stola,
    rs.broj_mjesta,
    rs.lokacija,

    rn.id AS narudzba_id,
    CONCAT(z.ime, ' ', z.prezime) AS konobar,
    rn.status AS status_narudzbe

FROM restoran_stol rs
LEFT JOIN restoran_narudzba rn ON rn.restoran_stol_id = rs.id
LEFT JOIN zaposlenik z ON z.id = rn.zaposlenik_id
ORDER BY rs.broj_stola, rn.datum_otvaranja;
/*pogled*/
SELECT * FROM stol_narudzba;

/*Evidencija cijena soba*/
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
/*Koristi pogled*/
SELECT * FROM evidencija_cijena_soba;