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

    UNIQUE (restoran_stavka_id)
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


/*
-- 1. GEOGRAFIJA I ŠIFRARNICI
*/

-- 1. DRZAVA
INSERT INTO drzava (id, naziv, iso_kod) VALUES
(1,'Hrvatska','HRV'),
(2,'Bosna i Hercegovina','BIH'),
(3,'Srbija','SRB'),
(4,'Italija','ITA'),
(5,'Njemacka','DEU'),
(6,'Ujedinjeno Kraljevstvo','GBR'),
(7,'Slovenija','SVN'),
(8,'Austrija','AUT'),
(9,'Madjarska','HUN'),
(10,'Crna Gora','MNE'),
(11,'Sjeverna Makedonija','MKD'),
(12,'Albanija','ALB'),
(13,'Grcka','GRC'),
(14,'Francuska','FRA'),
(15,'Spanjolska','ESP'),
(16,'Portugal','PRT'),
(17,'Nizozemska','NLD'),
(18,'Belgija','BEL'),
(19,'Svicarska','CHE'),
(20,'Svedska','SWE'),
(21,'Norveska','NOR'),
(22,'Danska','DNK'),
(23,'Finska','FIN'),
(24,'Irska','IRL'),
(25,'Poljska','POL'),
(26,'Ceska','CZE'),
(27,'Slovacka','SVK'),
(28,'Rumunjska','ROU'),
(29,'Bugarska','BGR'),
(30,'Turska','TUR');



-- 2. GRAD
INSERT INTO grad (naziv, drzava_id) VALUES
-- 1 Hrvatska
('Zagreb',1),('Split',1),
-- 2 Bosna i Hercegovina
('Sarajevo',2),('Mostar',2),
-- 3 Srbija
('Beograd',3),('Novi Sad',3),
-- 4 Italija
('Rim',4),('Milano',4),
-- 5 Njemacka
('Berlin',5),('Muenchen',5),
-- 6 Ujedinjeno Kraljevstvo
('London',6),('Manchester',6),
-- 7 Slovenija
('Ljubljana',7),('Maribor',7),
-- 8 Austrija
('Bec',8),('Salzburg',8),
-- 9 Madjarska
('Budimpesta',9),('Debrecen',9),
-- 10 Crna Gora
('Podgorica',10),('Budva',10),
-- 11 Sjeverna Makedonija
('Skopje',11),('Ohrid',11),
-- 12 Albanija
('Tirana',12),('Drac',12),
-- 13 Grcka
('Atena',13),('Solun',13),
-- 14 Francuska
('Pariz',14),('Lyon',14),
-- 15 Spanjolska
('Madrid',15),('Barcelona',15),
-- 16 Portugal
('Lisabon',16),('Porto',16),
-- 17 Nizozemska
('Amsterdam',17),('Rotterdam',17),
-- 18 Belgija
('Bruxelles',18),('Antwerpen',18),
-- 19 Svicarska
('Zurich',19),('Geneva',19),
-- 20 Svedska
('Stockholm',20),('Goteborg',20),
-- 21 Norveska
('Oslo',21),('Bergen',21),
-- 22 Danska
('Kopenhagen',22),('Aarhus',22),
-- 23 Finska
('Helsinki',23),('Tampere',23),
-- 24 Irska
('Dublin',24),('Cork',24),
-- 25 Poljska
('Varsava',25),('Krakow',25),
-- 26 Ceska
('Prag',26),('Brno',26),
-- 27 Slovacka
('Bratislava',27),('Kosice',27),
-- 28 Rumunjska
('Bukurest',28),('Cluj-Napoca',28),
-- 29 Bugarska
('Sofija',29),('Plovdiv',29),
-- 30 Turska
('Ankara',30),('Istanbul',30);


-- 3. VRSTA_DOKUMENTA
INSERT INTO vrsta_dokumenta (naziv) VALUES
('Osobna iskaznica'), 
('Putovnica'), 
('Vozacka dozvola');

/*
-- 2. ORGANIZACIJA I LJUDI
*/

-- 4. ODJEL
INSERT INTO odjel (id, naziv, tel_kontakt, lokalni) VALUES
(1,'Recepcija','010/100-100',100),
(2,'Domacinstvo','010/100-200',200),
(3,'Odrzavanje','010/100-300',300),
(4,'Uprava','010/100-400',400),
(5,'Restoran i Bar','010/100-500',500);
-- 4.a KATEGORIJE ZAPOSLENIKAA 
INSERT INTO pozicija_zaposlenika (id, naziv, razina_privilegija) VALUES
(1, 'Direktor', 10),
(2, 'Voditelj recepcije', 5),
(3, 'Voditelj odrzavanja', 5),
(4, 'Voditelj financija', 5),
(5, 'Sef kuhinje', 5),
(6, 'Nadzornica domacinstva', 5),
(7, 'Recepcioner', 1),
(8, 'Nocni recepcioner', 1),
(9, 'Agent rezervacija', 1),
(10, 'Sobarica', 1),
(11, 'Pranje i peglaonica', 1),
(12, 'Serviser', 1),
(13, 'Tehnicar', 1),
(14, 'Elektricar', 1),
(15, 'Vodoinstalater', 1),
(16, 'Tehnicar klimatizacije', 1),
(17, 'Racunovodstvo', 1),
(18, 'Administracija', 1),
(19, 'HR referent', 1),
(20, 'Kontroling', 1),
(21, 'Konobar', 1),
(22, 'Barmen', 1),
(23, 'Pomocni kuhar', 1);

INSERT INTO zaposlenik
(id, odjel_id, pozicija_id, ime, prezime, tel_kontakt, korisnicko_ime, lozinka_hash)
VALUES
-- 1 Recepcija
(1,1,7,'Iva','Ivic','099111111','iva.ivic','pass123'),
(2,1,2,'Luka','Lukic','099222222','luka.lukic','admin123'),
(3,1,7,'Maja','Majic','099101010','maja.majic','pass123'),
(4,1,7,'Ivan','Ilic','099101011','ivan.ilic','pass123'),
(5,1,8,'Tea','Teic','099101012','tea.teic','pass123'),
(6,1,9,'Nikola','Ninic','099101013','nikola.ninic','pass123'),

-- 2 Domacinstvo
(7,2,10,'Marija','Maricic','099333333','marija.maricic','pass123'),
(8,2,10,'Nina','Ninic','099333444','nina.ninic','pass123'),
(9,2,10,'Katarina','Katic','099202020','katarina.katic','pass123'),
(10,2,10,'Ivana','Ivanic','099202021','ivana.ivanic','pass123'),
(11,2,6,'Sandra','Sandric','099202022','sandra.sandric','pass123'),
(12,2,11,'Dora','Doric','099202023','dora.doric','pass123'),

-- 3 Tehničko
(13,3,12,'Tomo','Tomic','099444444','tomo.tomic','pass123'),
(14,3,3,'Mario','Marincic','099555555','mario.marincic','pass123'),
(15,3,13,'Stjepan','Stipic','099303030','stjepan.stipic','pass123'),
(16,3,14,'Ante','Antic','099303031','ante.antic','pass123'),
(17,3,15,'Josip','Jovic','099303032','josip.jovic','pass123'),
(18,3,16,'Filip','Filipovic','099303033','filip.filipovic','pass123'),

-- 4 Uprava
(19,4,1,'Ivana','Ivancic','099666666','ivana.ivancic','admin123'),
(20,4,17,'Petra','Petric','099777777','petra.petric','pass123'),
(21,4,4,'Marko','Maric','099404040','marko.maric','pass123'),
(22,4,18,'Lucija','Lucic','099404041','lucija.lucic','pass123'),
(23,4,19,'Ena','Enic','099404042','ena.enic','pass123'),
(24,4,20,'Bruno','Brunic','099404043','bruno.brunic','pass123'),

-- 5 Restoran
(25,5,21,'Marko','Markovic','099888888','marko.markovic','pass123'),
(26,5,5,'Ana','Anic','099999999','ana.anic','pass123'),
(27,5,21,'Karlo','Karlic','099505050','karlo.karlic','pass123'),
(28,5,21,'Lana','Lanic','099505051','lana.lanic','pass123'),
(29,5,22,'Mia','Miic','099505052','mia.miic','pass123'),
(30,5,23,'Dario','Darik','099505053','dario.darik','pass123');

-- 6. GOST
INSERT INTO gost
(id, ime, prezime, vrsta_dokumenta_id, broj_dokumenta, prebivaliste_grad_id, prebivaliste_adresa, datum_rodjenja, drzavljanstvo_id, vip_status)
VALUES
(1,'Ana','Anic',1,'AA12345',1,'Ilica 12','1990-02-15',1,1),
(2,'Ivica','Ivicic',2,'BB22345',2,'Put Mora 5','1988-07-21',1,0),
(3,'Marko','Maric',1,'MM44556',3,'Kvarnerska 7','1995-01-01',1,0),
(4,'Darko','Daric',2,'DD99887',3,'Ulica 1','1989-03-12',2,0),
(5,'Ena','Enic',1,'EE23232',5,'Nemanjina 10','1992-09-10',3,1),
(6,'Filip','Filipic',1,'FF11111',1,'Ilica 88','1993-05-19',1,0),
(7,'Goran','Goric',2,'GG22222',2,'Primorska 6','1985-10-10',1,0),
(8,'Helena','Helnic',1,'HH33333',3,'Trg Europe 2','2000-05-05',1,0),
(9,'Ivan','Ivanovic',1,'II44444',3,'Aleja 9','1987-08-08',2,0),
(10,'Jasna','Jasincic',2,'JJ55555',5,'Centar bb','1991-09-09',3,0),
(11,'Karlo','Karlic',1,'KK66666',1,'Maksimirska 55','1996-04-04',1,0),
(12,'Lana','Lanic',2,'LL77777',4,'Obala 18','1984-12-12',1,0),
(13,'Mirko','Mirkic',1,'MM88888',3,'Korzo 3','1997-06-06',1,0),
(14,'Nemanja','Nemanjovic',1,'NN99999',5,'Bulevar 1','1993-03-03',3,0),
(15,'Zara','Zaric',1,'OO11223',3,'Mejtash 7','1986-02-02',2,0),
(16,'Petar','Petric',2,'PP44556',1,'Savska 77','1994-05-05',1,0),
(17,'Renata','Renatic',1,'RR55667',2,'Katin Put 22','2003-05-05',1,0),
(18,'Sara','Saric',2,'SS66778',3,'Uvala 6','1992-09-15',1,0),
(19,'Tomica','Tomcic',1,'TT77889',5,'Vozdovacka 3','1985-05-17',3,0),
(20,'Klara','Klaric',1,'UU88990',3,'Ferhadija 10','2001-03-03',2,0),
(21,'Vedran','Vedric',2,'VV99001',1,'Tresnjevacka 8','1995-07-07',1,0),
(22,'Zarko','Zarkic',2,'ZZ20202',3,'Susacka 9','1987-04-09',1,0),
(23,'Adrian','Adric',2,'AD30303',7,'Via Roma 2','1999-08-11',4,0),
(24,'Bruno','Brunovic',2,'BR40404',3,'Ilidza 19','1988-02-28',2,0),
(25,'Sandra','Sandric',1,'SA50505',1,'Trnje 3','1994-03-22',1,0),
(26,'Dora','Doric',2,'DO60606',4,'Marjan 13','1998-06-18',1,0),
(27,'Ema','Emic',1,'EM70707',3,'Kastavska 4','2010-10-10',1,0),
(28,'Franjo','Franjcic',2,'FR80808',9,'Prenzlauer 1','1993-12-30',5,0),
(29,'John','Doe',2,'JD90909',11,'Baker Street 15','1980-05-05',6,1),
(30,'Peter','Peterowski',2,'PP73280',12,'Oxford 3','1980-05-05',6,0),
(31,'Tena','Tencic',1,'TE11111',2,'Pulska 1','1992-11-11',1,0),
(32,'Igor','Igorovic',2,'IG22222',2,'Kandlerova 7','1989-04-23',1,0),
(33,'Mate','Matic',1,'MA30001',5,'Stradun 1','1990-01-10',1,0),
(34,'Nika','Nikic',1,'NI30002',2,'Riva 12','1997-03-14',1,0),
(35,'Kristina','Krizic',2,'KR30003',13,'Trg 5','1991-06-20',7,0),
(36,'Boris','Boric',2,'BO30004',17,'Rakoczi 10','1986-09-09',9,0),
(37,'Elena','Elenic',1,'EL30005',15,'Ring 2','1995-12-01',8,0),
(38,'Milan','Milic',2,'MI30006',19,'Obala 4','1983-02-18',10,0),
(39,'Sofija','Sofic',2,'SO30007',21,'Centar 7','1994-07-07',11,0),
(40,'Arben','Arbeni',2,'AR30008',23,'Bulevar 1','1988-08-08',12,0),
(41,'Giorgio','Rossi',2,'GI30009',8,'Corso 9','1987-05-15',4,0),
(42,'Pierre','Dubois',2,'PI30010',27,'Rue 1','1992-10-10',14,0),
(43,'Carlos','Garcia',2,'CA30011',29,'Calle 8','1993-11-11',15,0),
(44,'Joao','Silva',2,'JO30012',31,'Rua 3','1989-04-04',16,0),
(45,'Sven','Svensson',2,'SV30013',39,'Main 2','1996-06-06',20,0),
(46,'Ola','Hansen',2,'OH30014',41,'Gate 5','1985-01-01',21,0),
(47,'Piotr','Kowalski',2,'PK30015',49,'Ulica 2','1991-02-02',25,0),
(48,'Elif','Yilmaz',2,'EY30016',59,'Ataturk 10','1998-09-09',30,0),
(49,'Mia','Mikic',1,'MM30017',4,'Korzo 12','1999-12-12',1,1),
(50,'Ayse','Kaya',2,'AK40002',60,'Istiklal 20','1996-01-16',30,0);

