import streamlit as st
import mysql.connector
import pandas as pd
from datetime import datetime
import time

# -----------------------------------------------------------------------------
# 1. POSTAVKE I SPAJANJE NA BAZU
# -----------------------------------------------------------------------------
def get_connection():
    return mysql.connector.connect(
        host="localhost",
        user="root",           # <--- TVOJ USER
        password="root",   # <--- TVOJA LOZINKA
        database="novi_projekt"
    )

# Funkcija za dohvat podataka (SELECT)
def run_query(query, params=None):
    conn = get_connection()
    try:
        df = pd.read_sql(query, conn, params=params)
        return df
    finally:
        conn.close()

# Funkcija za izvršavanje akcija (INSERT, UPDATE, PROCEDURE)
def run_action(query, params=None, is_procedure=False):
    conn = get_connection()
    cursor = conn.cursor()
    try:
        if is_procedure:
            cursor.callproc(query, params)
            # Za procedure koje vraćaju OUT parametre ili result setove
            # ovdje bi trebalo dodatno procesiranje, ali za naše void procedure je ok.
        else:
            cursor.execute(query, params)
        
        conn.commit()
        return True, "Uspješno izvršeno!"
    except mysql.connector.Error as err:
        return False, f"Greška iz baze: {err.msg}"
    finally:
        cursor.close()
        conn.close()

# -----------------------------------------------------------------------------
# 2. UI IZGLED
# -----------------------------------------------------------------------------
st.set_page_config(page_title="Hotel Manager Pro", layout="wide", page_icon="🏨")

st.title("🏨 Hotel Management Sustav")
st.markdown("---")

# Glavni izbornik s lijeve strane
menu = st.sidebar.radio(
    "Odaberi modul:",
    [
        "📅 RECEPCIJA (Rezervacije)", 
        "🍽️ RESTORAN (Narudžbe & Kuhinja)", 
        "📊 STANJE (Sobe i Logovi)",
        "📈 IZVJEŠTAJI (Financije & Zalihe)" 
    ]
)

