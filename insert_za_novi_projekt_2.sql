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
INSERT INTO grad (id, naziv, drzava_id) VALUES
(1,'Zagreb',1), (2,'Pula',1), (3,'Split',1), (4,'Rijeka',1), (5,'Dubrovnik',1),
(6,'Sarajevo',2), (7,'Mostar',2), (8,'Beograd',3), (9,'Novi Sad',3),
(10,'Rim',4), (11,'London',6), (12,'Ljubljana',7), (13,'Berlin',5);

-- 3. VRSTA_DOKUMENTA
INSERT INTO vrsta_dokumenta (id, naziv) VALUES
(1,'Osobna iskaznica'), (2,'Putovnica'), (3,'Vozacka dozvola');

/*
-- 2. ORGANIZACIJA I LJUDI
*/

-- 4. ODJEL
INSERT INTO odjel (id, naziv, tel_kontakt, lokalni) VALUES
(1,'Recepcija','010/100-100',100),
(2,'Domaćinstvo','010/100-200',200),
(3,'Održavanje','010/100-300',300),
(4,'Uprava','010/100-400',400),
(5,'Restoran i Bar','010/100-500',500); -- NOVI ODJEL

-- 5. ZAPOSLENIK
INSERT INTO zaposlenik (id, odjel_id, ime, prezime, tel_kontakt, pozicija, je_voditelj_odjela, korisnicko_ime, lozinka_hash) VALUES
(1,1,'Iva','Ivic','099111111','Recepcioner',0, 'iva.ivic', 'pass123'),
(2,1,'Luka','Lukic','099222222','Voditelj recepcije',1, 'luka.lukic', 'admin123'),
(3,2,'Marija','Maricic','099333333','Spremacica',0, 'marija.m', 'pass123'),
(4,2,'Nina','Ninic','099333444','Spremacica',0, 'nina.n', 'pass123'),
(5,3,'Tomo','Tomic','099444444','Serviser',0, 'tomo.t', 'pass123'),
(6,3,'Mario','Marincic','099555555','Voditelj odrzavanja',1, 'mario.m', 'pass123'),
(7,4,'Ivana','Ivancic','099666666','Direktor',1, 'ivana.i', 'admin123'),
(8,4,'Petra','Petric','099777777','Racunovodstvo',0, 'petra.p', 'pass123'),
(9,5,'Marko','Markovic','099888888','Konobar',0, 'marko.m', 'pass123'), 
(10,5,'Ana','Anic','099999999','Sef kuhinje',1, 'ana.a', 'pass123'); 