/*
-- 3. SMJEŠTAJNI KAPACITETI
*/

-- 7. TIP_SOBA
INSERT INTO tip_sobe (id, naziv, opis, standardni_kapacitet) VALUES
(1,'Single', 'Jednokrevetna soba', 1),
(2,'Double', 'Dvokrevetna soba (bracni krevet)', 2),
(3,'Twin', 'Dvokrevetna soba (2 odvojena kreveta)', 2),
(4,'Triple', 'Trokrevetna soba', 3),
(5,'Family', 'Obiteljska soba', 4),
(6,'Suite', 'Apartman / suite', 4),
(7,'Junior Suite', 'Manji apartman (junior suite)', 3),
(8,'Deluxe Double', 'Dvokrevetna deluxe soba', 2),
(9,'Superior Double', 'Dvokrevetna superior soba', 2),
(10,'Superior Twin', 'Dvokrevetna superior soba (2 odvojena kreveta)', 2),
(11,'Economy Single', 'Jednokrevetna economy soba', 1),
(12,'Economy Double', 'Dvokrevetna economy soba', 2),
(13,'Quadruple', 'Cetverokrevetna soba', 4),
(14,'Penthouse Suite', 'Najluksuzniji apartman', 4),
(15,'Accessible Double', 'Prilagodjena soba za osobe s invaliditetom', 2),
(16,'Double + Extra Bed', 'Dvokrevetna s pomocnim krevetom', 3),
(17,'Twin + Extra Bed', 'Twin soba s pomocnim krevetom', 3),
(18,'Studio', 'Studio soba s cajnom kuhinjom', 2),
(19,'Executive Suite', 'Apartman za poslovne goste', 4),
(20,'Honeymoon Suite', 'Apartman za mladence', 2);



-- 8. SOBA
INSERT INTO soba (id, broj, tip_sobe_id, kapacitet_osoba, kat, minibar, balkon, status) VALUES
-- 1–15: jeftinije (Single / Economy Single / Economy Double)
(1,101,1,1,1,0,0,'SLOBODNA'), -- SINGLE  
(2,102,1,1,1,0,0,'ZAUZETA'), -- SINGLE
(3,103,11,1,1,0,0,'SLOBODNA'), -- ECONOMY SINGLE
(4,104,11,1,1,0,0,'SLOBODNA'), -- ECONOMY SINGLE
(5,105,12,2,1,0,0,'SLOBODNA'), -- ECONOMY DOUBLE
(6,106,11,1,1,0,0,'CISCENJE'), -- ECONOMY SINGLE
(7,107,12,2,1,0,0,'SLOBODNA'), -- ECONOMY DOUBLE
(8,108,1,1,1,0,0,'SLOBODNA'), -- SINGLE
(9,109,11,1,1,0,0,'SLOBODNA'), -- ECONOMY SINGLE
(10,110,12,2,1,0,0,'ZAUZETA'), -- ECONOMY DOUBLE
(11,111,1,1,1,0,0,'SLOBODNA'), -- SINGLE
(12,112,11,1,1,0,0,'SLOBODNA'), -- ECONOMY SINGLE
(13,113,12,2,1,0,0,'SLOBODNA'), -- ECONOMY DOUBLE
(14,114,1,1,1,0,0,'SLOBODNA'), -- SINGLE
(15,115,11,1,1,0,0,'IZVAN_FUNKCIJE'), -- ECONOMY SINGLE

-- 16–32: standard (Double / Twin / Superior / Deluxe / Studio)
(16,201,2,2,2,1,0,'ZAUZETA'), -- DOUBLE
(17,202,2,2,2,1,0,'SLOBODNA'), -- DOUBLE
(18,203,3,2,2,1,0,'SLOBODNA'), -- TWIN
(19,204,3,2,2,1,0,'SLOBODNA'), -- TWIN
(20,205,9,2,2,1,1,'SLOBODNA'),   -- Superior Double
(21,206,10,2,2,1,1,'ZAUZETA'),    -- Superior Twin
(22,207,8,2,2,1,1,'SLOBODNA'),    -- Deluxe Double
(23,208,2,2,2,1,0,'CISCENJE'), -- DOUBLE
(24,209,3,2,2,1,0,'SLOBODNA'), -- TWIN
(25,210,18,2,2,1,1,'SLOBODNA'),   -- Studio
(26,211,2,2,2,1,0,'SLOBODNA'), -- DOUBLE
(27,212,3,2,2,1,0,'ZAUZETA'), -- TWIN
(28,213,9,2,2,1,1,'SLOBODNA'), -- Superior Double
(29,214,10,2,2,1,1,'SLOBODNA'), -- Superior Twin
(30,215,8,2,2,1,1,'SLOBODNA'), -- DELUXE DOUBLE
(31,216,2,2,2,1,0,'SLOBODNA'), -- DOUBLE
(32,217,3,2,2,1,0,'IZVAN_FUNKCIJE'), -- TWIN

-- 33–42: veće (Triple / Family / Quadruple / Extra bed)
(33,301,4,3,3,1,0,'SLOBODNA'),    -- Triple
(34,302,4,3,3,1,1,'ZAUZETA'), -- Triple
(35,303,4,3,3,1,0,'SLOBODNA'), -- Triple
(36,304,5,4,3,1,1,'SLOBODNA'),    -- Family
(37,305,13,4,3,1,1,'SLOBODNA'),   -- Quadruple
(38,306,16,3,3,1,0,'SLOBODNA'),   -- Double + Extra Bed
(39,307,17,3,3,1,0,'ZAUZETA'),    -- Twin + Extra Bed
(40,308,5,4,3,1,1,'CISCENJE'), -- Family
(41,309,13,4,3,1,1,'SLOBODNA'), -- Quadruple
(42,310,4,3,3,1,0,'SLOBODNA'), -- Triple

-- 43–47: suite (Suite / Junior / Executive)
(43,401,6,4,4,1,1,'SLOBODNA'),    -- Suite
(44,402,7,3,4,1,1,'ZAUZETA'),     -- Junior Suite
(45,403,6,4,4,1,1,'SLOBODNA'),    -- Suite
(46,404,19,4,4,1,1,'SLOBODNA'),   -- Executive Suite
(47,405,7,3,4,1,1,'CISCENJE'),    -- Junior Suite

-- 48–50: luksuz ograničeno (2 Honeymoon, 1 Penthouse)
(48,501,20,2,5,1,1,'SLOBODNA'),   -- Honeymoon Suite
(49,502,20,2,5,1,1,'ZAUZETA'),    -- Honeymoon Suite
(50,503,14,4,5,1,1,'SLOBODNA');   -- Penthouse Suite




-- 9. CJENIK_SOBA
INSERT INTO cjenik_soba (tip_sobe_id, datum_od, datum_do, cijena_nocenja, boravisna_pristojba_po_osobi) VALUES
-- 1 Single
(1, '2026-01-01', '2026-03-31', 55.00, 2.00), -- Zima (početak godine)
(1, '2026-04-01', '2026-09-30', 75.00, 2.00), -- Ljeto
(1, '2026-10-01', '2027-03-31', 55.00, 2.00), -- Zima (kraj godine)

-- 2 Double
(2, '2026-01-01', '2026-03-31', 85.00, 2.00),
(2, '2026-04-01', '2026-09-30', 115.00, 2.00),
(2, '2026-10-01', '2027-03-31', 85.00, 2.00),

-- 3 Twin
(3, '2026-01-01', '2026-03-31', 85.00, 2.00),
(3, '2026-04-01', '2026-09-30', 115.00, 2.00),
(3, '2026-10-01', '2027-03-31', 85.00, 2.00),

-- 4 Triple
(4, '2026-01-01', '2026-03-31', 120.00, 2.00),
(4, '2026-04-01', '2026-09-30', 160.00, 2.00),
(4, '2026-10-01', '2027-03-31', 120.00, 2.00),

-- 5 Family
(5, '2026-01-01', '2026-03-31', 140.00, 2.00),
(5, '2026-04-01', '2026-09-30', 190.00, 2.00),
(5, '2026-10-01', '2027-03-31', 140.00, 2.00),

-- 6 Suite
(6, '2026-01-01', '2026-03-31', 200.00, 2.00),
(6, '2026-04-01', '2026-09-30', 280.00, 2.00),
(6, '2026-10-01', '2027-03-31', 200.00, 2.00),

-- 7 Junior Suite
(7, '2026-01-01', '2026-03-31', 170.00, 2.00),
(7, '2026-04-01', '2026-09-30', 230.00, 2.00),
(7, '2026-10-01', '2027-03-31', 170.00, 2.00),

-- 8 Deluxe Double
(8, '2026-01-01', '2026-03-31', 115.00, 2.00),
(8, '2026-04-01', '2026-09-30', 155.00, 2.00),
(8, '2026-10-01', '2027-03-31', 115.00, 2.00),

-- 9 Superior Double
(9, '2026-01-01', '2026-03-31', 100.00, 2.00),
(9, '2026-04-01', '2026-09-30', 135.00, 2.00),
(9, '2026-10-01', '2027-03-31', 100.00, 2.00),

-- 10 Superior Twin
(10, '2026-01-01', '2026-03-31', 100.00, 2.00),
(10, '2026-04-01', '2026-09-30', 135.00, 2.00),
(10, '2026-10-01', '2027-03-31', 100.00, 2.00),

-- 11 Economy Single
(11, '2026-01-01', '2026-03-31', 45.00, 2.00),
(11, '2026-04-01', '2026-09-30', 60.00, 2.00),
(11, '2026-10-01', '2027-03-31', 45.00, 2.00),

-- 12 Economy Double
(12, '2026-01-01', '2026-03-31', 70.00, 2.00),
(12, '2026-04-01', '2026-09-30', 95.00, 2.00),
(12, '2026-10-01', '2027-03-31', 70.00, 2.00),

-- 13 Quadruple
(13, '2026-01-01', '2026-03-31', 150.00, 2.00),
(13, '2026-04-01', '2026-09-30', 205.00, 2.00),
(13, '2026-10-01', '2027-03-31', 150.00, 2.00),

-- 14 Penthouse Suite
(14, '2026-01-01', '2026-03-31', 350.00, 2.00),
(14, '2026-04-01', '2026-09-30', 480.00, 2.00),
(14, '2026-10-01', '2027-03-31', 350.00, 2.00),