# =============================================================================
# MODUL 1: RECEPCIJA - KREIRANJE, PREGLED I UPRAVLJANJE REZERVACIJAMA
# =============================================================================
if menu == "📅 RECEPCIJA (Rezervacije)":
    
    # SADA IMAMO 3 TABA: Nova, Lista (Upravljanje), Novi Gost
    tab_nova, tab_lista, tab_gost = st.tabs(["➕ Nova Rezervacija", "📋 Lista i Akcije", "👤 Novi Gost"])
    
    # --- TAB 1: NOVA REZERVACIJA ---
    with tab_nova:
        st.header("Nova Rezervacija")
        st.info("Ovdje kreirate novu rezervaciju. Sustav automatski računa cijenu i provjerava zauzeće.")

        # 1. Dohvat podataka
        gosti_df = run_query("SELECT id, ime, prezime FROM gost")
        sobe_df = run_query("SELECT id, broj, tip_sobe_id FROM soba")
        promocije_df = run_query("SELECT id, naziv, popust_postotak FROM promocija WHERE aktivna=1")

        # Rječnici za dropdown menije
        gost_dict = {f"{row['ime']} {row['prezime']} (ID: {row['id']})": row['id'] for i, row in gosti_df.iterrows()}
        soba_dict = {f"Soba {row['broj']}": row['id'] for i, row in sobe_df.iterrows()}
        promo_dict = {f"{row['naziv']} (-{row['popust_postotak']}%)": row['id'] for i, row in promocije_df.iterrows()}
        promo_dict["Nema promocije"] = None

        # 2. Forma
        with st.form("forma_rezervacija"):
            col1, col2 = st.columns(2)
            with col1:
                odabrani_gost_lbl = st.selectbox("Gost", list(gost_dict.keys()))
                odabrana_soba_lbl = st.selectbox("Soba", list(soba_dict.keys()))
                broj_osoba = st.number_input("Broj osoba", 1, 5, 2)
            
            with col2:
                odabrana_promo_lbl = st.selectbox("Promocija", list(promo_dict.keys()))
                datum_dolaska = st.date_input("Datum dolaska")
                datum_odlaska = st.date_input("Datum odlaska")
            
            napomena = st.text_area("Napomena", "Standardna rezervacija")

            # --- NOVO: Gumb za potvrdu ---
            submit_btn = st.form_submit_button("Potvrdi Rezervaciju")

        # --- NOVO: INFORMATIVNI IZRAČUN CIJENE (Izvan forme da se osvježava) ---
        if odabrana_soba_lbl and datum_dolaska and datum_odlaska:
            if datum_dolaska < datum_odlaska:
                s_id_calc = soba_dict[odabrana_soba_lbl]
                # Poziv SQL funkcije za izračun
                try:
                    df_calc = run_query(f"SELECT izracunaj_cijenu_smjestaja({s_id_calc}, '{datum_dolaska}', '{datum_odlaska}') as cijena")
                    if not df_calc.empty and df_calc.iloc[0]['cijena'] is not None:
                        cijena = df_calc.iloc[0]['cijena']
                        st.info(f"💰 Procijenjena cijena smještaja (bez boravišne): **{cijena} €**")
                except:
                    pass

        if submit_btn:
            # --- UKLONJENA PYTHON PROVJERA DATUMA ---
            # Šaljemo podatke ravno u bazu, neka se Trigger "trg_check_datumi_rezervacije" brine o tome!
            
            # Priprema podataka (int konverzija koju smo popravili)
            g_id = int(gost_dict[odabrani_gost_lbl])
            s_id = int(soba_dict[odabrana_soba_lbl])
            
            raw_promo_id = promo_dict[odabrana_promo_lbl]
            p_id = int(raw_promo_id) if raw_promo_id is not None else None
            br_osoba = int(broj_osoba)
            
            sql = """
                INSERT INTO rezervacija 
                (gost_nositelj_id, zaposlenik_id, soba_id, promocija_id, pocetak_datum, kraj_datum, broj_osoba, status, napomena)
                VALUES (%s, 1, %s, %s, %s, %s, %s, 'POTVRDJENA', %s)
            """ 
            
            params = (g_id, s_id, p_id, datum_dolaska, datum_odlaska, br_osoba, napomena)
            
            # Pokušaj izvršavanja
            success, msg = run_action(sql, params)
            
            if success:
                st.toast("✅ Rezervacija uspješno kreirana!", icon='📅')
                time.sleep(1)
                st.rerun()
            else:
                # Ovdje će se ispisati točna poruka koju si definirao u TRIGGERU
                # Npr: "Greška iz baze: Greška: Datum odlaska mora biti nakon datuma dolaska!"
                st.error(f"⛔ {msg}")

    # --- TAB 2: LISTA I AKCIJE (Check-in, Check-out, Otkazivanje) ---
    with tab_lista:
        st.subheader("Upravljanje Rezervacijama")
        
        # Filter
        status_filter = st.selectbox("Filtriraj po statusu:", ["SVI", "POTVRDJENA", "U_TIJEKU", "ZAVRSENA", "OTKAZANA"])
        
        sql = "SELECT * FROM pregled_svih_rezervacija WHERE 1=1"
        params = []
        if status_filter != "SVI":
            sql += " AND status = %s"
            params.append(status_filter)
        sql += " ORDER BY pocetak_datum DESC"
        
        df_rez = run_query(sql, params)
        
        # Boje za status
        def color_status(val):
            color = '#c8e6c9' if val == 'POTVRDJENA' else \
                    '#b3e5fc' if val == 'U_TIJEKU' else \
                    '#ffcdd2' if val == 'OTKAZANA' else ''
            return f'background-color: {color}'

        # Podjela ekrana: Lijevo tablica, Desno akcije
        col_list1, col_list2 = st.columns([3, 1])
        
        with col_list1:
            st.dataframe(
                df_rez.style.applymap(color_status, subset=['status']),
                use_container_width=True,
                height=600
            )
            
        with col_list2:
            st.write("### ⚙️ Akcije")
            if not df_rez.empty:
                # Dropdown za odabir rezervacije
                rez_options = df_rez['rezervacija_id'].tolist()
                odabrani_rez_id = st.selectbox("Odaberi ID:", rez_options)
                
                # Dohvati trenutni status odabrane rezervacije
                status_trenutni = df_rez[df_rez['rezervacija_id'] == odabrani_rez_id]['status'].values[0]
                st.info(f"Status: **{status_trenutni}**")
                
                st.markdown("---")

                # AKCIJA 1: Check-In
                if status_trenutni == 'POTVRDJENA':
                    if st.button("🛎️ Check-In"):
                        sql_in = "UPDATE rezervacija SET status = 'U_TIJEKU', vrijeme_check_in = NOW() WHERE id = %s"
                        success, msg = run_action(sql_in, [odabrani_rez_id])
                        if success:
                            st.success("Gost prijavljen!")
                            time.sleep(1)
                            st.rerun()
                        else:
                            st.error(msg)

                # AKCIJA 2: Check-Out
                if status_trenutni == 'U_TIJEKU':
                    if st.button("👋 Check-Out"):
                        sql_out = "UPDATE rezervacija SET status = 'ZAVRSENA', vrijeme_check_out = NOW() WHERE id = %s"
                        success, msg = run_action(sql_out, [odabrani_rez_id])
                        if success:
                            st.success("Gost odjavljen!")
                            time.sleep(1)
                            st.rerun()
                        else:
                            st.error(msg)
                            
                # AKCIJA 3: Otkazivanje (Procedura)
                if status_trenutni == 'POTVRDJENA':
                    if st.button("❌ Otkaži"):
                        success, msg = run_action("otkazi_rezervaciju", [odabrani_rez_id], is_procedure=True)
                        if success:
                            st.warning("Rezervacija otkazana.")
                            time.sleep(1)
                            st.rerun()
                        else:
                            st.error(msg)

    # --- TAB 3: NOVI GOST (POPRAVLJENO AŽURIRANJE) ---
    with tab_gost:
        st.header("Unos novog gosta")
        st.info("Unesite podatke o gostu.")

        # -- FORMA JE UKLONJENA ZA SELECTBOXEVE DA BUDU REAKTIVNI --
        
        ng_ime = st.text_input("Ime")
        ng_prezime = st.text_input("Prezime")
        
        col_dok, col_geo = st.columns(2)
        
        with col_dok:
            # Dokumenti
            dok_df = run_query("SELECT id, naziv FROM vrsta_dokumenta")
            if not dok_df.empty:
                dok_dict = {row['naziv']: row['id'] for i, row in dok_df.iterrows()}
                ng_dok_tip = st.selectbox("Vrsta dokumenta", list(dok_dict.keys()))
            else:
                ng_dok_tip = None
                
            ng_dok_broj = st.text_input("Broj dokumenta")
            ng_adresa = st.text_input("Adresa")

        with col_geo:
            # 1. Države - dodan key="drzava_select" da bude jedinstven
            drz_df = run_query("SELECT id, naziv FROM drzava ORDER BY naziv")
            
            if not drz_df.empty:
                drz_dict = {row['naziv']: row['id'] for i, row in drz_df.iterrows()}
                
                # Ovdje korisnik bira državu
                ng_drzava = st.selectbox("Država", list(drz_dict.keys()), index=0, key="drzava_select")
                
                # --- DEBUG: OVO ĆE TI POKAZATI ŠTO APLIKACIJA VIDI ---
                odabrani_id_drzave = drz_dict[ng_drzava]
                # st.caption(f"Debug: Odabran ID države je: {odabrani_id_drzave}") 
                # -----------------------------------------------------

                # 2. Gradovi - filtriraju se po odabranom ID-u
                grad_df = run_query("SELECT id, naziv FROM grad WHERE drzava_id = %s ORDER BY naziv", [odabrani_id_drzave])
                
                if grad_df.empty:
                    st.warning(f"Nema gradova u bazi za {ng_drzava}.")
                    grad_dict = {}
                    ng_grad = None
                else:
                    grad_dict = {row['naziv']: row['id'] for i, row in grad_df.iterrows()}
                    ng_grad = st.selectbox("Grad", list(grad_dict.keys()), key="grad_select")
            else:
                st.error("Tablica 'drzava' je prazna!")
                ng_drzava = None
                ng_grad = None

        st.markdown("---")
        
        # Gumb za spremanje je odvojen i on šalje podatke na kraju
        if st.button("💾 Spremi Gosta", type="primary"):
            # Provjera
            if ng_ime and ng_prezime and ng_dok_broj and ng_grad and ng_drzava:
                try:
                    sql_gost = """
                        INSERT INTO gost (ime, prezime, vrsta_dokumenta_id, broj_dokumenta, prebivaliste_grad_id, prebivaliste_adresa, drzavljanstvo_id)
                        VALUES (%s, %s, %s, %s, %s, %s, %s)
                    """
                    # Priprema ID-eva
                    id_dok = dok_dict[ng_dok_tip]
                    id_grad = grad_dict[ng_grad]
                    id_drzava = drz_dict[ng_drzava]
                    
                    params_gost = (ng_ime, ng_prezime, id_dok, ng_dok_broj, id_grad, ng_adresa, id_drzava)
                    
                    succ, msg = run_action(sql_gost, params_gost)
                    
                    if succ:
                        st.toast(f"✅ Gost {ng_ime} {ng_prezime} uspješno dodan!", icon='👤')
                        time.sleep(1)
                        st.rerun()
                    else:
                        st.error(f"Greška baze: {msg}")
                except Exception as e:
                    st.error(f"Sistemska greška: {e}")
            else:
                st.warning("Molimo ispunite sva polja.")