-- 6. GOST
INSERT INTO gost (id, ime, prezime, vrsta_dokumenta_id, broj_dokumenta, prebivaliste_drzava_id, prebivaliste_grad_id, prebivaliste_adresa, datum_rodjenja, drzavljanstvo, vip_status) VALUES
(1,'Ana','Anic',1,'AA12345',1,1,'Ilica 12','1990-02-15','HR', 1), 
(2,'Ivica','Ivicic',2,'BB22345',1,2,'Put Mora 5','1988-07-21','HR', 0),
(3,'Marko','Maric',1,'MM44556',1,3,'Kvarnerska 7','1995-01-01','HR', 0),
(4,'Darko','Daric',2,'DD99887',2,5,'Ulica 1','1989-03-12','BIH', 0),
(5,'Ena','Enic',1,'EE23232',3,7,'Nemanjina 10','1992-09-10','RS', 1), 
(6,'Filip','Filipic',1,'FF11111',1,1,'Ilica 88','1993-05-19','HR', 0),
(7,'Goran','Goric',2,'GG22222',1,2,'Primorska 6','1985-10-10','HR', 0),
(8,'Helena','Helnic',1,'HH33333',1,3,'Trg Europe 2',NULL,'HR', 0),
(9,'Ivan','Ivanovic',1,'II44444',2,6,'Aleja 9','1987-08-08','BIH', 0),
(10,'Jasna','Jasincic',2,'JJ55555',3,8,'Centar bb','1991-09-09','RS', 0),
(11,'Karlo','Karlic',1,'KK66666',1,1,'Maksimirska 55','1996-04-04','HR', 0),
(12,'Lana','Lanic',2,'LL77777',1,4,'Obala 18','1984-12-12','HR', 0),
(13,'Mirko','Mirkic',1,'MM88888',1,3,'Korzo 3','1997-06-06','HR', 0),
(14,'Nemanja','Nemanjovic',1,'NN99999',3,7,'Bulevar 1','1993-03-03','RS', 0),
(15,'Zara','Zaric',1,'OO11223',2,5,'Mejtash 7','1986-02-02','BIH', 0),
(16,'Petar','Petric',2,'PP44556',1,1,'Savska 77','1994-05-05','HR', 0),
(17,'Renata','Renatic',1,'RR55667',1,2,'Katin Put 22',NULL,'HR', 0),
(18,'Sara','Saric',2,'SS66778',1,3,'Uvala 6','1992-09-15','HR', 0),
(19,'Tomica','Tomcic',1,'TT77889',3,8,'Voždovacka 3','1985-05-17','RS', 0),
(20,'Klara','Klaric',1,'UU88990',2,5,'Ferhadija 10',NULL,'BIH', 0),
(21,'Vedran','Vedric',2,'VV99001',1,1,'Tresnjevacka 8','1995-07-07','HR', 0),
(22,'Zara','Zaric',1,'ZZ10101',1,2,'Bacvice 12','1991-01-21','HR', 0),
(23,'Zarko','Zarkic',2,'ZZ20202',1,3,'Susacka 9','1987-04-09','HR', 0),
(24,'Adrian','Adric',2,'AA30303',4,9,'Via Roma 2','1999-08-11','IT', 0),
(25,'Bruno','Brunovic',2,'BB40404',2,6,'Ilidza 19','1988-02-28','BIH', 0),
(26,'Sandra','Sandric',1,'CC50505',1,1,'Trnje 3','1994-03-22','HR', 0),
(27,'Dora','Doric',2,'DD60606',1,4,'Marjan 13','1998-06-18','HR', 0),
(28,'Ema','Emic',1,'EE70707',1,3,'Kastavska 4',NULL,'HR', 0),
(29,'Franjo','Franjcic',2,'FF80808',5,10,'Prenzlauer 1','1993-12-30','DE', 0),
(30,'John','Doe',2,'JS90909',1,1,'Radnicka 15','1980-05-05','UK', 1),
(31,'Peter','Peterowski',2,'AB7328',1,1,'Radnicka 15','1980-05-05','UK', 0),
(32,'Tena','Tencic',1,'AP11111',1,2,'Pulska 1','1992-11-11','HR', 0),
(33,'Igor','Igorovic',2,'IG22222',1,2,'Kandlerova 7','1989-04-23','HR', 0);

/*
-- 3. SMJEŠTAJNI KAPACITETI
*/

-- 7. TIP_SOBA
INSERT INTO tip_sobe (id, naziv, opis, standardni_kapacitet) VALUES
(1,'Single','Jednokrevetna',1), (2,'Double','Dvokrevetna',2),
(3,'Triple','Trokrevetna',3), (4,'Suite','Apartman',4);