-- 15 Accessible Double
(15, '2026-01-01', '2026-03-31', 90.00, 2.00),
(15, '2026-04-01', '2026-09-30', 120.00, 2.00),
(15, '2026-10-01', '2027-03-31', 90.00, 2.00),

-- 16 Double + Extra Bed
(16, '2026-01-01', '2026-03-31', 110.00, 2.00),
(16, '2026-04-01', '2026-09-30', 145.00, 2.00),
(16, '2026-10-01', '2027-03-31', 110.00, 2.00),

-- 17 Twin + Extra Bed
(17, '2026-01-01', '2026-03-31', 110.00, 2.00),
(17, '2026-04-01', '2026-09-30', 145.00, 2.00),
(17, '2026-10-01', '2027-03-31', 110.00, 2.00),

-- 18 Studio
(18, '2026-01-01', '2026-03-31', 125.00, 2.00),
(18, '2026-04-01', '2026-09-30', 170.00, 2.00),
(18, '2026-10-01', '2027-03-31', 125.00, 2.00),

-- 19 Executive Suite
(19, '2026-01-01', '2026-03-31', 240.00, 2.00),
(19, '2026-04-01', '2026-09-30', 330.00, 2.00),
(19, '2026-10-01', '2027-03-31', 240.00, 2.00),

-- 20 Honeymoon Suite
(20, '2026-01-01', '2026-03-31', 260.00, 2.00),
(20, '2026-04-01', '2026-09-30', 360.00, 2.00),
(20, '2026-10-01', '2027-03-31', 260.00, 2.00);



/*
-- 4. USLUGE, RESTORAN I SKLADIŠTE
*/

-- 10. KATEGORIJA_USLUGE (Hrana, Piće, Wellness...)
INSERT INTO kategorija_usluge (id, naziv) VALUES
(1,'Hrana'),
(2,'Pice'),
(3,'Wellness'),
(4,'Ostalo');

-- 11. USLUGA 
INSERT INTO usluga (id, kategorija_id, naziv, opis, jedinica_mjere, cijena_trenutna) VALUES
-- Hrana
-- Dorucak
(1, 1,'Dorucak/Kontinentalni','2 tost, 1 džem, kava ili čaja i sok.','kom',10.00),
(2, 1,'Dorucak/Američki','2 jaja, kobasica, 0.06kg slanina, 2 tost, kava ili čaj i sok','kom',10.00),
-- Rucak
(3, 1,'Salata/Vegeterijanska','1/4 crveni luk, 0.4kg bijelog graha, 1 avokado, 0.1 rajčica, 0.02kg bosiljka, 1/2 limuna, 0.0225 maslinovog ulja ','kom',7.00),
(4, 1,'Salata/Piletina','0.4kg piletine, 1/4 crveni luk, 0.3kg feta sir, 0.05l maslinovo ulje, 1/2 limuna, 0.02kg peršina','kom',7.00),
(5, 1,'Burger','pecivo, 0.25kg junetine, 1 luk, 1 majoneza, 1 kečap, 1/4 rajčice, 0.025 salata ','kom',12.00),
(6, 1,'Orada s krumpirom','1 orada, 1 mrkva, 0.3kg krumpira, 3 češnjaka, 0.2l bijelog vina, 1 limun, 0.15l maslonovog ulja, 0.4kg peršina','kom',22.00),
(7, 1,'Pizza Margherita','1 tijesto, 1/2 passate, 0.2kg mozzarelle, 0.03 maslinovog ulja, 0.015 bosiljka ','kom',11.00),
  
-- Polupansion
(8, 1,'Polupansion','Dorucak i rucak','dan',25.00),

-- Ostalo/hrana
(9, 1,'Sendvic/Sir','1 pecivo za sendvic, 0.025 salata, 0.015 maslaca, 0.1kg sira','kom',6.50),
(10, 1,'Sendvic/Šunka-sir','1 pecivo za sendvic, 0.025 salata, 0.015 maslaca, 0.1kg sira, 0.1kg šunke','kom',6.50),
(11,1,'Desert','tiramisu','kom',5.50),
-- Pice
(12,2,'Kava','Espresso','kom',2.00),
(13,2,'Cappuccino','Kava s mlijekom','kom',2.50),
(14,2,'Caj menta','Topli caj','kom',2.20),
(15,2,'Sok od narance','0.25l','kom',3.00),
(16,2,'Voda','0.5l','kom',1.80),
(17,2,'Coca Cola','0.25l','kom',3.50),
(18,2,'Pivo','0.33l','kom',4.00),
(19,2,'Vino/Bijelo','0.2l','kom',4.50),
(20,2,'Vino/Crno','0.2l','kom',4.50),
-- Wellness
(21,3,'Spa','Koristenje spa zone','kom',15.00),
(22,3,'Masaza 30 min','Relax masaza','kom',25.00),
(23,3,'Masaza 60 min','Relax masaza','kom',45.00),
(24,3,'Sauna','60 min','kom',10.00),
(25,3,'Jacuzzi','60 min','kom',12.00),
-- Ostalo
(26,4,'Parking','Dnevni parking','dan',5.00),
(27,4,'Najam bicikla','Najam bicikla po danu','dan',7.00),
(28,4,'Najam vozila','Najam vozila po danu','dan',40.00),
(29,4,'Room service','Posluga u sobu','kom',8.00),
(30,4,'Kasni checkout','Checkout nakon standardnog vremena','kom',25.00);

-- 12. ARTIKL
INSERT INTO artikl (id, naziv, stanje_zaliha, jedinica_mjere, nabavna_cijena) VALUES
(1,'Tost kruh',1000,'kom',1.20),
(2,'Dzem',1000,'kom',1.50),
(3,'Kava u zrnu',20,'kg',15.00),
(4,'Caj menta vrecice',1000,'kom',0.10),
(5,'Sok naranca',1000,'kom',1.80),

(6,'Jaja',1000,'kom',0.20),
(7,'Kobasica',250,'kom',0.5),
(8,'Slanina',20,'kg',12.00),

(9,'Crveni luk',30,'kom',1.20),
(10,'Bijeli grah',30,'kg',2.00),
(11,'Avokado',80,'kom',1.30),
(12,'Rajcica',40,'kg',2.00),
(13,'Bosiljak',5,'kg',18.00),
(14,'Limun',120,'kom',0.40),
(15,'Maslinovo ulje',30,'l',6.50),

(16,'Piletina file',30,'kg',7.50),
(17,'Feta sir',20,'kg',9.00),
(18,'Persin',10,'kg',12.00),

(19,'Junetina mljevena',30,'kg',12.00),
(20,'Pecivo burger',200,'kom',0.30),
(21,'Majoneza-paket',1000,'kom',0.1),
(22,'Kecap-paket',1000,'kom',0.1),
(23,'Zelena salata',5,'kg',2.50),

(24,'Orada',40,'kom',6.00),
(25,'Mrkva',50,'kg',1.00),
(26,'Krumpir',80,'kg',0.80),
(27,'Cesnjak',15,'kom',0.3),
(28,'Bijelo vino',250,'l',4.50),
(29,'Crno vino',250,'l',4.50),

(30,'Tijesto za pizzu',120,'kom',0.60),
(31,'Passata',80,'kom',1.10),
(32,'Sir mozzarella',25,'kg',6.00),

(33,'Pecivo za sendvic',250,'kom',0.25),
(34,'Maslac-paket',1000,'kom',0.1),
(35,'Sir Gauda',30,'kg',7.50),
(36,'Sunka',25,'kg',9.50),

(37,'Tiramisu',80,'kom',1.80),

(38,'Mlijeko',120,'l',0.90),
(39,'Voda boca 0.5l',300,'kom',0.25),
(40,'Coca Cola 0.25l',300,'kom',0.50),
(41,'Pivo boca 0.33l',200,'kom',1.10),
(42,'Vino/Bijelo',60,'l',4.00),
(43,'Vino/Crno',60,'l',4.00),
(44,'Čaj-Menta',1000,'kom',0.1),
(45,'Med-paket',1000,'kom',0.1);



-- 13. NORMATIV
INSERT INTO normativ (usluga_id, artikl_id, kolicina_potrosnje) VALUES
-- 1 Dorucak/Kontinentalni: 2 tost, dzem, kava ili caj, sok (aproksimacija: kava + caj + sok)
-- 2 tosta
(1,1,2.00),
-- 1 džem
(1,2,1.00),
-- 1 espresso
(1,3,0.01),
-- 1 sok od narance
(1,5,0.20),

-- 2 Dorucak/Americki: 2 jaja, kobasica, 0.06kg slanina, 2 tost, kava/caj, sok
-- 2 jaja
(2,6,2.00),
-- 1 kobasica
(2,7,1.00),
-- 2 kriške slanine
(2,8,0.06),
-- 2 tosta
(2,1,2.00),
-- 1 espresso
(2,3,0.01),
-- 1 sok od narance
(2,5,0.20),

-- 3 Salata/Vegeterijanska
-- 1/4 crvenog luka
(3,9,0.25),
-- 400 g graha
(3,10,0.40),
-- 1 avokado
(3,11,1.00),
-- 100 g rajčica
(3,12,0.10),
-- 20 grama bosiljka
(3,13,0.02),
-- pola limuna
(3,14,0.50),
-- dvije žlicice maslinovog ulja
(3,15,0.0225),

-- 4 Salata/Piletina
-- 400g piletine
(4,16,0.40),
-- 1/4 crvenog luka
(4,9,0.25),
-- 300g feta sir
(4,17,0.30),
-- 0.05l maslinovog ulja
(4,15,0.05),
-- pola limnuna
(4,14,0.50),
-- 20 grama peršina
(4,18,0.02),

-- 5 Burger
-- 1 pecivo za burger
(5,20,1.00),
-- 250g junetine
(5,19,0.25),
-- 1 crveni luk
(5,9,1.00),
-- 1 paketić majoneze
(5,21,1),
-- 1 paketić kečapa
(5,22,1),
-- 50grama rajčice
(5,12,0.05),
-- dva lista salate
(5,23,0.025),

-- 6 Orada s krumpirom (persin smanjio na 0.04kg jer 0.4kg je previše)
-- 1 orada
(6,24,1.00),
-- 100 grama mrkve
(6,25,0.10),
-- 300 grama krumpira
(6,26,0.30),
-- 3 češnjaka
(6,27,3.00),
-- 2dl bijelog vina
(6,28,0.20),
-- 1 limun
(6,14,1.00),
-- 1.5dl maslinovog ulja
(6,15,0.15),
-- 40 grama peršina
(6,18,0.04),

-- 7 Pizza Margherita
-- 1 tijesto za pizzu
(7,30,1.00),
-- 1/2 passate
(7,31,0.50),
-- 200 grama mozzarelle
(7,32,0.20),
-- 30ml maslinovog ulja
(7,15,0.03),
-- 15 grama bosiljka
(7,13,0.015),

-- 8 Polupansion (Dorucak + rucak) - ovo treba još razradit (riba nije uključena u polupansion)
-- Kontinentalni
(8,1,2.00),
(8,2,1.00),
(8,3,0.01),
(8,5,0.20),
-- 
-- 4 Salata/Piletina
(8,16,0.40),
(8,9,0.25),
(8,17,0.30),
(8,15,0.05),
(8,14,0.50),
(8,18,0.02),


-- 9 Sendvic/Sir
-- Pecivo za sendvic 
(9,33,1.00),
-- dvije fete salate
(9,23,0.025),
-- 1 paketić maslaca
(9,34,1),
-- 100 grama sira gaude
(9,35,0.10),

-- 10 Sendvic/Sunka-sir
-- Pecivo za sendvic
(10,33,1.00),
-- Dvije fete salate
(10,23,0.025),
-- Jedan paketić maslaca
(10,34,1),
-- 100 grama sira gauda
(10,35,0.10),
-- 100 grama šunke
(10,36,0.10),

-- 11 Desert (tiramisu)
(11,37,1.00),

-- 12 Kava (espresso)
-- 10 grama kave
(12,3,0.01),