# =============================================================================
# MODUL 2: RESTORAN - NARUDŽBE
# =============================================================================
elif menu == "🍽️ RESTORAN (Narudžbe & Kuhinja)":
    
    tab_otvori, tab_dodaj, tab_servis, tab_naplata = st.tabs(["1. Otvori Stol", "2. Dodaj Stavke", "3. Kuhinja/Servis", "4. Naplata"])

    # --- TAB 1: OTVARANJE ---
    with tab_otvori:
        st.subheader("Otvaranje nove narudžbe")
        stolovi = run_query("SELECT id, broj_stola, lokacija FROM restoran_stol")
        stol_dict = {f"Stol {row['broj_stola']} ({row['lokacija']})": row['id'] for i, row in stolovi.iterrows()}
        
        odabrani_stol_lbl = st.selectbox("Odaberi stol", list(stol_dict.keys()))
        
        if st.button("Otvori narudžbu na stolu"):
            stol_id = int(stol_dict[odabrani_stol_lbl])
            # Poziv procedure: proc_otvori_narudzbu(zaposlenik, stol, OUT id)
            # Kroz Python connector callproc radi malo drugačije s OUT parametrima,
            # pa ćemo koristiti wrapper varijablu u sesiji
            try:
                conn = get_connection()
                cursor = conn.cursor()
                # 28 = ID konobara (npr. Marko)
                cursor.callproc('proc_otvori_narudzbu', [28, stol_id, 0]) 
                conn.commit()
                st.toast("Narudžba otvorena!")
            except mysql.connector.Error as err:
                st.error(f"Greška: {err.msg}")
            finally:
                if 'conn' in locals() and conn.is_connected():
                    cursor.close()
                    conn.close()

    # --- TAB 2: DODAVANJE STAVKI ---
    with tab_dodaj:
        st.subheader("Dodaj na narudžbu")
        # Samo OTVORENE narudžbe
        otvorene = run_query("""
            SELECT rn.id, rs.broj_stola 
            FROM restoran_narudzba rn
            JOIN restoran_stol rs ON rn.restoran_stol_id = rs.id
            WHERE rn.status = 'OTVORENA'
        """)
        
        if otvorene.empty:
            st.warning("Nema otvorenih narudžbi.")
        else:
            narudzba_dict = {f"Narudžba #{row['id']} (Stol {row['broj_stola']})": row['id'] for i, row in otvorene.iterrows()}
            odabrana_narudzba_lbl = st.selectbox("Odaberi narudžbu", list(narudzba_dict.keys()))
            
            # Usluge
            usluge = run_query("SELECT id, naziv, cijena_trenutna FROM usluga WHERE kategorija_id IN (1,2)") # Hrana i piće
            usluga_dict = {f"{row['naziv']} ({row['cijena_trenutna']} €)": row['id'] for i, row in usluge.iterrows()}
            
            col_u1, col_u2 = st.columns(2)
            with col_u1:
                odabrana_usluga_lbl = st.selectbox("Artikl", list(usluga_dict.keys()))
            with col_u2:
                kolicina = st.number_input("Količina", 1, 20, 1)
            
            if st.button("Dodaj stavku"):
                n_id = int(narudzba_dict[odabrana_narudzba_lbl])
                u_id = int(usluga_dict[odabrana_usluga_lbl])
                kol = int(kolicina)
                
                # Poziv procedure proc_dodaj_stavku(narudzba, usluga, kolicina)
                success, msg = run_action("proc_dodaj_stavku", [n_id, u_id, kolicina], is_procedure=True)
                if success:
                    st.toast(f"✅ Uspješno dodano: {kol} kom!", icon='🛒')
                    
                    import time
                    time.sleep(0.5) # Kratka pauza da vidite poruku
                    st.rerun()      # Osvježi da se vidi u tablici dolje
                else:
                    st.error(msg)

            st.markdown("---")
            st.info(f"Trenutno na odabranoj narudžbi:")
            n_id_view = int(narudzba_dict[odabrana_narudzba_lbl])
            stavke_na_racunu = run_query(f"""
                SELECT u.naziv, rs.kolicina, rs.cijena_u_trenutku as cijena, rs.status_pripreme 
                FROM restoran_stavka rs
                JOIN usluga u ON rs.usluga_id = u.id
                WHERE rs.narudzba_id = {n_id_view}
            """)
            st.dataframe(stavke_na_racunu, use_container_width=True)

    # --- TAB 3: SERVIS (Pametno razdvajanje Hrana vs. Piće) ---
    with tab_servis:
        st.subheader("Kuhinja i Šank - Display")
        
        # 1. PROMJENA U UPITU: Dohvaćamo i 'u.kategorija_id'
        stavke_df = run_query("""
            SELECT rs.id, u.naziv, rs.kolicina, rs.status_pripreme, rs.narudzba_id, u.kategorija_id
            FROM restoran_stavka rs
            JOIN usluga u ON rs.usluga_id = u.id
            WHERE rs.status_pripreme IN ('NARUCENO', 'PRIPREMA')
        """)

        if stavke_df.empty:
            st.info("Nema narudžbi na čekanju.")
        else:
            # Prikaz tablice
            st.dataframe(stavke_df, use_container_width=True)
            st.markdown("---")
            
            # Priprema labela za dropdown
            # Dodajemo ikonu 🍔 ili 🍺 ovisno o kategoriji za lakše prepoznavanje
            def get_icon(kat_id):
                return "🍔" if kat_id == 1 else "🍺" if kat_id == 2 else "📦"

            stavka_dict = {
                f"{get_icon(row['kategorija_id'])} {row['naziv']} (Kol: {row['kolicina']}) -> {row['status_pripreme']}": row['id'] 
                for i, row in stavke_df.iterrows()
            }
            
            odabrana_oznaka = st.selectbox("Odaberi stavku za obradu:", list(stavka_dict.keys()))
            odabrani_id = int(stavka_dict[odabrana_oznaka])
            
            # Dohvaćamo detalje odabrane stavke iz DataFrame-a
            redak = stavke_df[stavke_df['id'] == odabrani_id].iloc[0]
            kategorija = int(redak['kategorija_id'])
            status = redak['status_pripreme']
            
            col_action1, col_action2 = st.columns(2)

            # --- LOGIKA PRIKAZA GUMBA ---

            # SCENARIJ A: HRANA (Kategorija 1)
            if kategorija == 1: 
                with col_action1:
                    if status == 'NARUCENO':
                        # Hrana se mora prvo staviti kuhati
                        if st.button("👨‍🍳 Stavi kuhati (Start Priprema)"):
                            try:
                                conn = get_connection()
                                cursor = conn.cursor()
                                args = [odabrani_id, '']
                                res = cursor.callproc('proc_zapocni_pripremu', args)
                                conn.commit()
                                st.toast(f"Kuhinja: {res[1]}", icon='🔥')
                                import time
                                time.sleep(0.5)
                                st.rerun()
                            except mysql.connector.Error as err:
                                st.error(f"Greška: {err.msg}")
                    else:
                        st.info("Jelo se već kuha...")

                with col_action2:
                    # Gumb za posluživanje je omogućen tek kad je jelo kuhano (PRIPREMA)
                    # Ili "force" posluživanje ako preskačemo red
                    if st.button("🔔 Jelo gotovo - Posluži", type="primary"):
                        try:
                            conn = get_connection()
                            cursor = conn.cursor()
                            args = [odabrani_id, '']
                            res = cursor.callproc('proc_posluzi_stavku', args)
                            conn.commit()
                            st.toast(f"Servis: {res[1]}", icon='🍽️')
                            import time
                            time.sleep(0.5)
                            st.rerun()
                        except mysql.connector.Error as err:
                            st.error(f"Greška: {err.msg}")

            # SCENARIJ B: PIĆE (Kategorija 2) ili OSTALO
            else:
                st.info("ℹ️ Piće/Ostalo ne zahtijeva pripremu u kuhinji.")
                
                # Ovdje nudimo SAMO gumb za posluživanje (preskačemo pripremu)
                if st.button("🍺 Natoči i Posluži", type="primary"):
                    try:
                        conn = get_connection()
                        cursor = conn.cursor()
                        # Pozivamo istu proceduru 'proc_posluzi_stavku'
                        # Ona je pametna: ako je status NARUCENO, ona će skinuti zalihe i odmah poslužiti.
                        args = [odabrani_id, '']
                        res = cursor.callproc('proc_posluzi_stavku', args)
                        conn.commit()
                        st.toast(f"Šank: {res[1]}", icon='✅')
                        import time
                        time.sleep(0.5)
                        st.rerun()
                    except mysql.connector.Error as err:
                        st.error(f"Greška: {err.msg}")

    # --- TAB 4: NAPLATA (Ispravljeno da greška ostane vidljiva) ---
    with tab_naplata:
        st.subheader("Naplata računa")
        
        otvorene_naplata = run_query("""
            SELECT rn.id, rs.broj_stola, 
                   (SELECT SUM(kolicina * cijena_u_trenutku) FROM restoran_stavka WHERE narudzba_id=rn.id) as total
            FROM restoran_narudzba rn
            JOIN restoran_stol rs ON rn.restoran_stol_id = rs.id
            WHERE rn.status = 'OTVORENA'
        """)
        
        if otvorene_naplata.empty:
            st.warning("Nema otvorenih narudžbi.")
        else:
            nar_naplata_dict = {f"Stol {row['broj_stola']} (Total: {row['total']} €)": row['id'] for i, row in otvorene_naplata.iterrows()}
            odabrana_za_platiti = st.selectbox("Odaberi stol za naplatu", list(nar_naplata_dict.keys()))
            
            nacin_placanja = st.radio("Način plaćanja:", ["GOTOVINA", "KARTICA", "NA SOBU"])
            
            soba_broj = None
            if nacin_placanja == "NA SOBU":
                soba_broj = st.number_input("Unesi broj sobe gosta:", min_value=100, max_value=505, step=1)
            
            if st.button("Izvrši naplatu"):
                nar_id = int(nar_naplata_dict[odabrana_za_platiti])
                
                sql_soba = int(soba_broj) if nacin_placanja == "NA SOBU" else None
                sql_nacin = "VIRMANSKI" if nacin_placanja == "NA SOBU" else nacin_placanja
                
                try:
                    conn = get_connection()
                    cursor = conn.cursor()
                    args = [nar_id, sql_nacin, sql_soba, '']
                    result_args = cursor.callproc('proc_naplati_narudzbu', args)
                    conn.commit()
                    
                    # USPJEH: Prikaži toast i osvježi
                    st.toast(f"💰 {result_args[3]}", icon='✅')
                    
                    import time
                    time.sleep(1)
                    st.rerun() # <--- RERUN JE SADA SAMO OVDJE (NAKON USPJEHA)
                    
                except mysql.connector.Error as err:
                    # GREŠKA: Samo ispiši grešku, NEMOJ osvježiti stranicu
                    st.error(f"Greška naplate: {err.msg}")
                    
                finally:
                    if 'conn' in locals() and conn.is_connected():
                        cursor.close()
                        conn.close()
                        # OVDJE VIŠE NEMA RERUN-a!

