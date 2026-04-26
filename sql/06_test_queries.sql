USE novi_projekt;

-- =============================================
-- TEST QUERIES extracted from original SQL files
-- These are NOT needed for the application to run.
-- They were used during development to verify triggers, procedures, functions, and views.
-- =============================================


-- ======================
-- From funkcije.sql
-- ======================

-- SELECT izracunaj_cijenu_smjestaja(1, '2026-12-12', '2026-12-20') AS cijena_boravka; -- zimska cijena single sobe
-- SELECT izracunaj_cijenu_smjestaja(1, '2026-7-12', '2026-7-20') AS cijena_boravka; -- ljetna cijena single sobe

select usluga.id, pdv_koji_moramo_platiti(usluga.id) as owed_VAT
from usluga;

-- select pdv_za_godinu(2026) as pdv_za_2026;

-- Treba vratiti 0 jer se siječe sa starom rezervacijom
SELECT provjeri_dostupnost_sobe(2, '2026-01-16', '2026-01-19') AS Mogu_Li_Rezervirati;

SELECT soba.id, soba.broj, soba.kapacitet_osoba, provjeri_dostupnost_sobe(soba.id, '2026-01-16', '2026-01-19') FROM soba;

-- Test data for capacity check (reservations for 4-person rooms)
INSERT INTO rezervacija (id, gost_nositelj_id, zaposlenik_id, soba_id, promocija_id, datum_rezervacije, pocetak_datum, kraj_datum, vrijeme_check_in, vrijeme_check_out, broj_osoba, status, napomena) VALUES
(41, 1, 1, 36, NULL, '2026-05-01 10:00:00', '2026-08-01', '2026-08-05', NULL, NULL, 4, 'POTVRDJENA', 'Test Data - Room 36'),
(42, 2, 1, 37, NULL, '2026-05-01 10:05:00', '2026-07-28', '2026-08-03', NULL, NULL, 4, 'POTVRDJENA', 'Test Data - Room 37'),
(43, 3, 2, 40, NULL, '2026-05-01 10:10:00', '2026-07-20', '2026-08-10', NULL, NULL, 4, 'POTVRDJENA', 'Test Data - Room 40'),
(44, 4, 2, 41, NULL, '2026-05-01 10:15:00', '2026-08-01', '2026-08-03', NULL, NULL, 4, 'POTVRDJENA', 'Test Data - Room 41'),
(45, 5, 3, 43, NULL, '2026-05-01 10:20:00', '2026-07-31', '2026-08-04', NULL, NULL, 4, 'POTVRDJENA', 'Test Data - Room 43'),
(46, 6, 3, 45, NULL, '2026-05-01 10:25:00', '2026-08-01', '2026-08-03', NULL, NULL, 4, 'POTVRDJENA', 'Test Data - Room 45'),
(47, 1, 4, 46, NULL, '2026-05-01 10:30:00', '2026-06-01', '2026-09-01', NULL, NULL, 4, 'POTVRDJENA', 'Test Data - Room 46'),
(48, 2, 4, 50, NULL, '2026-05-01 10:35:00', '2026-07-30', '2026-08-05', NULL, NULL, 4, 'POTVRDJENA', 'Test Data - Room 50');

-- 02.08 je zauzeta soba za 4 osobe sa ovim testnim podacima
SELECT provjeri_dostupnost_kapaciteta(4, '2026-08-01', '2026-08-03') AS Mogu_Li_Rezervirati_Kapacitet;

-- select dohvati_ukupan_iznos_rezervacije(1) as ukupno_za_rezervaciju_1;


-- ======================
-- From pogledi.sql
-- ======================

SELECT * FROM trenutno_stanje_soba;
SELECT * FROM racun_po_rezervaciji;
SELECT * FROM low_stock_alert;
SELECT * FROM najbolji_gosti_potrosnja LIMIT 10;
SELECT * FROM evidencija_cijena_soba;
SELECT *FROM neplaceni_racuni;