-- 13 Cappuccino (kava + mlijeko)
-- 10 grama kave
(13,3,0.01),
-- 15dl mlijeka
(13,38,0.15),

-- 14 Caj menta
-- 1/4 limuna
(14,14,0.25),
-- 1 čaj menta
(14,44,1),
-- 1 paket meda
(14,45,1),
  
-- 15 Sok od narance 
(15,5,1),
-- 16 Voda 0.5l
(16,39,1.00),
-- 17 Coca Cola 0.25l
(17,40,1.00),
-- 18 Pivo 0.33l
(18,41,1.00),
-- 19 Vino/Bijelo 0.2l (vino u litrima)
(19,28,0.20),
-- 20 Vino/Crno 0.2l (vino u litrima)
(20,29,0.20);



-- 14. RESTORAN_STOL 
INSERT INTO restoran_stol (id, broj_stola, broj_mjesta, lokacija) VALUES
(1,1,2,'Terasa'),
(2,2,2,'Terasa'),
(3,3,4,'Terasa'),
(4,4,4,'Terasa'),
(5,5,6,'Terasa'),
(6,6,2,'Terasa'),
(7,7,4,'Terasa'),
(8,8,2,'Terasa'),
(9,9,4,'Terasa'),
(10,10,6,'Terasa'),
(11,11,2,'Unutra'),
(12,12,2,'Unutra'),
(13,13,4,'Unutra'),
(14,14,4,'Unutra'),
(15,15,6,'Unutra'),
(16,16,2,'Unutra'),
(17,17,4,'Unutra'),
(18,18,2,'Unutra'),
(19,19,4,'Unutra'),
(20,20,6,'Unutra'),
(21,21,2,'Unutra'),
(22,22,2,'Unutra'),
(23,23,4,'Unutra'),
(24,24,4,'Unutra'),
(25,25,6,'Unutra'),
(26,26,2,'VIP'),
(27,27,4,'VIP'),
(28,28,6,'VIP'),
(29,29,2,'VIP'),
(30,30,4,'VIP');

/*
-- 5. REZERVACIJE I MARKETING i RAČUN
*/
-- DATUM : GODINA/MJEDEC/DAN
-- 15. PROMOCIJA 
INSERT INTO promocija (id, naziv, kod_kupona, popust_postotak, datum_pocetka, datum_zavrsetka) VALUES
(1, 'Zimski popust', 'ZIMA25', 10.00, '2025-12-01', '2026-02-28'),
(2, 'Ljeto rani booking', 'LJETO26', 15.00, '2026-01-01', '2026-03-01'),
(3, 'Business ponuda', 'BUSINESS26', 10.00, '2026-03-01', '2026-05-01'),
(4, 'Obiteljska čarolija', 'FAMILYFUN', 12.00, '2026-04-01', '2026-06-01');

-- 16. REZERVACIJA 
INSERT INTO rezervacija
(id, gost_nositelj_id, zaposlenik_id, soba_id, promocija_id, datum_rezervacije,
 pocetak_datum, kraj_datum, vrijeme_check_in, vrijeme_check_out, broj_osoba, status, napomena)
VALUES
-- ZAVRSENA (imaju check-in/out)
(1,  1, 1,  1,  NULL,'2025-01-02 09:15:00','2026-01-10','2025-01-12','2026-01-10 15:10:00','2026-01-12 10:05:00',1,'ZAVRSENA','Poslovni boravak'),
(2,  2, 1,  2,  NULL,'2026-01-05 12:20:00','2026-01-18','2026-01-20','2026-01-18 14:30:00','2026-01-20 10:10:00',1,'ZAVRSENA',NULL),
(3,  3, 2,  3,  1,   '2026-02-01 10:00:00','2026-02-10','2026-02-13','2026-02-10 15:00:00','2026-02-13 10:00:00',2,'ZAVRSENA','Kupon promo'),
(4,  4, 2,  4,  NULL,'2026-02-12 11:45:00','2026-02-20','2026-02-22','2026-02-20 15:20:00','2026-02-22 10:25:00',2,'ZAVRSENA',NULL),
(5,  5, 3,  5,  NULL,'2026-03-01 08:30:00','2026-03-10','2026-03-12','2026-03-10 14:10:00','2026-03-12 10:00:00',2,'ZAVRSENA','Mirna soba'),
(6,  6, 3,  6,  NULL,'2026-03-05 16:05:00','2026-03-18','2026-03-21','2026-03-18 15:05:00','2026-03-21 10:15:00',1,'ZAVRSENA',NULL),
(7,  7, 4,  7,  NULL,'2026-04-01 09:00:00','2026-04-10','2026-04-14','2026-04-10 15:00:00','2026-04-14 10:00:00',2,'ZAVRSENA','Proljetni odmor'),
(8,  8, 4,  8,  NULL,'2026-04-08 13:00:00','2026-04-22','2026-04-24','2026-04-22 14:45:00','2026-04-24 10:30:00',1,'ZAVRSENA',NULL),
(9,  9, 5,  9,  2,   '2026-05-01 10:10:00','2026-05-10','2026-05-15','2026-05-10 15:10:00','2026-05-15 10:10:00',3,'ZAVRSENA','Promo 2'),
(10,10, 5, 10, NULL,'2026-05-06 12:00:00','2026-05-18','2026-05-20','2026-05-18 15:00:00','2026-05-20 10:00:00',2,'ZAVRSENA',NULL),
(11,11, 6, 11, NULL,'2026-06-01 09:40:00','2026-06-10','2026-06-12','2026-06-10 15:00:00','2026-06-12 10:00:00',2,'ZAVRSENA',NULL),
(12,12, 6, 12, NULL,'2026-06-05 11:10:00','2026-06-20','2026-06-23','2026-06-20 15:10:00','2026-06-23 10:00:00',2,'ZAVRSENA','Pogled na more'),

-- OTKAZANA
(13,13, 1, 13, NULL,'2026-06-10 09:00:00','2026-07-01','2026-07-05',NULL,NULL,1,'OTKAZANA','Otkazano zbog putovanja'),
(14,14, 2, 14, NULL,'2026-06-12 10:20:00','2026-07-10','2026-07-12',NULL,NULL,2,'OTKAZANA',NULL),
(15,15, 3, 15,  1,  '2026-06-15 14:30:00','2026-08-01','2026-08-07',NULL,NULL,2,'OTKAZANA','Kupon istekao'),

-- U_TIJEKU (ima check-in, nema check-out)
(16,16, 1, 16, NULL,'2026-12-01 08:00:00','2026-12-20','2026-12-24','2026-12-20 14:20:00',NULL,1,'U_TIJEKU',NULL),
(17,17, 2, 17, NULL,'2026-12-02 09:10:00','2026-12-20','2026-12-26','2026-12-20 15:05:00',NULL,2,'U_TIJEKU','Kasni dolazak'),

-- POTVRDJENA (buduce, bez check-in/out)
(18,18, 3, 18, NULL,'2026-01-20 10:00:00','2026-07-03','2026-07-07',NULL,NULL,2,'POTVRDJENA',NULL),
(19,19, 4, 19,  2,  '2026-02-15 09:30:00','2026-07-08','2026-07-12',NULL,NULL,3,'POTVRDJENA','Ljetni paket'),
(20,20, 5, 20, NULL,'2026-02-18 12:00:00','2026-07-12','2026-07-15',NULL,NULL,2,'POTVRDJENA',NULL),
(21,21, 6, 21, NULL,'2026-03-01 08:15:00','2026-07-16','2026-07-18',NULL,NULL,2,'POTVRDJENA','Bez balkona'),
(22,22, 1, 22, NULL,'2026-03-05 10:10:00','2026-07-19','2026-07-22',NULL,NULL,2,'POTVRDJENA',NULL),
(23,23, 2, 23, NULL,'2026-03-10 11:11:00','2026-07-23','2026-07-25',NULL,NULL,1,'POTVRDJENA',NULL),
(24,24, 3, 24, NULL,'2026-03-12 09:45:00','2026-07-26','2026-07-30',NULL,NULL,1,'POTVRDJENA','Rana prijava ako moguce'),
(25,25, 4, 25, NULL,'2026-03-15 15:00:00','2026-08-01','2026-08-05',NULL,NULL,1,'POTVRDJENA',NULL),
(26,26, 5, 26, NULL,'2026-03-20 13:20:00','2026-08-06','2026-08-10',NULL,NULL,2,'POTVRDJENA',NULL),
(27,27, 6, 27,  1,  '2026-03-22 10:00:00','2026-08-11','2026-08-14',NULL,NULL,3,'POTVRDJENA','Kupon'),
(28,28, 1, 28, NULL,'2026-03-25 09:00:00','2026-08-15','2026-08-18',NULL,NULL,4,'POTVRDJENA','Obiteljska'),
(29,29, 2, 29, NULL,'2026-03-28 12:30:00','2026-08-19','2026-08-22',NULL,NULL,2,'POTVRDJENA',NULL),
(30,30, 3, 30, NULL,'2026-04-01 08:40:00','2026-08-23','2026-08-25',NULL,NULL,2,'POTVRDJENA',NULL),

-- jos nekoliko (da imas 40 komada ukupno)
(31,31, 4, 31, NULL,'2026-04-05 11:00:00','2026-09-01','2026-09-03',NULL,NULL,1,'POTVRDJENA',NULL),
(32,32, 5, 32, NULL,'2026-04-07 09:25:00','2026-09-04','2026-09-08',NULL,NULL,2,'POTVRDJENA',NULL),
(33,33, 6, 33, NULL,'2026-04-10 10:10:00','2026-09-09','2026-09-12',NULL,NULL,2,'POTVRDJENA',NULL),
(34,34, 1, 34, NULL,'2026-04-12 12:20:00','2026-09-13','2026-09-16',NULL,NULL,2,'POTVRDJENA',NULL),
(35,35, 2, 35, NULL,'2026-04-15 08:00:00','2026-09-17','2026-09-20',NULL,NULL,2,'POTVRDJENA',NULL),
(36,36, 3, 36, NULL,'2026-04-18 09:00:00','2026-09-21','2026-09-24',NULL,NULL,2,'POTVRDJENA',NULL),
(37,37, 4, 37,  2,  '2026-04-20 14:10:00','2026-09-25','2026-09-28',NULL,NULL,4,'POTVRDJENA','Promo 2'),
(38,38, 5, 38, NULL,'2026-04-22 10:00:00','2026-10-02','2026-10-05',NULL,NULL,3,'POTVRDJENA',NULL),
(39,39, 6, 39, NULL,'2026-04-25 11:30:00','2026-10-06','2026-10-10',NULL,NULL,2,'POTVRDJENA',NULL),
(40,40, 1, 40, NULL,'2026-04-28 09:45:00','2026-10-11','2026-10-14',NULL,NULL,2,'POTVRDJENA',NULL);


-- 17. RESTORAN_NARUDZBA 

INSERT INTO restoran_narudzba (id, zaposlenik_id, restoran_stol_id, datum_otvaranja, datum_zatvaranja, status) VALUES
-- Plaćene narudžbe za "ZAVRSENE" rezervacije (1-12)
(1, 25, 1, '2026-01-10 19:33:00', '2026-01-10 21:07:00', 'PLACENO'),
(2, 27, 5, '2026-01-19 09:04:00', '2026-01-19 10:17:00', 'PLACENO'),
(3, 28, 12, '2026-02-11 20:03:00', '2026-02-11 22:38:00', 'PLACENO'), 
(4, 25, 26, '2026-02-21 13:12:00', '2026-02-21 14:41:00', 'PLACENO'),
(5, 29, 2, '2026-03-11 18:08:00', '2026-03-11 19:14:00', 'PLACENO'),
(6, 30, 3, '2026-03-19 08:02:00', '2026-03-19 09:06:00', 'PLACENO'),
(7, 27, 8, '2026-04-12 20:11:00', '2026-04-12 21:43:00', 'PLACENO'),
(8, 26, 10, '2026-05-12 14:06:00', '2026-05-12 15:37:00', 'PLACENO'),
(9, 25, 15, '2026-06-21 20:09:00', '2026-06-21 22:13:00', 'PLACENO'),

