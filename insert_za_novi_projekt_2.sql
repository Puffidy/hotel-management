USE novi_projekt;

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


-- 5. ZAPOSLENIK
INSERT INTO zaposlenik
(id, odjel_id, ime, prezime, tel_kontakt, pozicija, je_voditelj_odjela, korisnicko_ime, lozinka_hash)
VALUES
-- 1 Recepcija
(1,1,'Iva','Ivic','099111111','Recepcioner',0,'iva.ivic','pass123'),
(2,1,'Luka','Lukic','099222222','Voditelj recepcije',1,'luka.lukic','admin123'),
(3,1,'Maja','Majic','099101010','Recepcioner',0,'maja.majic','pass123'),
(4,1,'Ivan','Ilic','099101011','Recepcioner',0,'ivan.ilic','pass123'),
(5,1,'Tea','Teic','099101012','Nocni recepcioner',0,'tea.teic','pass123'),
(6,1,'Nikola','Ninic','099101013','Agent rezervacija',0,'nikola.ninic','pass123'),

-- 2 Domacinstvo
(7,2,'Marija','Maricic','099333333','Sobarica',0,'marija.maricic','pass123'),
(8,2,'Nina','Ninic','099333444','Sobarica',0,'nina.ninic','pass123'),
(9,2,'Katarina','Katic','099202020','Sobarica',0,'katarina.katic','pass123'),
(10,2,'Ivana','Ivanic','099202021','Sobarica',0,'ivana.ivanic','pass123'),
(11,2,'Sandra','Sandric','099202022','Nadzornica domacinstva',1,'sandra.sandric','pass123'),
(12,2,'Dora','Doric','099202023','Pranje i peglaonica',0,'dora.doric','pass123'),

-- 3 Odrzavanje
(13,3,'Tomo','Tomic','099444444','Serviser',0,'tomo.tomic','pass123'),
(14,3,'Mario','Marincic','099555555','Voditelj odrzavanja',1,'mario.marincic','pass123'),
(15,3,'Stjepan','Stipic','099303030','Tehnicar',0,'stjepan.stipic','pass123'),
(16,3,'Ante','Antic','099303031','Elektricar',0,'ante.antic','pass123'),
(17,3,'Josip','Jovic','099303032','Vodoinstalater',0,'josip.jovic','pass123'),
(18,3,'Filip','Filipovic','099303033','Tehnicar klimatizacije',0,'filip.filipovic','pass123'),

-- 4 Uprava
(19,4,'Ivana','Ivancic','099666666','Direktor',1,'ivana.ivancic','admin123'),
(20,4,'Petra','Petric','099777777','Racunovodstvo',0,'petra.petric','pass123'),
(21,4,'Marko','Maric','099404040','Voditelj financija',0,'marko.maric','pass123'),
(22,4,'Lucija','Lucic','099404041','Administracija',0,'lucija.lucic','pass123'),
(23,4,'Ena','Enic','099404042','HR referent',0,'ena.enic','pass123'),
(24,4,'Bruno','Brunic','099404043','Kontroling',0,'bruno.brunic','pass123'),

-- 5 Restoran i Bar
(25,5,'Marko','Markovic','099888888','Konobar',0,'marko.markovic','pass123'),
(26,5,'Ana','Anic','099999999','Sef kuhinje',1,'ana.anic','pass123'),
(27,5,'Karlo','Karlic','099505050','Konobar',0,'karlo.karlic','pass123'),
(28,5,'Lana','Lanic','099505051','Konobar',0,'lana.lanic','pass123'),
(29,5,'Mia','Miic','099505052','Barmen',0,'mia.miic','pass123'),
(30,5,'Dario','Darik','099505053','Pomocni kuhar',0,'dario.darik','pass123');
;