# =============================================================================
# MODUL 3: PREGLEDI I DOMAĆINSTVO
# =============================================================================
elif menu == "📊 STANJE (Sobe i Logovi)":
    st.header("Pregled stanja hotela")
    
    # Prvi red: Pregled Soba i Logova
    col1, col2 = st.columns(2)
    
    with col1:
        st.subheader("Trenutno stanje soba")
        try:
            sobe_view = run_query("SELECT * FROM trenutno_stanje_soba ORDER BY broj_sobe")
            def color_row(val):
                color = '#ffcdd2' if val == 'ZAUZETA' else '#c8e6c9' if val == 'SLOBODNA' else '#fff9c4'
                return f'background-color: {color}'
            st.dataframe(sobe_view.style.applymap(color_row, subset=['trenutno_stanje']), use_container_width=True, height=400)
        except:
            st.error("View 'trenutno_stanje_soba' nedostaje.")

    with col2:
        st.subheader("Zadnje promjene (Logovi)")
        logs = run_query("SELECT * FROM log_rezervacije ORDER BY vrijeme_promjene DESC LIMIT 15")
        st.dataframe(logs, use_container_width=True, height=400)

    st.markdown("---")
    
    # --- NOVO: DOMAĆINSTVO (HOUSEKEEPING) ---
    st.subheader("🧹 Domaćinstvo (Čišćenje)")
    
    # Dohvati sobe koje su u statusu CISCENJE
    prljave_sobe = run_query("SELECT id, broj, tip_sobe_id, status FROM soba WHERE status = 'CISCENJE'")
    
    if prljave_sobe.empty:
        st.success("Sve sobe su čiste! Nema zadataka za domaćinstvo. ✨")
    else:
        col_clean1, col_clean2 = st.columns([3, 1])
        
        with col_clean1:
            st.warning(f"Broj soba za čišćenje: {len(prljave_sobe)}")
            st.dataframe(prljave_sobe, use_container_width=True)
            
        with col_clean2:
            st.write("### Akcija")
            # Dropdown
            soba_za_ciscenje_dict = {f"Soba {row['broj']}": row['id'] for i, row in prljave_sobe.iterrows()}
            odabrana_soba_clean = st.selectbox("Označi kao očišćeno:", list(soba_za_ciscenje_dict.keys()))
            
            if st.button("✨ Očišćeno (Slobodna)", type="primary"):
                soba_id_clean = soba_za_ciscenje_dict[odabrana_soba_clean]
                
                # Poziv procedure sp_ociscena_soba
                success, msg = run_action("sp_ociscena_soba", [soba_id_clean], is_procedure=True)
                
                if success:
                    st.toast(f"Soba {odabrana_soba_clean} je sada SLOBODNA!")
                    time.sleep(1)
                    st.rerun()
                else:
                    st.error(msg)