-- Narudžbe za aktivne goste koji su "U_TIJEKU" -  stats "OTVORENA"
(10, 28, 20, '2026-12-20 19:07:00', NULL, 'OTVORENA'), 
(11, 29, 21, '2026-12-20 20:18:00', NULL, 'OTVORENA'),

-- Narudžbe bez rezervacije - ne gosti 
(12, 30, 1, '2026-05-01 12:13:00', '2026-05-01 13:02:00', 'PLACENO'),
(13, 25, 4, '2026-06-01 19:16:00', '2026-06-01 20:22:00', 'PLACENO'),

-- Stornirana narudžba
(14, 27, 8, '2026-04-23 20:04:00', '2026-04-23 20:11:00', 'STORNIRANO');


-- 18. RESTORAN_STAVKA 

INSERT INTO restoran_stavka (narudzba_id, usluga_id, kolicina, cijena_u_trenutku, status_pripreme) VALUES
-- Prva narudžba
(1, 6, 1, 22.00, 'POSLUZENO'), -- Orada
(1, 19, 2, 4.50, 'POSLUZENO'), -- Vino bijelo

-- Druga narudžba
(2, 2, 1, 10.00, 'POSLUZENO'), -- Americki dorucak
(2, 13, 1, 2.50, 'POSLUZENO'), -- Cappuccino

-- Treća narudžba
(3, 5, 2, 12.00, 'POSLUZENO'), -- Burgeri
(3, 18, 4, 4.00, 'POSLUZENO'), -- Pivo
(3, 11, 2, 5.50, 'POSLUZENO'), -- Desert

-- Četvrta narudžba
(4, 3, 2, 7.00, 'POSLUZENO'), -- Salata veganska
(4, 16, 2, 1.80, 'POSLUZENO'), -- Voda

-- Peta narudžba
(5, 7, 2, 11.00, 'POSLUZENO'), -- Pizza

-- Šesta narudžba
(6, 1, 1, 10.00, 'POSLUZENO'), -- Kontinentalni

-- Sedma narudžba
(7, 6, 2, 22.00, 'POSLUZENO'), -- Orada
(7, 20, 4, 4.50, 'POSLUZENO'), -- Vino crno

-- Osma narudžba
(8, 4, 3, 7.00, 'POSLUZENO'), -- Salata piletina
(8, 17, 3, 3.50, 'POSLUZENO'), -- Cola

-- Deveta narudžba
(9, 5, 2, 12.00, 'POSLUZENO'), -- Burger

-- Deseta narudžba
(10, 19, 1, 4.50, 'POSLUZENO'), -- Vino bijelo
(10, 11, 1, 5.50, 'NARUCENO'), -- Desert

-- Jedanaesta narudžba
(11, 7, 2, 11.00, 'PRIPREMA'), -- Pizza

-- Dvanaesta narudžba
(12, 12, 2, 2.00, 'POSLUZENO'), -- Kava

-- Trinaesta narudžba
(13, 5, 1, 12.00, 'POSLUZENO'), -- Burger
(13, 18, 1, 4.00, 'POSLUZENO'), -- Pivo

-- Četrnaesta narudžba
(14, 12, 1, 2.00, 'STORNIRANO'); -- Kava

-- 19. REZERVACIJA_GOST 

INSERT INTO rezervacija_gost (rezervacija_id, gost_id, uloga) VALUES
-- 1-10
(1, 1, 'NOSITELJ'),
(2, 2, 'NOSITELJ'),
(3, 3, 'NOSITELJ'), (3, 41, 'GOST'), 
(4, 4, 'NOSITELJ'), (4, 42, 'GOST'), 
(5, 5, 'NOSITELJ'), (5, 43, 'GOST'), 
(6, 6, 'NOSITELJ'),
(7, 7, 'NOSITELJ'), (7, 44, 'GOST'), 
(8, 8, 'NOSITELJ'),
(9, 9, 'NOSITELJ'), (9, 10, 'GOST'), (9, 11, 'GOST'), 
(10, 10, 'NOSITELJ'), (10, 45, 'GOST'), 

-- 11-20
(11, 11, 'NOSITELJ'), (11, 46, 'GOST'),
(12, 12, 'NOSITELJ'), (12, 13, 'GOST'),
(13, 13, 'NOSITELJ'), 
(14, 14, 'NOSITELJ'), (14, 47, 'GOST'), 
(15, 15, 'NOSITELJ'), (15, 48, 'GOST'), 
(16, 16, 'NOSITELJ'),
(17, 17, 'NOSITELJ'), (17, 49, 'GOST'),
(18, 18, 'NOSITELJ'), (18, 50, 'GOST'),
(19, 19, 'NOSITELJ'), (19, 20, 'GOST'), (19, 21, 'GOST'),
(20, 20, 'NOSITELJ'), (20, 22, 'GOST'),

-- 21-30
(21, 21, 'NOSITELJ'), (21, 23, 'GOST'),
(22, 22, 'NOSITELJ'), (22, 24, 'GOST'),
(23, 23, 'NOSITELJ'),
(24, 24, 'NOSITELJ'),
(25, 25, 'NOSITELJ'),
(26, 26, 'NOSITELJ'), (26, 27, 'GOST'),
(27, 27, 'NOSITELJ'), (27, 28, 'GOST'), (27, 29, 'GOST'),
(28, 28, 'NOSITELJ'), (28, 30, 'GOST'), (28, 31, 'GOST'), (28, 32, 'GOST'),
(29, 29, 'NOSITELJ'), (29, 33, 'GOST'),
(30, 30, 'NOSITELJ'), (30, 34, 'GOST'),

-- 31-40
(31, 31, 'NOSITELJ'),
(32, 32, 'NOSITELJ'), (32, 35, 'GOST'),
(33, 33, 'NOSITELJ'), (33, 36, 'GOST'),
(34, 34, 'NOSITELJ'), (34, 37, 'GOST'),
(35, 35, 'NOSITELJ'), (35, 38, 'GOST'),
(36, 36, 'NOSITELJ'), (36, 39, 'GOST'),
(37, 37, 'NOSITELJ'), (37, 40, 'GOST'), (37, 1, 'GOST'), (37, 2, 'GOST'),
(38, 38, 'NOSITELJ'), (38, 3, 'GOST'), (38, 4, 'GOST'),
(39, 39, 'NOSITELJ'), (39, 5, 'GOST'),
(40, 40, 'NOSITELJ'), (40, 6, 'GOST');


/*
-- 20. LOG_REZERVACIJE 
*/
INSERT INTO log_rezervacije (rezervacija_id, stari_status, novi_status, vrijeme_promjene, korisnik_db) VALUES
(1, 'POTVRDJENA', 'ZAVRSENA', '2026-01-12 10:13:00', 'luka.lukic'),
(13, 'POTVRDJENA', 'OTKAZANA', '2026-06-05 14:24:00', 'nikola.ninic'),
(16, 'POTVRDJENA', 'U_TIJEKU', '2026-12-01 14:02:00', 'iva.ivic'),
(7, 'POTVRDJENA', 'ZAVRSENA', '2026-04-14 10:11:00', 'maja.majic'),
(2, 'POTVRDJENA', 'ZAVRSENA', '2026-01-20 10:22:00', 'luka.lukic'),
(3, 'POTVRDJENA', 'ZAVRSENA', '2026-02-13 10:08:00', 'iva.ivic');



-- 6. FINANCIJE
-- 21. RACUN

-- 21. RACUN (ispravak: dodan tip_racuna)
-- Pravilo iz DDL-a:
--  - HOTEL racun: rezervacija_id mora biti NOT NULL
--  - RESTORAN racun: rezervacija_id treba biti NULL
-- U tvom datasetu svi racuni 1-16 imaju rezervacija_id, pa su svi tipa HOTEL.

INSERT INTO racun
(id, tip_racuna, rezervacija_id, datum_izdavanja, nacin_placanja, iznos_ukupno, status_racuna, napomena)
VALUES
-- Rezervacija 1
(1,  'HOTEL', 1,  '2026-01-12 10:13:00', 'KARTICA',   145.00, 'PLACENO',  'R1 na firmu'),
-- Rezervacija 2
(2,  'HOTEL', 2,  '2026-01-20 10:23:00', 'GOTOVINA',  234.00, 'PLACENO',  NULL),
-- Rezervacija 3
(3,  'HOTEL', 3,  '2026-02-13 10:07:00', 'KARTICA',   360.00, 'PLACENO',  NULL),
-- Rezervacija 4
(4,  'HOTEL', 4,  '2026-02-22 10:32:00', 'ONLINE',    330.00, 'PLACENO',  'Placeno unaprijed'),
-- Rezervacija 5
(5,  'HOTEL', 5,  '2026-03-12 10:09:00', 'KARTICA',   215.00, 'PLACENO',  NULL),
-- Rezervacija 6
(6,  'HOTEL', 6,  '2026-03-21 10:21:00', 'GOTOVINA',  285.00, 'PLACENO',  NULL),
-- Rezervacija 7
(7,  'HOTEL', 7,  '2026-04-14 10:11:00', 'VIRMANSKI', 930.00, 'PLACENO',  NULL),
-- Rezervacija 8
(8,  'HOTEL', 8,  '2026-04-24 10:37:00', 'KARTICA',   250.00, 'PLACENO',  NULL),
-- Rezervacija 9
(9,  'HOTEL', 9,  '2026-05-15 10:18:00', 'KARTICA',   680.00, 'PLACENO',  NULL),
-- Rezervacija 10
(10, 'HOTEL', 10, '2026-05-20 10:08:00', 'GOTOVINA',  290.00, 'PLACENO',  NULL),
-- Rezervacija 11
(11, 'HOTEL', 11, '2026-06-12 10:12:00', 'KARTICA',   140.00, 'PLACENO',  NULL),
-- Rezervacija 12
(12, 'HOTEL', 12, '2026-06-23 10:16:00', 'KARTICA',   350.00, 'PLACENO',  NULL),

-- Otkazana s naplatom penala (Rez 13)
(13, 'HOTEL', 13, '2026-06-05 14:26:00', 'KARTICA',    50.00, 'PLACENO',  'Naplata kasnog otkaza'),

-- Racuni koji nisu placeni
(14, 'HOTEL', 31, '2026-09-03 10:53:00', 'GOTOVINA',  230.00, 'OTVOREN',  NULL),
(15, 'HOTEL', 32, '2026-09-08 12:17:00', 'KARTICA',   460.00, 'OTVOREN',  NULL),
(16, 'HOTEL', 33, '2026-09-03 10:53:00', 'GOTOVINA',  480.00, 'OTVOREN',  NULL),
(17, 'RESTORAN', NULL, '2026-05-01 13:05:00', 'GOTOVINA', NULL, 'PLACENO', 'Gost izvana - narudzba 12'),
(18, 'RESTORAN', NULL, '2026-06-01 20:30:00', 'KARTICA',  NULL, 'PLACENO', 'Gost izvana - narudzba 13');


-- 22. STAVKA_RACUNA

INSERT INTO stavka_racuna
(racun_id, usluga_id, restoran_stavka_id, tip_stavke, opis, kolicina, cijena_jedinicna, iznos_ukupno)
VALUES
-- Prvi račun (dodane 2 restoranske stavke iz narudzbe_id=1; restoran_stavka.id = 1 i 2)
(1, NULL, NULL, 'NOCENJE', 'Single soba', 2, 55.00, 110.00),
(1, NULL, NULL, 'BORAVISNA_PRISTOJBA', 'BP', 2, 2.00, 4.00),

-- RESTORAN: narudzba 1, stavka id=1 (Orada)
(1, NULL, 1, 'USLUGA', 'Orada', 1, 22.00, 22.00),
-- RESTORAN: narudzba 1, stavka id=2 (Vino bijelo, kolicina 2)
(1, NULL, 2, 'USLUGA', 'Vino bijelo', 2, 4.50, 9.00),

-- Drugi račun
(2, NULL, NULL, 'NOCENJE', 'Double soba', 2, 115.00, 230.00),
(2, NULL, NULL, 'BORAVISNA_PRISTOJBA', 'BP', 2, 2.00, 4.00),