-- 6. GOST
INSERT INTO gost
(id, ime, prezime, vrsta_dokumenta_id, broj_dokumenta, prebivaliste_drzava_id, prebivaliste_grad_id, prebivaliste_adresa, datum_rodjenja, drzavljanstvo, vip_status)
VALUES
(1,'Ana','Anic',1,'AA12345',1,1,'Ilica 12','1990-02-15','Hrvat',1),
(2,'Ivica','Ivicic',2,'BB22345',1,2,'Put Mora 5','1988-07-21','Hrvat',0),
(3,'Marko','Maric',1,'MM44556',1,3,'Kvarnerska 7','1995-01-01','Hrvat',0),
(4,'Darko','Daric',2,'DD99887',2,3,'Ulica 1','1989-03-12','Bosanac',0),
(5,'Ena','Enic',1,'EE23232',3,5,'Nemanjina 10','1992-09-10','Srbin',1),
(6,'Filip','Filipic',1,'FF11111',1,1,'Ilica 88','1993-05-19','Hrvat',0),
(7,'Goran','Goric',2,'GG22222',1,2,'Primorska 6','1985-10-10','Hrvat',0),
(8,'Helena','Helnic',1,'HH33333',1,3,'Trg Europe 2','2000-05-05','Hrvat',0),
(9,'Ivan','Ivanovic',1,'II44444',2,3,'Aleja 9','1987-08-08','Bosanac',0),
(10,'Jasna','Jasincic',2,'JJ55555',3,5,'Centar bb','1991-09-09','Srbin',0),
(11,'Karlo','Karlic',1,'KK66666',1,1,'Maksimirska 55','1996-04-04','Hrvat',0),
(12,'Lana','Lanic',2,'LL77777',1,4,'Obala 18','1984-12-12','Hrvat',0),
(13,'Mirko','Mirkic',1,'MM88888',1,3,'Korzo 3','1997-06-06','Hrvat',0),
(14,'Nemanja','Nemanjovic',1,'NN99999',3,5,'Bulevar 1','1993-03-03','Srbin',0),
(15,'Zara','Zaric',1,'OO11223',2,3,'Mejtash 7','1986-02-02','Bosanac',0),
(16,'Petar','Petric',2,'PP44556',1,1,'Savska 77','1994-05-05','Hrvat',0),
(17,'Renata','Renatic',1,'RR55667',1,2,'Katin Put 22','2003-05-05','Hrvat',0),
(18,'Sara','Saric',2,'SS66778',1,3,'Uvala 6','1992-09-15','Hrvat',0),
(19,'Tomica','Tomcic',1,'TT77889',3,5,'Vozdovacka 3','1985-05-17','Srbin',0),
(20,'Klara','Klaric',1,'UU88990',2,3,'Ferhadija 10','2001-03-03','Bosanac',0),
(21,'Vedran','Vedric',2,'VV99001',1,1,'Tresnjevacka 8','1995-07-07','Hrvat',0),
(22,'Zarko','Zarkic',2,'ZZ20202',1,3,'Susacka 9','1987-04-09','Hrvat',0),
(23,'Adrian','Adric',2,'AD30303',4,7,'Via Roma 2','1999-08-11','Talijan',0),
(24,'Bruno','Brunovic',2,'BR40404',2,3,'Ilidza 19','1988-02-28','Bosanac',0),
(25,'Sandra','Sandric',1,'SA50505',1,1,'Trnje 3','1994-03-22','Hrvat',0),
(26,'Dora','Doric',2,'DO60606',1,4,'Marjan 13','1998-06-18','Hrvat',0),
(27,'Ema','Emic',1,'EM70707',1,3,'Kastavska 4','2010-10-10','Hrvat',0),
(28,'Franjo','Franjcic',2,'FR80808',5,9,'Prenzlauer 1','1993-12-30','Njemac',0),
(29,'John','Doe',2,'JD90909',6,11,'Baker Street 15','1980-05-05','Britanac',1),
(30,'Peter','Peterowski',2,'PP73280',6,12,'Oxford 3','1980-05-05','Britanac',0),
(31,'Tena','Tencic',1,'TE11111',1,2,'Pulska 1','1992-11-11','Hrvat',0),
(32,'Igor','Igorovic',2,'IG22222',1,2,'Kandlerova 7','1989-04-23','Hrvat',0),
(33,'Mate','Matic',1,'MA30001',1,5,'Stradun 1','1990-01-10','Hrvat',0),
(34,'Nika','Nikic',1,'NI30002',1,2,'Riva 12','1997-03-14','Hrvat',0),
(35,'Kristina','Krizic',2,'KR30003',7,13,'Trg 5','1991-06-20','Slovenac',0),
(36,'Boris','Boric',2,'BO30004',9,17,'Rakoczi 10','1986-09-09','Madjar',0),
(37,'Elena','Elenic',1,'EL30005',8,15,'Ring 2','1995-12-01','Austrijanac',0),
(38,'Milan','Milic',2,'MI30006',10,19,'Obala 4','1983-02-18','Crnogorac',0),
(39,'Sofija','Sofic',2,'SO30007',11,21,'Centar 7','1994-07-07','Makedonac',0),
(40,'Arben','Arbeni',2,'AR30008',12,23,'Bulevar 1','1988-08-08','Albanac',0),
(41,'Giorgio','Rossi',2,'GI30009',4,8,'Corso 9','1987-05-15','Talijan',0),
(42,'Pierre','Dubois',2,'PI30010',14,27,'Rue 1','1992-10-10','Francuz',0),
(43,'Carlos','Garcia',2,'CA30011',15,29,'Calle 8','1993-11-11','Spanjolac',0),
(44,'Joao','Silva',2,'JO30012',16,31,'Rua 3','1989-04-04','Portugalac',0),
(45,'Sven','Svensson',2,'SV30013',20,39,'Main 2','1996-06-06','Svedjanin',0),
(46,'Ola','Hansen',2,'OH30014',21,41,'Gate 5','1985-01-01','Norvezanin',0),
(47,'Piotr','Kowalski',2,'PK30015',25,49,'Ulica 2','1991-02-02','Poljak',0),
(48,'Elif','Yilmaz',2,'EY30016',30,59,'Ataturk 10','1998-09-09','Turcin',0),
(49,'Mia','Mikic',1,'MM30017',1,4,'Korzo 12','1999-12-12','Hrvat',1),
(50,'Ayse','Kaya',2,'AK40002',30,60,'Istiklal 20','1996-01-16','Turcin',0);


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
(1,'2026-04-01','2026-09-30',75.00,2.00),
(1,'2026-10-01','2027-03-31',55.00,2.00),
-- 2 Double
(2,'2026-04-01','2026-09-30',115.00,2.00),
(2,'2026-10-01','2027-03-31',85.00,2.00),
-- 3 Twin
(3,'2026-04-01','2026-09-30',115.00,2.00),
(3,'2026-10-01','2027-03-31',85.00,2.00),
-- 4 Triple
(4,'2026-04-01','2026-09-30',160.00,2.00),
(4,'2026-10-01','2027-03-31',120.00,2.00),
-- 5 Family
(5,'2026-04-01','2026-09-30',190.00,2.00),
(5,'2026-10-01','2027-03-31',140.00,2.00),
-- 6 Suite
(6,'2026-04-01','2026-09-30',280.00,2.00),
(6,'2026-10-01','2027-03-31',200.00,2.00),
-- 7 Junior Suite
(7,'2026-04-01','2026-09-30',230.00,2.00),
(7,'2026-10-01','2027-03-31',170.00,2.00),
-- 8 Deluxe Double
(8,'2026-04-01','2026-09-30',155.00,2.00),
(8,'2026-10-01','2027-03-31',115.00,2.00),
-- 9 Superior Double
(9,'2026-04-01','2026-09-30',135.00,2.00),
(9,'2026-10-01','2027-03-31',100.00,2.00),
-- 10 Superior Twin
(10,'2026-04-01','2026-09-30',135.00,2.00),
(10,'2026-10-01','2027-03-31',100.00,2.00),
-- 11 Economy Single
(11,'2026-04-01','2026-09-30',60.00,2.00),
(11,'2026-10-01','2027-03-31',45.00,2.00),
-- 12 Economy Double
(12,'2026-04-01','2026-09-30',95.00,2.00),
(12,'2026-10-01','2027-03-31',70.00,2.00),
-- 13 Quadruple
(13,'2026-04-01','2026-09-30',205.00,2.00),
(13,'2026-10-01','2027-03-31',150.00,2.00),
-- 14 Penthouse Suite
(14,'2026-04-01','2026-09-30',480.00,2.00),
(14,'2026-10-01','2027-03-31',350.00,2.00),
-- 15 Accessible Double
(15,'2026-04-01','2026-09-30',120.00,2.00),
(15,'2026-10-01','2027-03-31',90.00,2.00),
-- 16 Double + Extra Bed
(16,'2026-04-01','2026-09-30',145.00,2.00),
(16,'2026-10-01','2027-03-31',110.00,2.00),
-- 17 Twin + Extra Bed
(17,'2026-04-01','2026-09-30',145.00,2.00),
(17,'2026-10-01','2027-03-31',110.00,2.00),
-- 18 Studio
(18,'2026-04-01','2026-09-30',170.00,2.00),
(18,'2026-10-01','2027-03-31',125.00,2.00),
-- 19 Executive Suite
(19,'2026-04-01','2026-09-30',330.00,2.00),
(19,'2026-10-01','2027-03-31',240.00,2.00),
-- 20 Honeymoon Suite
(20,'2026-04-01','2026-09-30',360.00,2.00),
(20,'2026-10-01','2027-03-31',260.00,2.00);



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
--Kontinentalni
(8,1,2.00),
(8,2,1.00),
(8,3,0.01),
(8,5,0.20),
-- 
-- 4 Salata/Piletina
(4,16,0.40),
(4,9,0.25),
(4,17,0.30),
(4,15,0.05),
(4,14,0.50),
(4,18,0.02),


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

