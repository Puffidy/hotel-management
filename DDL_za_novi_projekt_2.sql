DROP DATABASE IF EXISTS novi_projekt;
CREATE DATABASE IF NOT EXISTS novi_projekt;
USE novi_projekt;

/*
-- 1. GEOGRAFIJA I ŠIFRARNICI
*/

-- 1. DRZAVA
CREATE TABLE drzava (
    id INT AUTO_INCREMENT PRIMARY KEY,
    naziv VARCHAR(80) NOT NULL,
    iso_kod CHAR(3) UNIQUE
);

-- 2. GRAD
CREATE TABLE grad (
    id INT AUTO_INCREMENT PRIMARY KEY,
    naziv VARCHAR(80) NOT NULL,
    drzava_id INT NOT NULL,
    CONSTRAINT fk_grad_drzava FOREIGN KEY (drzava_id) REFERENCES drzava(id)
);

-- 3. VRSTA_DOKUMENTA
CREATE TABLE vrsta_dokumenta (
    id INT AUTO_INCREMENT PRIMARY KEY,
    naziv VARCHAR(50) NOT NULL
);


-- status gosta
CREATE TABLE status_gosta (
	id INT AUTO_INCREMENT PRIMARY KEY,
    naziv VARCHAR(50) NOT NULL UNIQUE,
    donji_prag_potrosnje DECIMAL (12, 2) NOT NULL DEFAULT 0.00,
    opis TEXT
);

INSERT INTO status_gosta (naziv, donji_prag_potrosnje, opis) VALUES ('Osnovni', 0.00, 'Pocetni satus');


/*
-- 2. ORGANIZACIJA I LJUDI
*/

-- 4. ODJEL
CREATE TABLE odjel (
    id INT AUTO_INCREMENT PRIMARY KEY,
    naziv VARCHAR(50) NOT NULL,
    tel_kontakt VARCHAR(20),
    lokalni INT
);

-- 4.a KATEGORIJE ZAPOSLENIKA 
CREATE TABLE pozicija_zaposlenika (
    id INT AUTO_INCREMENT PRIMARY KEY,
    naziv VARCHAR(50) NOT NULL UNIQUE,
    razina_privilegija INT
);

-- 5. ZAPOSLENIK
CREATE TABLE zaposlenik (
    id INT AUTO_INCREMENT PRIMARY KEY,
    odjel_id INT NOT NULL,
    ime VARCHAR(50) NOT NULL,
    prezime VARCHAR(50) NOT NULL,
	pozicija_id INT NOT NULL,
    datum_zaposlenja TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    tel_kontakt VARCHAR(20),
    email VARCHAR(80),
    korisnicko_ime VARCHAR(30) UNIQUE, 
    lozinka_hash VARCHAR(255), 
    CONSTRAINT fk_zaposlenik_odjel FOREIGN KEY (odjel_id) REFERENCES odjel(id),
	CONSTRAINT fk_zaposlenik_pozicija FOREIGN KEY (pozicija_id) REFERENCES pozicija_zaposlenika(id)
);

-- 6. GOST
CREATE TABLE gost (
    id INT AUTO_INCREMENT PRIMARY KEY,
    ime VARCHAR(50) NOT NULL,
    prezime VARCHAR(50) NOT NULL,
    vrsta_dokumenta_id INT NOT NULL,
    broj_dokumenta VARCHAR(30) NOT NULL,
    prebivaliste_grad_id INT NOT NULL,
    prebivaliste_adresa VARCHAR(100) NOT NULL,
    datum_rodjenja DATE,
    drzavljanstvo_id INT NOT NULL,
    status_id INT NOT NULL DEFAULT 1,
    ukupna_potrosnja_cache DECIMAL(12,2) NOT NULL DEFAULT 0.00,
	vip_status BOOLEAN DEFAULT 0,
    
    CONSTRAINT fk_gost_vrsta_dok FOREIGN KEY (vrsta_dokumenta_id) REFERENCES vrsta_dokumenta(id),
    CONSTRAINT fk_gost_drzavljanstvo FOREIGN KEY (drzavljanstvo_id) REFERENCES drzava(id),
    CONSTRAINT fk_gost_preb_grad FOREIGN KEY (prebivaliste_grad_id) REFERENCES grad(id),
    CONSTRAINT fk_gost_status FOREIGN KEY (status_id) REFERENCES status_gosta(id),

    UNIQUE (vrsta_dokumenta_id, broj_dokumenta),
    
    INDEX idx_gost_potrosnja (ukupna_potrosnja_cache DESC)
);