-- ======================
-- From proc_view_za_recenzije.sql
-- ======================

SELECT * FROM pregled_recenzija_za_menadzera;

CALL odgovori_na_recenziju(10, 'Pozvali smo ekipu za deratizaciju, a sobarici smo povećali plaću zbog legendarnog humora.');


-- ======================
-- From procedure.sql
-- ======================

CALL otkazi_rezervaciju(40);
SELECT * FROM rezervacija WHERE id = 40;
CALL otkazi_rezervaciju(1);

-- UNOS DUMMY PODATAKA - PREBACITI U GLAVNI INSERT PRIJE ZAVRŠNOG PROIZVODA
INSERT INTO log_rezervacije (rezervacija_id, stari_status, novi_status, vrijeme_promjene, korisnik_db) VALUES
(1, 'NOVA', 'POTVRDJENA', '2023-01-15 10:00:00', 'stari_admin'),
(2, 'POTVRDJENA', 'OTKAZANA', '2023-05-20 14:30:00', 'stari_admin'),
(3, 'U_TIJEKU', 'ZAVRSENA', '2023-08-01 09:00:00', 'stari_admin');

-- ISTO PREBACITI U GLAVNI DDL
SET SQL_SAFE_UPDATES = 0;

SELECT * FROM log_rezervacije ORDER BY vrijeme_promjene ASC;

SET @broj_obrisanih = 0;
CALL ocisti_stare_log_rez(90, @broj_obrisanih);
SELECT @broj_obrisanih AS 'Ukupno trajno obrisanih zapisa';

CALL sp_ociscena_soba(101);

-- CALL koji radi sa postojećim insertima iz tvog koda
CALL sp_dodaj_gosta_na_rezervaciju(1, 1);  -- rezervacija_id = 1, gost_id = 1

-- CALL koji radi sa postojećim insertima
CALL sp_primijeni_promociju(1, 1);  -- rezervacija_id = 1, promocija_id = 1

CALL dohvati_slobodne_sobe(3, '2026-08-01', '2026-08-03');


-- ======================
-- From procedure_1.sql
-- ======================