-- 8. SOBA
INSERT INTO soba (id, broj, tip_sobe_id, kapacitet_osoba, kat, minibar, balkon, status) VALUES
(1,101,1,1,1,0,0,'SLOBODNA'), (2,102,1,1,1,0,0,'ZAUZETA'),
(3,103,2,2,1,1,0,'SLOBODNA'), (4,104,2,2,1,1,0,'IZVAN_FUNKCIJE'),
(5,105,2,2,1,1,1,'SLOBODNA'), (6,201,3,3,2,1,0,'ZAUZETA'),
(7,202,3,3,2,1,0,'SLOBODNA'), (8,203,3,3,2,1,1,'SLOBODNA'),
(9,204,2,2,2,1,1,'ZAUZETA'), (10,205,1,1,2,0,0,'SLOBODNA'),
(11,301,4,4,3,1,1,'SLOBODNA'), (12,302,4,4,3,1,1,'ZAUZETA'),
(13,303,4,4,3,1,1,'SLOBODNA'), (14,304,2,2,3,1,0,'IZVAN_FUNKCIJE'),
(15,305,2,2,3,1,0,'SLOBODNA'), (16,401,1,1,4,0,0,'SLOBODNA'),
(17,402,2,2,4,1,1,'ZAUZETA'), (18,403,3,3,4,1,0,'SLOBODNA'),
(19,404,4,4,4,1,1,'SLOBODNA'), (20,405,2,2,4,1,0,'SLOBODNA');

-- 9. CJENIK_SOBA
INSERT INTO cjenik_soba (tip_sobe_id, datum_od, datum_do, cijena_nocenja, boravisna_pristojba_po_osobi) VALUES
(1,'2025-01-01','2025-05-31',50.00,2.00), (1,'2025-06-01','2025-09-30',70.00,2.00),
(2,'2025-01-01','2025-05-31',80.00,2.00), (2,'2025-06-01','2025-09-30',110.00,2.00),
(3,'2025-01-01','2025-05-31',100.00,2.00), (3,'2025-06-01','2025-09-30',140.00,2.00),
(4,'2025-01-01','2025-05-31',150.00,2.00), (4,'2025-06-01','2025-09-30',220.00,2.00);

/*
-- 4. USLUGE, RESTORAN I SKLADIŠTE
*/

-- 10. KATEGORIJA_USLUGE (Hrana, Piće, Wellness...)
INSERT INTO kategorija_usluge (id, naziv) VALUES 
(1, 'Hrana'), (2, 'Pice'), (3, 'Wellness'), (4, 'Ostalo');

-- 11. USLUGA 
INSERT INTO usluga (id, kategorija_id, naziv, opis, jedinica_mjere, cijena_trenutna) VALUES
(1, 1, 'Dorucak','Svedski stol','kom', 10.00),
(2, 1, 'Polupansion','Dorucak i vecera','dan', 25.00),
(3, 4, 'Parking','Dnevni parking','dan', 5.00),
(4, 3, 'Spa','Koristenje spa tretmana','kom', 15.00),
(5, 4, 'Najam bicikla','Najam bicikla po danu','dan', 7.00),
(6, 1, 'Room service','Posluga u sobu','kom', 8.00),
(7, 4, 'Najam vozila','Najam vozila po danu','dan', 40.00),
(8, 2, 'Kava','Espresso','kom', 2.00), -- NOVO
(9, 2, 'Coca Cola','0.25l','kom', 3.50); -- NOVO

-- 12. ARTIKL
INSERT INTO artikl (id, naziv, stanje_zaliha, jedinica_mjere, nabavna_cijena) VALUES
(1, 'Jaja', 1000, 'kom', 0.20),
(2, 'Kruh', 50, 'kg', 1.50),
(3, 'Kava u zrnu', 20, 'kg', 15.00),
(4, 'Coca Cola Boca', 200, 'kom', 1.00),
(5, 'Mlijeko', 100, 'lit', 0.90),
(6, 'Bicikl', 10, 'kom', 200.00),
(7, 'Mljeveno meso', 10, 'kg', 12.00),
(8, 'Slanina', 12, 'kg', 20.00),
(9, 'Limuni', 2, 'kg', 1.00),
(10, 'Čaj od mente u vrečicama', 25, 'kom', 0.17),
(11, 'Plasma keksi', 15, 'kom', 2.50),
(12, 'Riža', 10, 'kg', 1.00),
(13, 'Sir - Gauda', 1, 'kg', 10.15),
(14, 'Srdele', 9, 'kg', 20.00),
(15, 'Hobotnica', 10, 'kg', 30.00),
(16, 'Parmezan-ribani', 2, 'kg', 72.00),
(17, 'Pjenušac Freixenet Premium Carta', 6, 'kom', 8.00),
(18, 'Korlat Syrah Vrhunsko', 3, 'kom', 17.00),
(19, 'Kutjevo Graševina', 7, 'kom', 8.00),
(20, 'Dimmes Drniški pršut', 5, 'kg', 32.00);