-- Treći račun
(3, NULL, NULL, 'NOCENJE', 'Twin soba', 3, 115.00, 345.00),
(3, NULL, NULL, 'BORAVISNA_PRISTOJBA', 'BP', 6, 2.00, 12.00),

-- Četvrti račun
(4, NULL, NULL, 'NOCENJE', 'Triple soba', 2, 160.00, 320.00),
(4, NULL, NULL, 'BORAVISNA_PRISTOJBA', 'BP', 4, 2.00, 8.00),

-- Peti račun
(5, NULL, NULL, 'NOCENJE', 'Econ Double', 2, 95.00, 190.00),
(5, 21,   NULL, 'USLUGA', 'Spa ulaznica', 1, 15.00, 15.00),

-- Šesti račun
(6, NULL, NULL, 'NOCENJE', 'Econ Single', 3, 60.00, 180.00),
(6, 28,   NULL, 'USLUGA', 'Najam vozila', 2, 40.00, 80.00),

-- Sedmi račun
(7, NULL, NULL, 'NOCENJE', 'Junior Suite', 4, 230.00, 920.00),
(7, NULL, NULL, 'BORAVISNA_PRISTOJBA', 'BP', 8, 2.00, 16.00),

-- Osmi račun
(8, NULL, NULL, 'NOCENJE', 'Deluxe', 2, 155.00, 310.00),
(8, NULL, NULL, 'OSTALO', 'Popust na buku', 1, -60.00, -60.00),

-- Deveti račun
(9, NULL, NULL, 'NOCENJE', 'Superior', 5, 135.00, 675.00),
(9, NULL, NULL, 'BORAVISNA_PRISTOJBA', 'BP', 15, 2.00, 30.00),

-- Deseti račun (dodana 1 restoranska stavka iz narudzbe_id=10; restoran_stavka.id = 20 (Desert))
(10, NULL, NULL, 'NOCENJE', 'Superior Twin', 2, 135.00, 270.00),

-- RESTORAN: narudzba 10, stavka id=20 (Desert, kolicina 1)
(10, NULL, 18, 'USLUGA', 'Desert', 1, 5.50, 5.50),

-- Jedanaesti račun
(11, NULL, NULL, 'NOCENJE', 'Single', 2, 75.00, 150.00),

-- Dvanaesti račun
(12, NULL, NULL, 'NOCENJE', 'Econ Double', 3, 95.00, 285.00),
(12, 22,   NULL, 'USLUGA', 'Masaza 30min', 2, 25.00, 50.00),

-- Trinaesti račun
(13, NULL, NULL, 'OSTALO', 'Naknada', 1, 50.00, 50.00);


/*
-- 7. ODRŽAVANJE I FEEDBACK
*/
INSERT INTO ciscenje_dnevni_nalog (zaposlenik_id, rezervacija_id, prijavljena_steta, opis_stete, obavljeno) VALUES
(7, 1, 0, NULL, 1), 
(8, 2, 1, 'Gost razbio čašu u kupaonici', 1),
(9, 3, 0, NULL, 1), 
(7, 4, 1, 'Crna mrlja na tepihu', 0),
(10, 5, 0, NULL, 1),
(8, 6, 0, NULL, 1),
(9, 7, 0, NULL, 1),
(7, 8, 1, 'Oštećena zavjesa', 1),
(10, 9, 0, NULL, 1),
(8, 10, 0, NULL, 1);

INSERT INTO servis_dnevni_nalog (zaposlenik_id, soba_id, korisnik_placa, opis, rijeseno) VALUES
(13, 1, 0, 'Zamjena žarulje', 1),
(14, 20, 1, 'Gost uništio daljinski od TV-a', 1),
(15, 36, 0, 'Klima uređaj buči', 0),
(16, 10, 0, 'Vrata od tuš kabine zapinju', 1),
(17, 43, 0, 'Odštopavanje odvoda', 0),
(13, 5, 0, 'Promjena baterija na bravi', 1),
(14, 25, 0, 'Popravak noge od stola', 1),
(15, 33, 0, 'Resetiranje routera', 1);


-- 25. RECENZIJA
INSERT INTO recenzija (rezervacija_id, ocjena, komentar) VALUES
(1, 5, 'Sve je bilo odlično!'),
(2, 4, 'Soba super, doručak prosječan.'),
(3, 3, 'Lijep pogled, mala soba.'),
(4, 1, 'Bezobrazno osoblje!!! Ne preporučujem nikome sa obitelji'),
(5, 5, 'Odlična hrana, super smo zadovoljni i dolazimo iduce godine'),
(6, 2, 'Cijena je nerealna za ovakvu sobu koja je zadnje renovirana za vrijeme Druga Tita'),
(7, 4, 'Sve je bilo čisto kada smo došli, osoblje je spremno pomoći. Jedino je parking teško za naći.'),
(8, 5, 'Uživali smo svaki dan i soba je dovoljna za dvoje. Internet je začuđujuče brz.'),
(9, 3, 'Hrana je bila hladna kada je došla i malo neslana. Soba je uredna i ima sve što nam je bilo potrebno.'),
(10, 1, 'Kada smo pronašli mrtvog miša u hodniku i to rekli sobarici ona nam je odgovorila -Barem je mrtav-. Grozno'),
(11, 4, 'Omjer cijene i usluge je malo nerealan, ali iskustvo je bilo super'),
(12, 5, 'Hrana je top, pogled sa terase je taman za jutarnju kavicu i osoblje je spremno pomoći'),
(13, 2, 'Food is too spicy, everyone is smoking and there is no reliable parking. Only redeeming quality is the prices'),
(14, 3, 'Ništa posebno, vidio sam i bolje'),
(15, 2, 'Trazila sam konobara jos majoneze i rekao mi je da to neide uz grah. Nije ovo više jugoslavija pusti me da stavljam majonezu u grah!!!!'),
(16, 5, 'TOP TOP TOP mjesto!!! Hrana je najbolja koju sam jela, soba prekrasno miriši i sve je blizu'),
(17, 3, 'Overall the service is okay. The staff is not very enthusiastic about their job and they dont like Trump #MAGA'),
(18, 4, 'Malo je skuplje ali vrijedi tih novaca. Jedini problem je to što je miris u sobama malo previše naporan'),
(19, 5, 'Žena htjela stavit majonezu u grah, konobar odgovara -Ti nisi normalna-, deda je legenda'),
(20, 2, 'Rekli su nam da nesmijemo puštati THOMPSONA pre glasno');

-- FFUUUUUUUNKCIJEEEE

-- FUNKCIJA KOJA IZRACUNAVA CIJENU SMJESTAJA SOBE PO DATUMU 

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

-- TEST TEST TEST
-- SELECT izracunaj_cijenu_smjestaja(1, '2026-12-12', '2026-12-20') AS cijena_boravka; -- zimska cijena single sobe
-- SELECT izracunaj_cijenu_smjestaja(1, '2026-7-12', '2026-7-20') AS cijena_boravka; -- ljetna cijena single sobe


-- FUNKCIJA KOJA RAČUNA PDV ZA SVAKU USLUGU KOJU IMAMO U TABLICI USLUGE


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

-- TEST TEST TEST 
-- select usluga.id, pdv_koji_moramo_platiti_za_uslugu(usluga.id) as owed_VAT
-- from usluga;


-- FUNKCIJA KOJA RAČUNA IZLAZNI PDV OD RACUNA PO RACUN STAVKI

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

-- ZA PRVU FUNKCIJU TREBA PROMIJENIT IME NA procijenjeni_pretporez_po_normativu_za_uslugu A DRUGU FUNCKIJU TREBA IZMJENIT DA RACUNA IZLAZNI PDV PO RACUN STAVKA ZA SVAKI RACUN 
-- 1) Preimenovati funkciju pdv_koji_moramo_platiti_za_uslugu u procijenjeni_pretporez_po_normativu_za_uslugu
--    (funkcija procjenjuje pretporez na inpute na temelju normativa; nije stvarni ulazni PDV jer nemamo ulazne račune).
-- 2) Izmijeniti funkciju pdv_za_godinu da računa samo izlazni PDV iz stavki računa (racun + stavka_racuna),
--    koristeći parametar p_godina (umjesto hard-coded 2026) i po potrebi pravilnu formulu ovisno je li iznos neto ili bruto.



-- Izracun marze jela
-- FUNCKIJA KOJA POKAZUJE KOLKO KOŠTA KOJE JELO ZA NAPRAVITI PO NORMATIVU

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


-- TEST TEST TEST 
-- SELECT 
--   u.id,
--   u.naziv,
--   u.cijena_trenutna AS cijena,
--   izracunaj_marzu_jela(u.id) AS marza
-- FROM usluga u
-- WHERE EXISTS (
--   SELECT 1 
--   FROM normativ n 
--   WHERE n.usluga_id = u.id
-- )
-- ORDER BY marza DESC;


-- OKIDAAAAAAACI


-- 1. Okidač za novu rezervacija na istu sobu koja već rezervirana + upit za prikaz  - - E.B.

DELIMITER //

CREATE TRIGGER  trg_dupla_rezervacija_sobe
BEFORE INSERT ON rezervacija
FOR EACH ROW
BEGIN
    DECLARE brojac_rez  INT;
    
    SELECT COUNT(*) INTO brojac_rez
    FROM rezervacija
    WHERE soba_id =NEW.soba_id
      AND status != 'OTKAZANA'									
      AND NEW.pocetak_datum < kraj_datum 					      
      AND NEW.kraj_datum > pocetak_datum;
      
    IF brojac_rez > 0 THEN
        SIGNAL SQLSTATE '45000'
        SET MESSAGE_TEXT = 'Greška: Soba je već rezervirana u odabranom terminu!';
    END IF;
END //

DELIMITER ;

-- TEST TEST TEST 1
-- UPIT 1
-- SELECT 
--     r.id AS ID_Rezervacije,
--     s.broj AS Broj_Sobe,
--     CONCAT(g.ime, ' ', g.prezime) AS Gost,
-- 	CONCAT(DATE_FORMAT(r.pocetak_datum, '%d.%m.'), '-', DATE_FORMAT(r.kraj_datum, '%d.%m.%Y')) AS Termin,
-- 	r.status
-- FROM rezervacija r
-- JOIN soba s ON r.soba_id = s.id
-- JOIN gost g ON r.gost_nositelj_id = g.id
-- WHERE r.status IN ('POTVRDJENA', 'U_TIJEKU');

-- INSERT INTO rezervacija 
-- (gost_nositelj_id, zaposlenik_id, soba_id, promocija_id, datum_rezervacije, pocetak_datum, kraj_datum, broj_osoba, status, napomena) 
-- VALUES 
-- (1, 1, 16, NULL, NOW(), '2026-12-19', '2026-12-22', 1, 'POTVRDJENA', 'Test test');

-- TEST TEST TEST 2
-- INSERT INTO rezervacija
-- (id, gost_nositelj_id, zaposlenik_id, soba_id, promocija_id, datum_rezervacije,
--  pocetak_datum, kraj_datum, vrijeme_check_in, vrijeme_check_out, broj_osoba, status, napomena)
-- VALUES
-- (41, 41, 1, 18, NULL, '2026-06-01 10:00:00',
--  '2026-07-05', '2026-07-06', NULL, NULL, 2, 'POTVRDJENA',
--  'TEST: ovo se preklapa s rezervacijom ID=18 (soba 18, 2026-07-03 do 2026-07-07)');

-- 2.Okidač Promocija se smije unijeti u rezervaciju samo ako je aktivna i vremenski važeća + upit za prikaz - - E.B.
DELIMITER //