-- (No standalone test queries beyond what's covered above)


-- ======================
-- From okidaci.sql
-- ======================

-- 1. Test: dupla rezervacija sobe
SELECT
    r.id AS ID_Rezervacije,
    s.broj AS Broj_Sobe,
    CONCAT(g.ime, ' ', g.prezime) AS Gost,
	CONCAT(DATE_FORMAT(r.pocetak_datum, '%d.%m.'), '-', DATE_FORMAT(r.kraj_datum, '%d.%m.%Y')) AS Termin,
	r.status
FROM rezervacija r
JOIN soba s ON r.soba_id = s.id
JOIN gost g ON r.gost_nositelj_id = g.id
WHERE r.status IN ('POTVRDJENA', 'U_TIJEKU');

INSERT INTO rezervacija
(gost_nositelj_id, zaposlenik_id, soba_id, promocija_id, datum_rezervacije, pocetak_datum, kraj_datum, broj_osoba, status, napomena)
VALUES
(1, 1, 16, NULL, NOW(), '2026-12-19', '2026-12-22', 1, 'POTVRDJENA', 'Test test');

-- 2. Test: neaktivna promocija
INSERT INTO promocija(id, naziv, kod_kupona, popust_postotak, datum_pocetka, datum_zavrsetka,aktivna) VALUES
(999, 'NEAKTIVNA', 'TESTNA', 10.00, '2025-12-01', '2026-02-28',0);

SELECT
    p.id AS ID_Promo,
    p.naziv AS Naziv_Promocije,
    DATE_FORMAT(p.datum_pocetka, '%d.%m.%Y') AS Vrijedi_Od,
    DATE_FORMAT(p.datum_zavrsetka, '%d.%m.%Y') AS Vrijedi_Do,
    p.aktivna AS Aktivna,

    IF(p.aktivna = 1, 'Da', 'Ne') AS Aktivna,

    COUNT(r.id) AS Ukupno_Iskoristeno,

    GROUP_CONCAT(r.id) AS ID_Rezervacija_Lista
FROM
    promocija p
LEFT JOIN
    rezervacija r ON p.id = r.promocija_id
GROUP BY
    p.id, p.naziv, p.datum_pocetka, p.datum_zavrsetka, p.aktivna
ORDER BY
    p.id;

INSERT INTO rezervacija
(gost_nositelj_id, zaposlenik_id, soba_id, promocija_id, datum_rezervacije, pocetak_datum, kraj_datum, broj_osoba, status, napomena)
VALUES
(1, 1, 7, 999, NOW(), '2026-01-20', '2026-01-22', 2, 'POTVRDJENA', 'Test neaktivna proba');

INSERT INTO rezervacija
(gost_nositelj_id, zaposlenik_id, soba_id, promocija_id, datum_rezervacije, pocetak_datum, kraj_datum, broj_osoba, status, napomena)
VALUES
(1, 1, 7, 1, NOW(), '2026-02-22', '2026-03-01', 2, 'POTVRDJENA', 'Test after');

INSERT INTO rezervacija
(gost_nositelj_id, zaposlenik_id, soba_id, promocija_id, datum_rezervacije, pocetak_datum, kraj_datum, broj_osoba, status, napomena)
VALUES
(1, 1, 7, 3, NOW(), '2026-02-22', '2026-03-05', 2, 'POTVRDJENA', 'Test before');

-- 3. Test: ažuriranje promocije na rezervaciji
SELECT
    r.id AS ID_Rez,
    CONCAT(g.ime, ' ', g.prezime) AS Nositelj,

    DATE_FORMAT(r.pocetak_datum, '%d.%m.%Y') AS Boravak_Od,
    DATE_FORMAT(r.kraj_datum, '%d.%m.%Y') AS Boravak_Do,

    IFNULL(p.naziv, 'Nema promocije') AS Trenutna_Promo

FROM
    rezervacija r
JOIN
    gost g ON r.gost_nositelj_id=g.id
LEFT JOIN
    promocija p ON r.promocija_id=p.id
WHERE
    r.status IN ('POTVRDJENA', 'U_TIJEKU')
ORDER BY
    r.id;

-- neaktvne promocije
UPDATE rezervacija
SET promocija_id =999
WHERE id = 16;
--vremenski nevažeća promocija
UPDATE rezervacija
SET promocija_id = 2
WHERE id =25;

--vremenski nevažeća promocija #2
UPDATE rezervacija
SET promocija_id = 4
WHERE id =38;

-- 4. Test: check-in time
INSERT INTO rezervacija
(gost_nositelj_id, zaposlenik_id, soba_id, promocija_id, datum_rezervacije, pocetak_datum, kraj_datum, vrijeme_check_in, vrijeme_check_out, broj_osoba, status, napomena) VALUES
(5, 1, 48, NULL, '2025-12-20 10:00:00', '2026-01-11', '2026-01-15', '2026-01-11 15:30:00', NULL, 2, 'U_TIJEKU', 'Dummy gost 1 - Već u sobi'),
(6, 2, 49, NULL, '2025-12-25 11:00:00', '2026-01-12', '2026-01-16', '2026-01-12 14:15:00', NULL, 2, 'U_TIJEKU', 'Dummy gost 2 - Upravo stigli');

SELECT
    r.id AS ID_Rez,
    CONCAT(g.ime, ' ', g.prezime) AS Gost,
    DATE_FORMAT(pocetak_datum, '%d.%m.%Y') AS Dolazak,

    IFNULL(
        DATE_FORMAT(vrijeme_check_in, '%H:%i'),
        'Čeka se dolazak'
    ) AS Vrijeme_prijave,
    status
FROM rezervacija r
JOIN gost g ON r.gost_nositelj_id = g.id
WHERE status IN ('POTVRDJENA', 'U_TIJEKU')
ORDER BY r.id
LIMIT  10;

UPDATE rezervacija
SET vrijeme_check_in= '2026-07-19 13:59:59',
    status = 'U_TIJEKU'
WHERE id = 18;

UPDATE rezervacija
SET vrijeme_check_in = '2026-07-19 14:00:01',
    status = 'U_TIJEKU'
WHERE id = 20;

-- 5. Test: log insert
INSERT INTO rezervacija
(gost_nositelj_id, zaposlenik_id, soba_id, promocija_id, datum_rezervacije, pocetak_datum, kraj_datum, broj_osoba, status, napomena)
VALUES
(45, 1, 15, NULL, NOW(), '2026-11-01', '2026-11-05', 1, 'POTVRDJENA', 'Log test');

UPDATE rezervacija
SET kraj_datum = '2026-01-12'
WHERE id = 1;

SELECT
    l.rezervacija_id AS 'ID Rez',
    l.id AS 'ID Log',
    CONCAT(g.ime, ' ', g.prezime) AS 'Nositelj Rezervacije',

    DATE_FORMAT(l.vrijeme_promjene, '%d.%m.%Y %H:%i:%s') AS 'Vrijeme Promjene',

    CONCAT(
        IFNULL(l.stari_status, 'NOVA'),
        '-->',
        l.novi_status
    ) AS 'Tijek Promjene Statusa',

    IF(l.novi_status = 'OTKAZANA', 'Otkazana',
        IF(l.novi_status = 'U_TIJEKU', 'U tijeku',
            CONCAT(DATEDIFF(r.kraj_datum, r.pocetak_datum), ' dana')
        )
    ) AS 'Trajanje Boravka',

   l.korisnik_db AS 'Izvršio Korisnik'

FROM
    log_rezervacije l
JOIN
    rezervacija r ON l.rezervacija_id = r.id
JOIN
    gost g ON r.gost_nositelj_id = g.id
ORDER BY
    l.vrijeme_promjene DESC, l.id DESC
    ;

-- 6. Test: log update
UPDATE rezervacija
SET
    pocetak_datum = '2026-12-24',
    kraj_datum = '2026-12-30',
    soba_id = 20,
    napomena = 'Gost zatražio promjenu termina pa otkazao',
    status = 'OTKAZANA'
WHERE id = 43;

SELECT
    l.rezervacija_id AS 'ID',
    CONCAT(g.ime, ' ', g.prezime) AS 'Gost',

    CONCAT(IFNULL(l.stari_status, 'NOVA'), ' --> ', l.novi_status) AS 'Povijest Promjene Statusa',
    DATE_FORMAT(l.vrijeme_promjene, '%H:%i:%s') AS 'Vrijeme Promjene',

    DATE_FORMAT(r.pocetak_datum, '%d.%m.%Y') AS 'Trenutni Datum Dolaska',
    r.napomena AS 'Trenutna Napomena (Zadnja)'

FROM
    log_rezervacije l
JOIN
    rezervacija r ON l.rezervacija_id = r.id
JOIN
    gost g ON r.gost_nositelj_id = g.id
WHERE
    l.rezervacija_id = 43
ORDER BY
    l.id DESC
LIMIT 1;

-- 7. Test: log delete
INSERT INTO rezervacija
(gost_nositelj_id, zaposlenik_id, soba_id, promocija_id, datum_rezervacije, pocetak_datum, kraj_datum, broj_osoba, status, napomena)
VALUES
(10, 1, 50, NULL, NOW(),'2026-02-01','2027-02-01',1,'POTVRDJENA', 'Gost ostaje godinu dana? Typo?');

SET SQL_SAFE_UPDATES = 1;

DELETE FROM rezervacija
WHERE gost_nositelj_id = 10
  AND napomena LIKE '%Typo%';

SELECT
    l.id AS 'ID Log',
    l.rezervacija_id AS 'ID Obrisane Rezervacije',

    DATE_FORMAT(l.vrijeme_promjene, '%d.%m.%Y %H:%i') AS 'Vrijeme brisanja',

    CONCAT(l.stari_status, ' --> ', l.novi_status) AS 'Status promjena',

    IFNULL(CONCAT(g.ime, ' ', g.prezime), 'Podaci trajno uklonjeni') AS 'Originalni Nositelj',

    l.korisnik_db AS 'Obrisao korisnik',

	CONCAT(TIMESTAMPDIFF(MINUTE, l.vrijeme_promjene, NOW()), ' min') AS 'Proteklo od brisanja'

FROM
    log_rezervacije l

LEFT JOIN
    rezervacija r ON l.rezervacija_id = r.id
LEFT JOIN
    gost g ON r.gost_nositelj_id = g.id
WHERE
    l.novi_status = 'OBRISANO'
ORDER BY
    l.vrijeme_promjene DESC;

-- 8. Test: besplatno ciscenje trigger
INSERT INTO stavka_racuna (racun_id, usluga_id, tip_stavke, opis, kolicina, cijena_jedinicna, iznos_ukupno)
VALUES (1, 31, 'USLUGA', 'Čišćenje redovno', 1, 30.00, 30.00);

INSERT INTO stavka_racuna (racun_id, usluga_id, tip_stavke, opis, kolicina, cijena_jedinicna, iznos_ukupno)
VALUES (7, 31, 'USLUGA', 'Čišćenje redovno', 1, 30.00, 30.00);

-- Ažuriranje greške iz inicijalnog inserta
UPDATE rezervacija
SET kraj_datum = '2026-01-12'
WHERE id = 1;

SELECT
    CONCAT(g.ime, ' ', g.prezime) AS gost_nositelj,
    r.id AS br_racuna,
    DATE_FORMAT(rez.pocetak_datum, '%d.%m.%Y') AS check_in,
    DATE_FORMAT(rez.kraj_datum, '%d.%m.%Y') AS check_out,
    DATEDIFF(rez.kraj_datum, rez.pocetak_datum) AS trajanje_nocenja,
    sr.opis AS stavka_opis,
    CONCAT(FORMAT(u.cijena_trenutna, 2), ' €') AS redovna_cijena,
    CONCAT(FORMAT(sr.cijena_jedinicna, 2), ' €') AS naplacena_cijena,

    IF(DATEDIFF(rez.kraj_datum, rez.pocetak_datum) > 3 AND sr.cijena_jedinicna = 0,
       'Gratis',

       IF(DATEDIFF(rez.kraj_datum, rez.pocetak_datum) <= 3 AND sr.cijena_jedinicna > 0,
          'Naplaćeno',

          'GREŠKA: Trigger ne šljaka!'
       )
    ) AS status

FROM stavka_racuna sr
JOIN racun r ON sr.racun_id = r.id
JOIN rezervacija rez ON r.rezervacija_id = rez.id
JOIN gost g ON rez.gost_nositelj_id = g.id
JOIN usluga u ON sr.usluga_id = u.id
WHERE u.naziv = 'Završno čišćenje'
ORDER BY r.id;

-- Test: kreiraj_racun_nakon_rezervacije trigger
INSERT INTO rezervacija
(gost_nositelj_id, zaposlenik_id, soba_id, promocija_id, datum_rezervacije,
 pocetak_datum, kraj_datum, vrijeme_check_in, vrijeme_check_out, broj_osoba, status, napomena)
VALUES
-- ZAVRSENA (imaju check-in/out)
(1, 1,  1,  NULL,'2026-01-02 09:15:00','2027-01-10','2027-01-12',NULL,NULL,1,'POTVRDJENA','Poslovni boravak');