/*
-- 3. SMJEŠTAJNI KAPACITETI
*/

-- 7. TIP_SOBA
CREATE TABLE tip_sobe (
    id INT AUTO_INCREMENT PRIMARY KEY,
    naziv VARCHAR(50) NOT NULL,
    opis TEXT,
    standardni_kapacitet INT NOT NULL
);

-- 8. SOBA
CREATE TABLE soba (
    id INT AUTO_INCREMENT PRIMARY KEY,
    broj INT NOT NULL UNIQUE,
    tip_sobe_id INT NOT NULL,
    kapacitet_osoba INT NOT NULL,
    kat INT NOT NULL,
    minibar BOOLEAN NOT NULL DEFAULT 0,
    balkon BOOLEAN NOT NULL DEFAULT 0,
    status VARCHAR(20) NOT NULL DEFAULT 'SLOBODNA',
    CONSTRAINT chk_soba_status CHECK (status IN ('SLOBODNA','ZAUZETA','IZVAN_FUNKCIJE', 'CISCENJE')),
    CONSTRAINT fk_soba_tip FOREIGN KEY (tip_sobe_id) REFERENCES tip_sobe(id)
);

-- 9. CJENIK_SOBA
CREATE TABLE cjenik_soba (
    id INT AUTO_INCREMENT PRIMARY KEY,
    tip_sobe_id INT NOT NULL,
    datum_od DATE NOT NULL,
    datum_do DATE NOT NULL,
    cijena_nocenja NUMERIC(10,2) NOT NULL,
    boravisna_pristojba_po_osobi NUMERIC(10,2) NOT NULL,
    aktivan BOOLEAN NOT NULL DEFAULT 1,
    CONSTRAINT fk_cjenik_soba FOREIGN KEY (tip_sobe_id) REFERENCES tip_sobe(id)
);

/*
-- 4. USLUGE, RESTORAN I SKLADIŠTE
*/

-- 10. KATEGORIJA_USLUGE (Hrana, Piće, Wellness...)
CREATE TABLE kategorija_usluge (
    id INT AUTO_INCREMENT PRIMARY KEY,
    naziv VARCHAR(50) NOT NULL
);

-- 11. USLUGA 
CREATE TABLE usluga (
    id INT AUTO_INCREMENT PRIMARY KEY,
    kategorija_id INT NULL, -- Link na kategoriju
    naziv VARCHAR(50) NOT NULL,
    opis TEXT,
    jedinica_mjere VARCHAR(20) DEFAULT 'kom',
    cijena_trenutna NUMERIC(10,2) NOT NULL DEFAULT 0.00,
    CONSTRAINT fk_usluga_kat FOREIGN KEY (kategorija_id) REFERENCES kategorija_usluge(id)
);

-- 12. ARTIKL
CREATE TABLE artikl (
    id INT AUTO_INCREMENT PRIMARY KEY,
    naziv VARCHAR(50) NOT NULL,
    stanje_zaliha DECIMAL(10,2) DEFAULT 0,
    jedinica_mjere VARCHAR(10), 
    nabavna_cijena DECIMAL(10,2)
);

-- 13. NORMATIV 
CREATE TABLE normativ (
    usluga_id INT NOT NULL,
    artikl_id INT NOT NULL,
    kolicina_potrosnje DECIMAL(10,4) NOT NULL,
    PRIMARY KEY (usluga_id, artikl_id),
    CONSTRAINT fk_norm_usluga FOREIGN KEY (usluga_id) REFERENCES usluga(id),
    CONSTRAINT fk_norm_artikl FOREIGN KEY (artikl_id) REFERENCES artikl(id)
);

-- 14. RESTORAN_STOL 
CREATE TABLE restoran_stol (
    id INT AUTO_INCREMENT PRIMARY KEY,
    broj_stola INT NOT NULL UNIQUE,
    broj_mjesta INT NOT NULL,
    lokacija VARCHAR(50)
);

/*
-- 5. REZERVACIJE I MARKETING
*/