CREATE TRIGGER trg_unos_provjera_valjanosti_promocije
BEFORE INSERT ON rezervacija
FOR EACH ROW
BEGIN
    DECLARE v_aktivna INT;
    
    DECLARE v_promo_vrijedi_od DATE;
    DECLARE v_promo_vrijedi_do DATE;
    
    DECLARE v_rez_dolazak DATE;
    DECLARE v_rez_odlazak DATE;

    IF NEW.promocija_id IS NOT NULL THEN
        
        SELECT aktivna, datum_pocetka, datum_zavrsetka 
        INTO v_aktivna, v_promo_vrijedi_od, v_promo_vrijedi_do
        FROM promocija 
        WHERE id = NEW.promocija_id;

        SET v_rez_dolazak = NEW.pocetak_datum;
        SET v_rez_odlazak = NEW.kraj_datum;

        IF v_aktivna = 0 THEN
            SIGNAL SQLSTATE '45000'
            SET MESSAGE_TEXT = 'Greška: Odabrana promocija je neaktivna!';
        END IF;

        IF v_rez_dolazak < v_promo_vrijedi_od THEN
            SIGNAL SQLSTATE '45000'
            SET MESSAGE_TEXT = 'Greška: Rezervacija počinje prije nego što sama promocija vrijedi!';
        END IF;

        IF v_rez_odlazak > v_promo_vrijedi_do THEN
            SIGNAL SQLSTATE '45000'
            SET MESSAGE_TEXT = 'Greška: Rezervacija završava nakon što je promocija istekla!';
        END IF;
        
    END IF;
END //

DELIMITER ;


-- 2. Upit + TEST

-- INSERT INTO promocija(id, naziv, kod_kupona, popust_postotak, datum_pocetka, datum_zavrsetka,aktivna) VALUES
-- (999, 'NEAKTIVNA', 'TESTNA', 10.00, '2025-12-01', '2026-02-28',0); 

-- SELECT 
--     p.id AS ID_Promo,
--     p.naziv AS Naziv_Promocije,
--     DATE_FORMAT(p.datum_pocetka, '%d.%m.%Y') AS Vrijedi_Od,
--     DATE_FORMAT(p.datum_zavrsetka, '%d.%m.%Y') AS Vrijedi_Do,
--     p.aktivna AS Aktivna,
--     
--     IF(p.aktivna = 1, 'Da', 'Ne') AS Aktivna,
--     
--     COUNT(r.id) AS Ukupno_Iskoristeno,
--     
--     GROUP_CONCAT(r.id) AS ID_Rezervacija_Lista
-- FROM 
--     promocija p
-- LEFT JOIN 
--     rezervacija r ON p.id = r.promocija_id
-- GROUP BY 
--     p.id, p.naziv, p.datum_pocetka, p.datum_zavrsetka, p.aktivna
-- ORDER BY 
--     p.id;

-- INSERT INTO rezervacija 
-- (gost_nositelj_id, zaposlenik_id, soba_id, promocija_id, datum_rezervacije, pocetak_datum, kraj_datum, broj_osoba, status, napomena) 
-- VALUES 
-- (1, 1, 7, 999, NOW(), '2026-01-20', '2026-01-22', 2, 'POTVRDJENA', 'Test neaktivna proba');

-- INSERT INTO rezervacija 
-- (gost_nositelj_id, zaposlenik_id, soba_id, promocija_id, datum_rezervacije, pocetak_datum, kraj_datum, broj_osoba, status, napomena) 
-- VALUES 
-- (1, 1, 7, 1, NOW(), '2026-02-22', '2026-03-01', 2, 'POTVRDJENA', 'Test after');

-- INSERT INTO rezervacija 
-- (gost_nositelj_id, zaposlenik_id, soba_id, promocija_id, datum_rezervacije, pocetak_datum, kraj_datum, broj_osoba, status, napomena) 
-- VALUES 
-- (1, 1, 7, 3, NOW(), '2026-02-22', '2026-03-05', 2, 'POTVRDJENA', 'Test before');

-- 3. Okidač Promocija se smije ažurirati u postojećoj rezervaciji samo ako je aktivna i vremenski važeća + upit - - E.B.
DELIMITER //

CREATE TRIGGER  trg_ažuriranje_rezervacije_provjera_valjanosti_promocije
BEFORE UPDATE ON rezervacija
FOR EACH ROW
BEGIN
    DECLARE v_aktivna INT;
    
    DECLARE v_promo_vrijedi_od DATE;
    DECLARE v_promo_vrijedi_do DATE;

    DECLARE v_rez_dolazak DATE;
    DECLARE v_rez_odlazak DATE;

    IF NEW.promocija_id IS NOT NULL THEN
        
        SELECT aktivna, datum_pocetka, datum_zavrsetka 
        INTO v_aktivna, v_promo_vrijedi_od, v_promo_vrijedi_do
        FROM promocija 
        WHERE id=NEW.promocija_id;

        SET v_rez_dolazak=NEW.pocetak_datum;
        SET v_rez_odlazak=NEW.kraj_datum;


        IF v_aktivna = 0 THEN
            SIGNAL SQLSTATE '45000'
            SET MESSAGE_TEXT = 'Greška: Odabrana promocija je neaktivna!';
        END IF;


        IF v_rez_dolazak < v_promo_vrijedi_od THEN
            SIGNAL SQLSTATE '45000'
            SET MESSAGE_TEXT = 'Greška: Rezervacija počinje prije nego što sama promocija počinje vrijediti!';
        END IF;

        IF v_rez_odlazak > v_promo_vrijedi_do THEN
            SIGNAL SQLSTATE '45000'
            SET MESSAGE_TEXT = 'Greška: Rezervacija završava nakon što je promocija istekla!';
        END IF;
        
    END IF;
END //

DELIMITER ;

-- 3 upit + TEST TEST TEST
-- SELECT 
--     r.id AS ID_Rez,
--     CONCAT(g.ime, ' ', g.prezime) AS Nositelj,

--     DATE_FORMAT(r.pocetak_datum, '%d.%m.%Y') AS Boravak_Od,
--     DATE_FORMAT(r.kraj_datum, '%d.%m.%Y') AS Boravak_Do,
--     
--     IFNULL(p.naziv, 'Nema promocije') AS Trenutna_Promo
--     
-- FROM 
--     rezervacija r
-- JOIN 
--     gost g ON r.gost_nositelj_id=g.id
-- LEFT JOIN 
--     promocija p ON r.promocija_id=p.id
-- WHERE 
--     r.status IN ('POTVRDJENA', 'U_TIJEKU')
-- ORDER BY 
--     r.id;


-- UPDATE rezervacija 
-- SET promocija_id =999 
-- WHERE id = 16;

-- UPDATE rezervacija 
-- SET promocija_id = 2 
-- WHERE id =25;


-- UPDATE rezervacija 
-- SET promocija_id = 4 
-- WHERE id =38;

-- 4. OKIDAČ - Check in vrijeme striktno od 14:00h pa nadalje kod prijave gosta tj. ažuriranja relacije rezervacija - - E.B.

-- umjesto hour stavljeno time to sec, jer nije valjalo check in između 14 i 15
DELIMITER //

CREATE TRIGGER trg_provjera_checkin_time
BEFORE UPDATE ON rezervacija
FOR EACH ROW
BEGIN
  IF NEW.vrijeme_check_in IS NOT NULL AND OLD.vrijeme_check_in IS NULL THEN
    IF TIME_TO_SEC(TIME(NEW.vrijeme_check_in)) < TIME_TO_SEC('14:00:00') THEN
      SIGNAL SQLSTATE '45000'
      SET MESSAGE_TEXT = 'Greška: Check-in nije dozvoljen prije 14:00 sati!';
    END IF;
  END IF;
END//

-- STARI OKIDAČ
-- DELIMITER ;

-- DELIMITER //

-- CREATE TRIGGER trg_provjera_checkin_time
-- BEFORE UPDATE ON rezervacija
-- FOR EACH ROW
-- BEGIN
--     IF NEW.vrijeme_check_in IS NOT NULL AND OLD.vrijeme_check_in IS NULL THEN
--         
--         IF HOUR(NEW.vrijeme_check_in) <= 14 THEN
--             SIGNAL SQLSTATE '45000'
--             SET MESSAGE_TEXT = 'Greška: Check-in nije dozvoljen prije 14:00 sati!';
--         END IF;
--         
--     END IF;
-- END //

-- DELIMITER ;

-- INSERT INTO rezervacija 
-- (gost_nositelj_id, zaposlenik_id, soba_id, promocija_id, datum_rezervacije, pocetak_datum, kraj_datum, vrijeme_check_in, vrijeme_check_out, broj_osoba, status, napomena) VALUES 
-- (5, 1, 48, NULL, '2025-12-20 10:00:00', '2026-01-11', '2026-01-15', '2026-01-11 15:30:00', NULL, 2, 'U_TIJEKU', 'Dummy gost 1 - Već u sobi'),
-- (6, 2, 49, NULL, '2025-12-25 11:00:00', '2026-01-12', '2026-01-16', '2026-01-12 14:15:00', NULL, 2, 'U_TIJEKU', 'Dummy gost 2 - Upravo stigli');


-- 4. Upit
-- SELECT 
--     r.id AS ID_Rez,
--     CONCAT(g.ime, ' ', g.prezime) AS Gost,
--     DATE_FORMAT(pocetak_datum, '%d.%m.%Y') AS Dolazak,
--     
--     IFNULL(
--         DATE_FORMAT(vrijeme_check_in, '%H:%i'), 
--         'Čeka se dolazak'
--     ) AS Vrijeme_prijave,
--     status
-- FROM rezervacija r
-- JOIN gost g ON r.gost_nositelj_id = g.id
-- WHERE status IN ('POTVRDJENA', 'U_TIJEKU')
-- ORDER BY r.id
-- LIMIT  10;

-- TEST TEST TEST

-- UPDATE rezervacija 
-- SET vrijeme_check_in= '2026-07-19 13:59:59', 
--     status = 'U_TIJEKU'
-- WHERE id = 18;

-- UPDATE rezervacija 
-- SET vrijeme_check_in = '2026-07-19 14:00:01', 
--     status = 'U_TIJEKU'
-- WHERE id = 20;


-- 5. Automatski unos svih novih rezervacija u "log_rezervacija" - - E.B.

DELIMITER //
CREATE TRIGGER trg_unos_log_rezervacija
AFTER INSERT ON rezervacija
FOR EACH ROW
BEGIN
    INSERT INTO log_rezervacije (rezervacija_id, stari_status, novi_status, korisnik_db)
    VALUES (NEW.id, NULL, NEW.status, USER());
END //
DELIMITER ;


-- TEST TEST TEST 
-- INSERT INTO rezervacija 
-- (gost_nositelj_id, zaposlenik_id, soba_id, promocija_id, datum_rezervacije, pocetak_datum, kraj_datum, broj_osoba, status, napomena) 
-- VALUES 
-- (45, 1, 15, NULL, NOW(), '2026-11-01', '2026-11-05', 1, 'POTVRDJENA', 'Log test');

-- UPDATE rezervacija 
-- SET kraj_datum = '2026-01-12' 
-- WHERE id = 1;


-- 5. Upit
-- SELECT 
--     l.rezervacija_id AS 'ID Rez',
--     l.id AS 'ID Log',
--     CONCAT(g.ime, ' ', g.prezime) AS 'Nositelj Rezervacije',
--     
--     DATE_FORMAT(l.vrijeme_promjene, '%d.%m.%Y %H:%i:%s') AS 'Vrijeme Promjene',
--     
--     CONCAT(
--         IFNULL(l.stari_status, 'NOVA'), 
--         '-->', 
--         l.novi_status
--     ) AS 'Tijek Promjene Statusa',
--     
--     IF(l.novi_status = 'OTKAZANA', 'Otkazana', 
--         IF(l.novi_status = 'U_TIJEKU', 'U tijeku', 
--             CONCAT(DATEDIFF(r.kraj_datum, r.pocetak_datum), ' dana')
--         )
--     ) AS 'Trajanje Boravka',
--     
--    l.korisnik_db AS 'Izvršio Korisnik'

-- FROM 
--     log_rezervacije l
-- JOIN 
--     rezervacija r ON l.rezervacija_id = r.id
-- JOIN 
--     gost g ON r.gost_nositelj_id = g.id
-- ORDER BY 
--     l.vrijeme_promjene DESC, l.id DESC
--     ;



-- 6. Automatski unos svih ažuriranja postojećih rezervacija u "log_rezervacija"  - - E.B.