# =============================================================================
# MODUL 4: IZVJEŠTAJI (FINANCIJE I SKLADIŠTE)
# =============================================================================
elif menu == "📈 IZVJEŠTAJI (Financije & Zalihe)":
    
    tab_zalihe, tab_racuni = st.tabs(["📦 Skladište (Zalihe)", "💶 Financije (Računi)"])
    
    # --- TAB 1: ZALIHE ---
    with tab_zalihe:
        st.header("Stanje Skladišta")
        
        # 1. Prikaz kritičnih zaliha (koristimo tvoj POGLED iz pogledi.sql)
        # Ako pogled ne postoji, aplikacija će pasti, pa koristimo try-except ili običan query
        try:
            df_low = run_query("SELECT * FROM low_stock_alert")
            if not df_low.empty:
                st.error(f"⚠️ PAŽNJA: {len(df_low)} artikala ima kritično niske zalihe!")
                st.dataframe(df_low, use_container_width=True)
            else:
                st.success("✅ Nema kritičnih artikala.")
        except:
            st.warning("Pogled 'low_stock_alert' nije pronađen. Prikazujem samo tablicu.")

        st.markdown("---")
        st.subheader("Svi Artikli")

        # 2. Glavna tablica zaliha - SADA KORISTIMO NOVI POGLED
        # Jednostavan select, sortiramo po stanju da vidimo čega ima najmanje
        df_artikli = run_query("SELECT * FROM pregled_zaliha_skladiste ORDER BY stanje_zaliha ASC")
        
        # Funkcija za bojanje redaka (isto kao prije)
        def highlight_stock(val):
            color = '#ffcdd2' if val <= 5 else '#fff9c4' if val <= 20 else ''
            return f'background-color: {color}'

        # Prikazujemo tablicu
        st.dataframe(
            df_artikli.style.applymap(highlight_stock, subset=['stanje_zaliha'])
                      .format({"nabavna_cijena": "{:.2f} €", "ukupna_vrijednost": "{:.2f} €"}),
            use_container_width=True,
            height=500
        )

    # --- TAB 2: RAČUNI (Ažurirano s novim Pogledom) ---
    with tab_racuni:
        st.header("Pregled Računa")
        
        col_fil1, col_fil2 = st.columns(2)
        with col_fil1:
            filter_tip = st.selectbox("Filtriraj po tipu:", ["SVI", "HOTEL", "RESTORAN"])
        with col_fil2:
            filter_status = st.selectbox("Filtriraj po statusu:", ["SVI", "PLACENO", "OTVOREN", "STORNIRANO"])
            
        # SADA KORISTIMO POGLED 'pregled_svih_racuna'
        # WHERE 1=1 je trik da možemo lako lijepiti AND uvjete
        sql_base = "SELECT * FROM pregled_svih_racuna WHERE 1=1"
        params = []
        
        # Dinamičko dodavanje filtera
        if filter_tip != "SVI":
            sql_base += " AND tip_racuna = %s"
            params.append(filter_tip)
            
        if filter_status != "SVI":
            sql_base += " AND status_racuna = %s"
            params.append(filter_status)
            
        sql_base += " ORDER BY racun_id DESC"
        
        # Izvršavanje upita
        try:
            df_racuni = run_query(sql_base, params)

            if not df_racuni.empty:
                df_racuni['rezervacija_id'] = df_racuni['rezervacija_id'].astype('Int64').astype(str).replace('<NA>', '-')
            
            # Prikaz liste računa
            st.dataframe(
                df_racuni.style.format({"iznos_ukupno": "{:.2f} €"}),
                use_container_width=True
            )
            
            st.markdown("---")
            st.subheader("🔍 Detalji Računa")
            
            # Odabir računa za detalje
            if not df_racuni.empty:
                lista_racuna = df_racuni['racun_id'].tolist()
                odabrani_id_racuna = st.selectbox("Odaberi ID računa za prikaz stavki:", lista_racuna)
                
                # Dohvat stavki za taj račun (Ovo ostaje isti jednostavan upit)
                stavke_df = run_query("""
                    SELECT tip_stavke, opis, kolicina, cijena_jedinicna, iznos_ukupno
                    FROM stavka_racuna
                    WHERE racun_id = %s
                """, (int(odabrani_id_racuna),))
                
                st.table(stavke_df.style.format({"cijena_jedinicna": "{:.2f} €", "iznos_ukupno": "{:.2f} €"}))
                
                total = stavke_df['iznos_ukupno'].sum()
                st.metric(label="UKUPAN IZNOS", value=f"{total:.2f} €")
            else:
                st.info("Nema računa koji odgovaraju filterima.")
                
        except Exception as e:
            st.error(f"Greška: Moguće da pogled 'pregled_svih_racuna' još nije kreiran u bazi.\nDetalji: {e}")