-- 15. PROMOCIJA 
CREATE TABLE promocija (
    id INT  PRIMARY KEY,
    naziv VARCHAR(50) NOT NULL, 
    kod_kupona VARCHAR(20) UNIQUE,
    popust_postotak DECIMAL(5,2),
    datum_pocetka DATE,
    datum_zavrsetka DATE,
    aktivna BOOLEAN DEFAULT 1
);

-- 16. REZERVACIJA 
CREATE TABLE rezervacija (
    id INT AUTO_INCREMENT PRIMARY KEY,
    gost_nositelj_id INT NOT NULL,
    zaposlenik_id INT NOT NULL,
    soba_id INT NOT NULL,
    promocija_id INT NULL, 
    
    datum_rezervacije TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    pocetak_datum DATE NOT NULL, 
    kraj_datum DATE NOT NULL,
    
    vrijeme_check_in DATETIME NULL,  
    vrijeme_check_out DATETIME NULL,
    
    broj_osoba INT NOT NULL,
    status VARCHAR(20) NOT NULL DEFAULT 'POTVRDJENA',
    napomena TEXT,
    
    CONSTRAINT chk_rezervacija_status CHECK (status IN ('POTVRDJENA','OTKAZANA','U_TIJEKU','ZAVRSENA')),
    CONSTRAINT fk_rez_gost FOREIGN KEY (gost_nositelj_id) REFERENCES gost(id),
    CONSTRAINT fk_rez_zaposlenik FOREIGN KEY (zaposlenik_id) REFERENCES zaposlenik(id),
    CONSTRAINT fk_rez_soba FOREIGN KEY (soba_id) REFERENCES soba(id),
    CONSTRAINT fk_rez_promo FOREIGN KEY (promocija_id) REFERENCES promocija(id)
);

-- 17. RESTORAN_NARUDZBA 
CREATE TABLE restoran_narudzba (
    id INT AUTO_INCREMENT PRIMARY KEY,
    zaposlenik_id INT NOT NULL, 
    restoran_stol_id INT NOT NULL,
    datum_otvaranja TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    datum_zatvaranja TIMESTAMP NULL,
    status VARCHAR(20) DEFAULT 'OTVORENA',
    
    CONSTRAINT fk_rest_konobar FOREIGN KEY (zaposlenik_id) REFERENCES zaposlenik(id),
    CONSTRAINT fk_rest_stol FOREIGN KEY (restoran_stol_id) REFERENCES restoran_stol(id)

);

-- 18. RESTORAN_STAVKA
CREATE TABLE restoran_stavka (
    id INT AUTO_INCREMENT PRIMARY KEY,
    narudzba_id INT NOT NULL,
    usluga_id INT NOT NULL,
    kolicina INT NOT NULL DEFAULT 1,
    cijena_u_trenutku NUMERIC(10,2) NOT NULL,
    status_pripreme VARCHAR(20) DEFAULT 'NARUCENO', 
    
    CONSTRAINT fk_rest_stavka_nar FOREIGN KEY (narudzba_id) REFERENCES restoran_narudzba(id),
    CONSTRAINT fk_rest_stavka_usl FOREIGN KEY (usluga_id) REFERENCES usluga(id),

    CONSTRAINT chk_rest_kolicina CHECK (kolicina > 0),
    CONSTRAINT chk_rest_cijena CHECK (cijena_u_trenutku >= 0)
);

-- 19. REZERVACIJA_GOST 
CREATE TABLE rezervacija_gost (
    id INT AUTO_INCREMENT PRIMARY KEY,
    rezervacija_id INT NOT NULL,
    gost_id INT NOT NULL,
    uloga VARCHAR(20) DEFAULT 'GOST',
    CONSTRAINT fk_rezgost_rez FOREIGN KEY (rezervacija_id) REFERENCES rezervacija(id),
    CONSTRAINT fk_rezgost_gost FOREIGN KEY (gost_id) REFERENCES gost(id),
    UNIQUE (rezervacija_id, gost_id)
);

-- 20. LOG_REZERVACIJE 
CREATE TABLE log_rezervacije (
    id INT AUTO_INCREMENT PRIMARY KEY,
    rezervacija_id INT NOT NULL,
    stari_status VARCHAR(20),
    novi_status VARCHAR(20),
    vrijeme_promjene TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    korisnik_db VARCHAR(50),
	CONSTRAINT fk_rezervacija_id FOREIGN KEY (rezervacija_id) REFERENCES rezervacija(id)
);

/*
-- 6. FINANCIJE
*/