-- 15. PROMOCIJA 
INSERT INTO promocija (id, naziv, kod_kupona, popust_postotak, datum_pocetka, datum_zavrsetka) VALUES
(1, 'Zimski popust', 'ZIMA24', 10.00, '2024-01-01', '2024-02-28'),
(2, 'Ljeto rani booking', 'LJETO25', 15.00, '2025-01-01', '2025-05-01'),
(3, 'Business ponuda', 'BUSINESS25', 10.00, '2025-01-01', '2025-12-31'),
(4, 'Obiteljska čarolija', 'FAMILYFUN', 12.00, '2025-01-01', '2025-06-30');

-- 16. REZERVACIJA 
INSERT INTO rezervacija (id, gost_nositelj_id, zaposlenik_id, soba_id, promocija_id, datum_rezervacije, pocetak_datum, kraj_datum, vrijeme_check_in, vrijeme_check_out, broj_osoba, status, napomena) VALUES
-- ZAVRSENE (Imaju check-in/out)

-- 17. RESTORAN_NARUDZBA 
INSERT INTO restoran_narudzba (zaposlenik_id, restoran_stol_id, rezervacija_smjestaj_id, status) VALUES


-- 18. RESTORAN_STAVKA 
INSERT INTO restoran_stavka (narudzba_id, usluga_id, kolicina, cijena_u_trenutku) VALUES

-- 19. REZERVACIJA_GOST 
INSERT INTO rezervacija_gost (rezervacija_id, gost_id) VALUES


-- 20. LOG_REZERVACIJE 
INSERT INTO log_rezervacije (rezervacija_id, stari_status, novi_status, korisnik_db) VALUES


/*
-- 6. FINANCIJE
*/

-- 21. RACUN
INSERT INTO racun (id, rezervacija_id, datum_izdavanja, nacin_placanja, iznos_ukupno) VALUES


-- 22. STAVKA_RACUNA
INSERT INTO stavka_racuna (racun_id, usluga_id, tip_stavke, opis, kolicina, cijena_jedinicna, iznos_ukupno) VALUES


/*
-- 7. ODRŽAVANJE I FEEDBACK
*/

-- 23. CISCENJE_DNEVNI_NALOG
INSERT INTO ciscenje_dnevni_nalog (zaposlenik_id, rezervacija_id, prijavljena_steta, opis_stete, obavljeno) VALUES


-- 24. SERVIS_DNEVNI_NALOG
INSERT INTO servis_dnevni_nalog (zaposlenik_id, soba_id, korisnik_placa, opis, rijeseno) VALUES


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