-- 13. NORMATIV
INSERT INTO normativ (usluga_id, artikl_id, kolicina_potrosnje) VALUES
(1, 1, 2.00), -- Doručak troši 2 jaja
(1, 2, 0.20), -- Doručak troši 0.2kg kruha
(8, 3, 0.01), -- Kava troši 0.01kg zrna
(9, 4, 1.00); -- Cola troši 1 bocu

-- 14. RESTORAN_STOL 
INSERT INTO restoran_stol (id, broj_stola, broj_mjesta, lokacija) VALUES
(1, 1, 4, 'Terasa'), (2, 2, 2, 'Terasa'), (3, 3, 4, 'Unutra'), (4, 4, 6, 'Unutra');

/*
-- 5. REZERVACIJE I MARKETING
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
(1,1,1,3,1, '2024-01-05', '2024-01-10', '2024-01-12', '2024-01-10 15:00:00', '2024-01-12 10:00:00', 1, 'ZAVRSENA', 'Poslovni boravak'),
(2,2,1,5,NULL, '2024-02-01', '2024-02-15', '2024-02-18', '2024-02-15 14:00:00', '2024-02-18 11:00:00', 2, 'ZAVRSENA', NULL),
(3,3,2,11,NULL,'2024-03-03', '2024-03-20', '2024-03-25', '2024-03-20 16:00:00', '2024-03-25 09:00:00', 2, 'ZAVRSENA', 'Godišnji'),
-- POTVRDJENE (Nemaju check-in/out još)
(13,13,1,5,2,'2025-01-15', '2025-06-01', '2025-06-05', NULL, NULL, 2, 'POTVRDJENA', NULL),
(14,14,1,9,NULL,'2025-02-10', '2025-07-20', '2025-07-25', NULL, NULL, 1, 'POTVRDJENA', 'Tiha soba'),
-- U TIJEKU (Imaju check-in, nemaju check-out)
(16,16,1,6,NULL,'2025-04-01', '2025-12-05', '2025-12-10', '2025-12-05 13:00:00', NULL, 2, 'U_TIJEKU', NULL);

-- 17. RESTORAN_NARUDZBA 
INSERT INTO restoran_narudzba (zaposlenik_id, restoran_stol_id, rezervacija_smjestaj_id, status) VALUES
(9, 1, 1, 'NAPLACENA'), -- Gost iz rez 1 je jeo
(9, 3, NULL, 'OTVORENA'); -- Gost s ceste

-- 18. RESTORAN_STAVKA 
INSERT INTO restoran_stavka (narudzba_id, usluga_id, kolicina, cijena_u_trenutku) VALUES
(1, 1, 2, 10.00), -- 2 Doručka
(1, 8, 2, 2.00);  -- 2 Kave

-- 19. REZERVACIJA_GOST 
INSERT INTO rezervacija_gost (rezervacija_id, gost_id) VALUES
(2, 29), (3, 12), (13, 17);

-- 20. LOG_REZERVACIJE 
INSERT INTO log_rezervacije (rezervacija_id, stari_status, novi_status, korisnik_db) VALUES
(1, 'POTVRDJENA', 'U_TIJEKU', 'iva.ivic'),
(1, 'U_TIJEKU', 'ZAVRSENA', 'luka.lukic');

/*
-- 6. FINANCIJE
*/