-- 21. RACUN
CREATE TABLE racun (
    id INT AUTO_INCREMENT PRIMARY KEY,

    tip_racuna VARCHAR(20) NOT NULL DEFAULT 'HOTEL',
    rezervacija_id INT NULL,
    datum_izdavanja TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    nacin_placanja VARCHAR(20) NOT NULL,
    iznos_ukupno NUMERIC(10,2),
    status_racuna VARCHAR(20) NOT NULL DEFAULT 'OTVOREN',
    napomena TEXT,
    CONSTRAINT fk_racun_rez FOREIGN KEY (rezervacija_id) REFERENCES rezervacija(id),
    CONSTRAINT chk_racun_nacin CHECK (nacin_placanja IN ('GOTOVINA','KARTICA','VIRMANSKI','ONLINE')),
    CONSTRAINT chk_racun_tip CHECK (tip_racuna IN ('HOTEL','RESTORAN')),
    CONSTRAINT chk_racun_status CHECK (status_racuna IN ('OTVOREN', 'PLACENO', 'STORNIRANO'))
);

-- 22. STAVKA_RACUNA
CREATE TABLE stavka_racuna (
    id INT AUTO_INCREMENT PRIMARY KEY,
    racun_id INT NOT NULL,

    usluga_id INT NULL, 
    restoran_stavka_id INT NULL,

    tip_stavke VARCHAR(30) NOT NULL,
    opis VARCHAR(100),
    kolicina INT NOT NULL DEFAULT 1,
    cijena_jedinicna NUMERIC(10,2) NOT NULL,
    iznos_ukupno NUMERIC(10,2) NOT NULL,

    CONSTRAINT chk_stavka_tip CHECK (tip_stavke IN ('NOCENJE','USLUGA','BORAVISNA_PRISTOJBA','OSTALO')),
    CONSTRAINT fk_stavka_racun FOREIGN KEY (racun_id) REFERENCES racun(id),
    CONSTRAINT fk_stavka_usl FOREIGN KEY (usluga_id) REFERENCES usluga(id),

    CONSTRAINT fk_stavka_racuna_rest_stavka
        FOREIGN KEY (restoran_stavka_id) REFERENCES restoran_stavka(id),

    UNIQUE (restoran_stavka_id),
    CONSTRAINT chk_stavka_kolicina CHECK (kolicina > 0),
    CONSTRAINT chk_stavka_iznos CHECK (iznos_ukupno >= 0)
);

/*
-- 7. ODRŽAVANJE I FEEDBACK
*/

-- 23. CISCENJE_DNEVNI_NALOG
CREATE TABLE ciscenje_dnevni_nalog (
    id INT AUTO_INCREMENT PRIMARY KEY,
    zaposlenik_id INT NOT NULL, 
    rezervacija_id INT NOT NULL,
    datum_naloga TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    prijavljena_steta BOOLEAN NOT NULL DEFAULT 0,
    opis_stete TEXT,
    obavljeno BOOLEAN DEFAULT 0,
    CONSTRAINT fk_ciscenje_zapos FOREIGN KEY (zaposlenik_id) REFERENCES zaposlenik(id),
    CONSTRAINT fk_ciscenje_rez FOREIGN KEY (rezervacija_id) REFERENCES rezervacija(id)
);

-- 24. SERVIS_DNEVNI_NALOG
CREATE TABLE servis_dnevni_nalog (
    id INT AUTO_INCREMENT PRIMARY KEY,
    zaposlenik_id INT NOT NULL,
    soba_id INT NOT NULL,
    datum_naloga TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    korisnik_placa BOOLEAN NOT NULL DEFAULT 0,
    opis TEXT,
    rijeseno BOOLEAN DEFAULT 0,
    CONSTRAINT fk_servis_zapos FOREIGN KEY (zaposlenik_id) REFERENCES zaposlenik(id),
    CONSTRAINT fk_servis_soba FOREIGN KEY (soba_id) REFERENCES soba(id)
);

-- 25. RECENZIJA 
CREATE TABLE recenzija (
    id INT AUTO_INCREMENT PRIMARY KEY,
    rezervacija_id INT NOT NULL,
    ocjena INT CHECK (ocjena BETWEEN 1 AND 5),
    komentar TEXT,
    datum_recenzije TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    CONSTRAINT fk_recenzija_rez FOREIGN KEY (rezervacija_id) REFERENCES rezervacija(id)
);