DELIMITER //
CREATE TRIGGER trg_azuriranje_log_rezervacija
AFTER UPDATE ON rezervacija
FOR EACH ROW
BEGIN
    IF OLD.status != NEW.status THEN
        INSERT INTO log_rezervacije (rezervacija_id, stari_status, novi_status, korisnik_db)
        VALUES (NEW.id, OLD.status, NEW.status, USER());
    END IF;
END //
DELIMITER ;

-- TEST TEST TEST 

-- UPDATE rezervacija 
-- SET 
--     pocetak_datum = '2026-12-24',  
--     kraj_datum = '2026-12-30',
--     soba_id = 20,
--     napomena = 'Gost zatražio promjenu termina pa otkazao',
--     status = 'OTKAZANA'
-- WHERE id = 41;

-- 6. Upit
-- SELECT 
--     l.rezervacija_id AS 'ID',
--     CONCAT(g.ime, ' ', g.prezime) AS 'Gost',
--     
--     CONCAT(IFNULL(l.stari_status, 'NOVA'), ' --> ', l.novi_status) AS 'Povijest Promjene Statusa',
--     DATE_FORMAT(l.vrijeme_promjene, '%H:%i:%s') AS 'Vrijeme Promjene',
--     
--     DATE_FORMAT(r.pocetak_datum, '%d.%m.%Y') AS 'Trenutni Datum Dolaska',
--     r.napomena AS 'Trenutna Napomena (Zadnja)'

-- FROM 
--     log_rezervacije l
-- JOIN 
--     rezervacija r ON l.rezervacija_id = r.id
-- JOIN 
--     gost g ON r.gost_nositelj_id = g.id
-- WHERE 
--     l.rezervacija_id = 41
-- ORDER BY 
--     l.id DESC
-- LIMIT 1;



-- 7. Automatski unos svih brisanja postojećih rezervacija u "log_rezervacija"  - - E.B.
ALTER TABLE log_rezervacije DROP FOREIGN KEY fk_rezervacija_id;
DELIMITER //
CREATE TRIGGER trg_brisanje_log_rezervacija
AFTER DELETE ON rezervacija
FOR EACH ROW
BEGIN
    INSERT INTO log_rezervacije (rezervacija_id, stari_status, novi_status, korisnik_db)
    VALUES (OLD.id, OLD.status, 'OBRISANO', USER());
END //
DELIMITER ;

-- TEST TEST TEST 1 

-- INSERT INTO rezervacija 
-- (gost_nositelj_id, zaposlenik_id, soba_id, promocija_id, datum_rezervacije, pocetak_datum, kraj_datum, broj_osoba, status, napomena) 
-- VALUES 
-- (10, 1, 50, NULL, NOW(),'2027-02-01','2027-02-02',1,'POTVRDJENA', 'Gost ostaje godinu dana? Typo?');
-- SET SQL_SAFE_UPDATES = 1;

-- DELETE FROM rezervacija 
-- WHERE gost_nositelj_id = 10 
--   AND napomena LIKE 'Typo%';

-- DELETE FROM rezervacija
-- WHERE id = 41;


-- 7. upit
-- SELECT 
--     l.id AS 'ID Log',
--     l.rezervacija_id AS 'ID Obrisane Rezervacije',
--     
--     DATE_FORMAT(l.vrijeme_promjene, '%d.%m.%Y %H:%i') AS 'Vrijeme brisanja',
--     
--     CONCAT(l.stari_status, ' --> ', l.novi_status) AS 'Status promjena',
--     
--     IFNULL(CONCAT(g.ime, ' ', g.prezime), 'Podaci trajno uklonjeni') AS 'Originalni Nositelj',
--     
--     l.korisnik_db AS 'Obrisao korisnik',
--     
-- 	CONCAT(TIMESTAMPDIFF(MINUTE, l.vrijeme_promjene, NOW()), ' min') AS 'Proteklo od brisanja'

-- FROM 
--     log_rezervacije l

-- LEFT JOIN 
--     rezervacija r ON l.rezervacija_id = r.id
-- LEFT JOIN 
--     gost g ON r.gost_nositelj_id = g.id
-- WHERE 
--     l.novi_status = 'OBRISANO'
-- ORDER BY 
--     l.vrijeme_promjene DESC;




-- 8. OKIDAČ Automatski unos besplatnog čišćenja na stavka_računu ukoliko  je boravak bio duži od tri dana  - - E.B.


DELIMITER //

CREATE TRIGGER trg_besplatno_ciscenje_dugi_boravak
BEFORE INSERT ON stavka_racuna
FOR EACH ROW
BEGIN
    DECLARE v_naziv_usluge VARCHAR(50);
    DECLARE v_rezervacija_id INT;
    DECLARE v_trajanje_dana INT;

    IF NEW.usluga_id IS NOT NULL THEN
        SELECT naziv INTO v_naziv_usluge 
        FROM usluga 
        WHERE id = NEW.usluga_id;

        IF v_naziv_usluge = 'Završno čišćenje' THEN
            
            SELECT rezervacija_id INTO v_rezervacija_id
            FROM racun
            WHERE id = NEW.racun_id;

            SELECT DATEDIFF(kraj_datum, pocetak_datum) INTO v_trajanje_dana
            FROM rezervacija
            WHERE id = v_rezervacija_id;

            IF v_trajanje_dana > 3 THEN
                SET NEW.cijena_jedinicna = 0.00;

                SET NEW.iznos_ukupno = 0.00; 

                SET NEW.opis = CONCAT(NEW.opis, ' (GRATIS -Boravak duži od 3 dana)');
            END IF;
            
        END IF;
    END IF;
END //
DELIMITER ;

-- INSERT INTO usluga (id, kategorija_id, naziv, opis, jedinica_mjere, cijena_trenutna)
-- VALUES (31, 4, 'Završno čišćenje', 'Završno čišćenje sobe nakon boravka', 'kom', 30.00);

-- INSERT INTO stavka_racuna (racun_id, usluga_id, tip_stavke, opis, kolicina, cijena_jedinicna, iznos_ukupno) 
-- VALUES (1, 31, 'USLUGA', 'Čišćenje redovno', 1, 30.00, 30.00);

-- INSERT INTO stavka_racuna (racun_id, usluga_id, tip_stavke, opis, kolicina, cijena_jedinicna, iznos_ukupno) 
-- VALUES (7, 31, 'USLUGA', 'Čišćenje redovno', 1, 30.00, 30.00);

-- 8. Upit
-- SELECT 
--     CONCAT(g.ime, ' ', g.prezime) AS gost_nositelj,
--     r.id AS br_racuna,
--     DATE_FORMAT(rez.pocetak_datum, '%d.%m.%Y') AS check_in,
--     DATE_FORMAT(rez.kraj_datum, '%d.%m.%Y') AS check_out,
--     DATEDIFF(rez.kraj_datum, rez.pocetak_datum) AS trajanje_nocenja,
--     sr.opis AS stavka_opis,
--     CONCAT(FORMAT(u.cijena_trenutna, 2), ' €') AS redovna_cijena,
--     CONCAT(FORMAT(sr.cijena_jedinicna, 2), ' €') AS naplacena_cijena,
--     
--     IF(DATEDIFF(rez.kraj_datum, rez.pocetak_datum) > 3 AND sr.cijena_jedinicna = 0, 
--        'Gratis',
--        
--        IF(DATEDIFF(rez.kraj_datum, rez.pocetak_datum) <= 3 AND sr.cijena_jedinicna > 0,
--           'Naplaćeno',
--           
--           'GREŠKA: Trigger ne šljaka!'
--        )
--     ) AS status

-- FROM stavka_racuna sr
-- JOIN racun r ON sr.racun_id = r.id
-- JOIN rezervacija rez ON r.rezervacija_id = rez.id
-- JOIN gost g ON rez.gost_nositelj_id = g.id
-- JOIN usluga u ON sr.usluga_id = u.id
-- WHERE u.naziv = 'Završno čišćenje'
-- ORDER BY r.id;

-- Okidač  “Osiguravanje ispravnog kronološkog slijeda rezervacije” 



DELIMITER //

CREATE TRIGGER trg_check_datumi_rezervacije
BEFORE INSERT ON rezervacija
FOR EACH ROW
BEGIN
    -- Provjera: Datum odlaska mora biti nakon datuma dolaska
    IF NEW.kraj_datum <= NEW.pocetak_datum THEN
        SIGNAL SQLSTATE '45000'
        SET MESSAGE_TEXT = 'Greška: Datum odlaska mora biti nakon datuma dolaska!';
    END IF;
END //

DELIMITER ;

-- test test test

-- INSERT INTO rezervacija
-- (gost_nositelj_id, zaposlenik_id, soba_id, promocija_id, datum_rezervacije,
--  pocetak_datum, kraj_datum, broj_osoba, status, napomena)
-- VALUES
-- (1, 1, 1, NULL, NOW(),
--  '2026-07-12', '2026-07-10', 2, 'POTVRDJENA', 'TEST: kraj prije pocetka (mora pasti)');


-- 2. okidac za sprijecavanje ranog checkina



DELIMITER //

CREATE TRIGGER trg_sprijeci_rani_checkin
BEFORE UPDATE ON rezervacija
FOR EACH ROW
BEGIN
    -- Provjera se vrši SAMO ako se status mijenja na 'U_TIJEKU' (dakle radi se Check-In)
    IF NEW.status = 'U_TIJEKU' AND OLD.status != 'U_TIJEKU' THEN
        
        -- Ako je današnji datum (CURDATE) manji od datuma početka rezervacije
        IF CURDATE() < NEW.pocetak_datum THEN
            SIGNAL SQLSTATE '45000'
            SET MESSAGE_TEXT = 'Greška: Check-in nije moguć prije datuma početka rezervacije!';
        END IF;
        
    END IF;
END //

DELIMITER ;

-- test test test 

-- SELECT * FROM rezervacija;
-- UPDATE rezervacija
-- SET status = 'U_TIJEKU'
-- WHERE id = 18;  



DELIMITER //

CREATE TRIGGER trg_auto_ciscenje_nakon_checkouta
AFTER UPDATE ON rezervacija
FOR EACH ROW
BEGIN
    -- Provjeravamo je li se status upravo promijenio u 'ZAVRSENA' (Check-out)
    IF NEW.status = 'ZAVRSENA' AND OLD.status != 'ZAVRSENA' THEN
        
        -- Automatski postavi status pripadajuće sobe na 'CISCENJE'
        UPDATE soba
        SET status = 'CISCENJE'
        WHERE id = NEW.soba_id;
        
    END IF;
END //

DELIMITER ;

-- test test test

-- SELECT id, soba_id, status
-- FROM rezervacija;

-- UPDATE rezervacija
-- SET status = 'ZAVRSENA'
-- WHERE id = 16;

-- SELECT id, status
-- FROM soba
-- WHERE id = (SELECT soba_id FROM rezervacija WHERE id = 16);



DELIMITER //

CREATE TRIGGER trg_sprijeci_rezervaciju_kvar
BEFORE INSERT ON rezervacija
FOR EACH ROW
BEGIN
    DECLARE v_status_sobe VARCHAR(20);

    -- Dohvati trenutni status sobe
    SELECT status INTO v_status_sobe 
    FROM soba 
    WHERE id = NEW.soba_id;

    -- Provjera: Je li soba pokvarena ILI se čisti?
    IF v_status_sobe IN ('IZVAN_FUNKCIJE', 'CISCENJE') THEN
        SIGNAL SQLSTATE '45000'
        SET MESSAGE_TEXT = 'Greška: Soba nije dostupna (Status je ČIŠĆENJE ili IZVAN FUNKCIJE)!';
    END IF;
END //

DELIMITER ;

-- TEST TEST TEST 

-- SELECT * from soba;
-- INSERT INTO rezervacija
-- (gost_nositelj_id, zaposlenik_id, soba_id, promocija_id, datum_rezervacije,
--  pocetak_datum, kraj_datum, broj_osoba, status, napomena)
-- VALUES
-- (1, 1, 6, NULL, NOW(),
--  '2030-01-10', '2030-01-12', 2, 'POTVRDJENA', 'TEST: soba nedostupna');