-- 21. RACUN
INSERT INTO racun (id, rezervacija_id, datum_izdavanja, nacin_placanja, iznos_ukupno) VALUES
(1,1,'2024-01-12 10:00:00','KARTICA',220.00),
(2,2,'2024-02-18 12:00:00','GOTOVINA',450.00),
(3,3,'2024-03-25 09:30:00','VIRMANSKI',800.00);

-- 22. STAVKA_RACUNA
INSERT INTO stavka_racuna (racun_id, usluga_id, tip_stavke, opis, kolicina, cijena_jedinicna, iznos_ukupno) VALUES
(1,NULL,'NOCENJE','Nocenje Single',2,50.00,100.00),
(1,1,'USLUGA','Dorucak',2,10.00,20.00), 
(1,NULL,'BORAVISNA_PRISTOJBA','Taksa',2,2.00,4.00),
(2,NULL,'NOCENJE','Nocenje Double',3,80.00,240.00),
(2,4,'USLUGA','Spa Tretman',1,15.00,15.00);

/*
-- 7. ODRŽAVANJE I FEEDBACK
*/

-- 23. CISCENJE_DNEVNI_NALOG
INSERT INTO ciscenje_dnevni_nalog (zaposlenik_id, rezervacija_id, prijavljena_steta, opis_stete, obavljeno) VALUES
(3, 1, 0, NULL, 1),
(4, 2, 1, 'Mrlja na tepihu', 1),
(4, 3, 0, NULL, 1),
(3, 4, 0, NULL, 1),
(3, 5, 1, 'Strgana čaša za vino', 1),
(3, 6, 0, NULL, 1),
(4, 7, 1, 'Poderali plahtu', 1),
(3, 8, 1, 'Zaštopan umivaonik', 0),
(3, 9, 0, NULL, 1),
(4, 10, 0, NULL, 1),
(4, 11, 0, NULL, 1),
(4, 12, 1, 'Rupe u fahu', 1),
(3, 13, 0, NULL, 1),
(4, 14, 0, NULL, 1),
(4, 15, 0, NULL, 1),
(3, 16, 1, 'Zaštopan WC', 0),
(4, 17, 0, NULL, 1),
(3, 18, 1, 'Mrlja na kauču od paradajza', 1),
(3, 19, 1, 'Rupe od čikova po tepihu', 1),
(4, 20, 0, NULL, 1);

-- 24. SERVIS_DNEVNI_NALOG
INSERT INTO servis_dnevni_nalog (zaposlenik_id, soba_id, korisnik_placa, opis, rijeseno) VALUES
(5, 4, 0, 'Popravak klime', 0),
(6, 11, 1, 'Slomljena stolica', 1)
(6, 5, 0, 'Postavljanje zamke za miševe', 1),
(6, 2, 1, 'Strgana kvaka od kupaonskih vrata', 1),
(5, 12, 0, 'Popravak radijatora, ventili ne rade', 0),
(6, 19, 0, 'Zamjena štekera', 1),
(5, 13, 0, 'Odštopavanje zahoda', 1),
(5, 16, 1, 'Popravak vrata od frižidera', 1), 
(5, 15, 1, 'Rupa u zidu', 1),
(6, 1, 0, 'Zamjena žarulje u lusteru', 1), 
(6, 3, 0, 'Zamjena baterija u daljinskom upravljaču', 1),
(6, 5, 0, 'Pogreb mrtvog miša', 0),
(5, 11, 1, 'Odštopavanje sudopera u kupaoni', 1),
(6, 10, 1, 'Popravak  televizora', 0),
(5, 9, 0, 'Namještanje roleta', 1),
(5, 17, 0, 'Zamjena lampice u pećnici', 1),
(6, 18, 1, 'Strgan mehanizam za otvaranje balkona', 0),
(5, 20, 0, 'Zamjena žarulje u stolnoj lampi', 1);

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
