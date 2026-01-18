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
        user="root",           # <--- PROVJERI SVOJE KORISNIČKO IME
        password="root",       # <--- PROVJERI SVOJU LOZINKU
        database="novi_projekt"
    )

# Funkcija za dohvat podataka (SELECT) - Vraća Pandas DataFrame
def run_query(query, params=None):
    conn = get_connection()
    try:
        df = pd.read_sql(query, conn, params=params)
        return df
    finally:
        if conn.is_connected():
            conn.close()

# Funkcija za izvršavanje akcija (INSERT, UPDATE, PROCEDURE)
def run_action(query, params=None, is_procedure=False):
    conn = get_connection()
    cursor = conn.cursor()
    try:
        if is_procedure:
            cursor.callproc(query, params)
        else:
            cursor.execute(query, params)
        
        conn.commit()
        return True, "Uspješno izvršeno!"
    except mysql.connector.Error as err:
        # Čišćenje poruke greške (mičemo SQL kodove grešaka ako je moguće)
        msg = str(err.msg)
        if "Greška:" in msg:
            return False, msg
        else:
            return False, f"Baza odbija: {msg}"
    finally:
        cursor.close()
        conn.close()

# -----------------------------------------------------------------------------
# 2. UI IZGLED I GLAVNI IZBORNIK
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
    tab_nova, tab_lista, tab_gost, tab_usluge = st.tabs(["➕ Nova Rezervacija", "📋 Lista i Akcije", "👤 Novi Gost", "💆 Dodatne Usluge"])
    
    # --- TAB 1: NOVA REZERVACIJA ---
    with tab_nova:
        st.header("Nova Rezervacija")
        st.info("Ovdje kreirate novu rezervaciju. Sustav automatski računa cijenu i provjerava zauzeće.")

        # 1. Dohvat podataka 
        gosti_df = run_query("SELECT id, ime, prezime FROM gost")
        
        # --- IZMJENA: Dohvaćamo SVE sobe (i prljave i zauzete) koristeći novi View ---
        # Stari kod je imao "WHERE status = 'SLOBODNA'", to smo maknuli.
        sobe_df = run_query("SELECT * FROM view_sve_sobe_dropdown")
        
        promocije_df = run_query("SELECT id, naziv, popust_postotak FROM promocija WHERE aktivna=1")

        # Rječnici za dropdown menije
        gost_dict = {f"{row['ime']} {row['prezime']} (ID: {row['id']})": row['id'] for i, row in gosti_df.iterrows()}
        
        # --- IZMJENA: U labelu dodajemo status sobe da se vidi je li zauzeta ---
        # Sada će pisati npr: "Soba 101 (Single) - [ZAUZETA]"
        soba_dict = {
            f"Soba {row['broj']} ({row['tip_sobe']}) - [{row['status']}]": row['id'] 
            for i, row in sobe_df.iterrows()
        }
        
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

            # Gumb za potvrdu
            submit_btn = st.form_submit_button("Potvrdi Rezervaciju")

        # Informativni izračun cijene (poziva funkciju iz baze)
        if odabrana_soba_lbl and datum_dolaska and datum_odlaska:
            if datum_dolaska < datum_odlaska:
                s_id_calc = soba_dict[odabrana_soba_lbl]
                try:
                    # Ovdje koristimo SQL funkciju 'izracunaj_cijenu_smjestaja'
                    df_calc = run_query(f"SELECT izracunaj_cijenu_smjestaja({s_id_calc}, '{datum_dolaska}', '{datum_odlaska}') as cijena")
                    if not df_calc.empty and df_calc.iloc[0]['cijena'] is not None:
                        cijena = df_calc.iloc[0]['cijena']
                        st.info(f"💰 Procijenjena cijena smještaja (bez boravišne): **{cijena} €**")
                except:
                    pass

        if submit_btn:
            # --- TANKI KLIJENT: Slanje podataka proceduri ---
            
            # Priprema parametara
            g_id = int(gost_dict[odabrani_gost_lbl])
            s_id = int(soba_dict[odabrana_soba_lbl])
            
            raw_promo_id = promo_dict[odabrana_promo_lbl]
            p_id = int(raw_promo_id) if raw_promo_id is not None else None
            br_osoba = int(broj_osoba)
            
            # Lista parametara mora odgovarati redoslijedu u 'proc_kreiraj_rezervaciju'
            params = [g_id, s_id, p_id, datum_dolaska, datum_odlaska, br_osoba, napomena]
            
            # Poziv procedure umjesto SQL INSERT-a
            success, msg = run_action("proc_kreiraj_rezervaciju", params, is_procedure=True)
            
            if success:
                st.toast("✅ Rezervacija uspješno kreirana!", icon='📅')
                time.sleep(1)
                st.rerun()
            else:
                # Prikaz greške koju je vratio Trigger ili Baza
                st.error(f"⛔ {msg}")

    # --- TAB 2: LISTA I AKCIJE (Check-in, Check-out, Otkazivanje) ---
    with tab_lista:
        st.subheader("Upravljanje Rezervacijama")
        
        # Filter
        status_filter = st.selectbox("Filtriraj po statusu:", ["SVI", "POTVRDJENA", "U_TIJEKU", "ZAVRSENA", "OTKAZANA"])
        
        # Čitanje pogleda (View)
        sql = "SELECT * FROM pregled_svih_rezervacija WHERE 1=1"
        params = []
        if status_filter != "SVI":
            sql += " AND status = %s"
            params.append(status_filter)
        sql += " ORDER BY pocetak_datum ASC"
        
        df_rez = run_query(sql, params)
        
        # Boje za status
        def color_status(val):
            color = '#c8e6c9' if val == 'POTVRDJENA' else \
                    '#b3e5fc' if val == 'U_TIJEKU' else \
                    '#ffcdd2' if val == 'OTKAZANA' else ''
            return f'background-color: {color}'

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
                rez_options = df_rez['rezervacija_id'].tolist()
                odabrani_rez_id = st.selectbox("Odaberi ID:", rez_options)
                
                # Dohvat podataka za odabranu rezervaciju
                red_rezervacije = df_rez[df_rez['rezervacija_id'] == odabrani_rez_id].iloc[0]
                status_trenutni = red_rezervacije['status']
                datum_dolaska = pd.to_datetime(red_rezervacije['pocetak_datum']).date()
                
                st.info(f"Status: **{status_trenutni}**")
                st.caption(f"Datum dolaska: {datum_dolaska}")
                st.markdown("---")

                # AKCIJA 1: Check-In 
                if status_trenutni == 'POTVRDJENA':
                    if st.button("🛎️ Check-In"):
                        # Poziv procedure 'proc_rezervacija_check_in'
                        success, msg = run_action("proc_rezervacija_check_in", [odabrani_rez_id], is_procedure=True)
                        
                        if success:
                            st.success("Gost prijavljen!")
                            time.sleep(1)
                            st.rerun()
                        else:
                            st.error(f"⛔ STOP: {msg}")

                # AKCIJA 2: Check-Out
                if status_trenutni == 'U_TIJEKU':
                    if st.button("👋 Check-Out"):
                        # Poziv procedure 'proc_rezervacija_check_out'
                        success, msg = run_action("proc_rezervacija_check_out", [odabrani_rez_id], is_procedure=True)
                        
                        if success:
                            st.success("Gost odjavljen!")
                            time.sleep(1)
                            st.rerun()
                        else:
                            st.error(msg)
                            
                # AKCIJA 3: Otkazivanje
                if status_trenutni == 'POTVRDJENA':
                    if st.button("❌ Otkaži"):
                        # Poziv procedure 'otkazi_rezervaciju'
                        success, msg = run_action("otkazi_rezervaciju", [odabrani_rez_id], is_procedure=True)
                        if success:
                            st.warning("Rezervacija otkazana.")
                            time.sleep(1)
                            st.rerun()
                        else:
                            st.error(msg)

    # --- TAB 3: NOVI GOST (BEZ PYTHON VALIDACIJE) ---
    with tab_gost:
        st.header("Unos novog gosta")
        st.info("Unesite podatke. Validaciju (obavezna polja) vrši baza podataka.")

        if st.session_state.get("treba_ocistiti_formu"):
            st.session_state["txt_ime"] = ""
            st.session_state["txt_prezime"] = ""
            st.session_state["txt_dok_broj"] = ""
            st.session_state["txt_adresa"] = ""
            st.session_state["treba_ocistiti_formu"] = False

        ng_ime = st.text_input("Ime", key="txt_ime")
        ng_prezime = st.text_input("Prezime", key="txt_prezime")
        
        col_dok, col_geo = st.columns(2)
        
        with col_dok:
            dok_df = run_query("SELECT id, naziv FROM vrsta_dokumenta")
            if not dok_df.empty:
                dok_dict = {row['naziv']: row['id'] for i, row in dok_df.iterrows()}
                ng_dok_tip = st.selectbox("Vrsta dokumenta", list(dok_dict.keys()), key="sel_dok")
            else:
                ng_dok_tip = None
                
            ng_dok_broj = st.text_input("Broj dokumenta", key="txt_dok_broj")
            ng_adresa = st.text_input("Adresa", key="txt_adresa")

        with col_geo:
            drz_df = run_query("SELECT id, naziv FROM drzava ORDER BY naziv")
            if not drz_df.empty:
                drz_dict = {row['naziv']: row['id'] for i, row in drz_df.iterrows()}
                ng_drzava = st.selectbox("Država", list(drz_dict.keys()), index=0, key="sel_drzava")
                
                id_drzave = drz_dict[ng_drzava]
                grad_df = run_query("SELECT id, naziv FROM grad WHERE drzava_id = %s ORDER BY naziv", [id_drzave])
                
                if grad_df.empty:
                    grad_dict = {}
                    ng_grad = None
                else:
                    grad_dict = {row['naziv']: row['id'] for i, row in grad_df.iterrows()}
                    ng_grad = st.selectbox("Grad", list(grad_dict.keys()), key="sel_grad")
            else:
                ng_drzava = None
                ng_grad = None

        st.markdown("---")
        st.subheader("👥 Dodaj suputnika na postojeću rezervaciju")
        
        # 1. Dohvati aktivne rezervacije
        rez_df = run_query("SELECT rezervacija_id, broj_sobe, ime, prezime FROM view_aktivne_rezervacije")
        if not rez_df.empty:
            rez_dict_sup = {f"Soba {row['broj_sobe']} ({row['ime']} {row['prezime']})": row['rezervacija_id'] for i, row in rez_df.iterrows()}
            odabrana_rez_sup = st.selectbox("Rezervacija:", list(rez_dict_sup.keys()))
            
            # 2. Dohvati sve goste
            svi_gosti = run_query("SELECT id, ime, prezime FROM gost ORDER BY prezime")
            gost_dict_sup = {f"{row['ime']} {row['prezime']}": row['id'] for i, row in svi_gosti.iterrows()}
            odabrani_gost_sup = st.selectbox("Odaberi suputnika:", list(gost_dict_sup.keys()))
            
            if st.button("➕ Dodaj suputnika"):
                r_id = rez_dict_sup[odabrana_rez_sup]
                g_id = gost_dict_sup[odabrani_gost_sup]
                
                success, msg = run_action("proc_dodaj_suputnika", [r_id, g_id], is_procedure=True)
                if success:
                    st.success("Suputnik dodan!")
                else:
                    st.error(msg)
        else:
            st.info("Nema aktivnih rezervacija za dodavanje suputnika.")
        
        # Gumb za spremanje
        if st.button("💾 Spremi Gosta", type="primary"):
            try:
                # Priprema parametara za proceduru
                p_dok = dok_dict.get(ng_dok_tip)
                p_grad = grad_dict.get(ng_grad)
                p_drz = drz_dict.get(ng_drzava)
                
                # Parametri moraju odgovarati proceduri 'proc_kreiraj_gosta'
                params = [ng_ime, ng_prezime, p_dok, ng_dok_broj, p_grad, ng_adresa, p_drz]
                
                # Poziv procedure umjesto SQL INSERT-a
                succ, msg = run_action("proc_kreiraj_gosta", params, is_procedure=True)
                
                if succ:
                    st.success(f"✅ Uspješno dodan gost: **{ng_ime} {ng_prezime}**")
                    st.session_state["treba_ocistiti_formu"] = True
                    time.sleep(1.5)
                    st.rerun()
                else:
                    # Baza javlja grešku (npr. NULL vrijednost)
                    st.error(f"Greška baze: {msg}")

            except Exception as e:
                st.error(f"Sistemska greška: {e}")

    # --- TAB 4: DODATNE USLUGE ---
    with tab_usluge:
        st.header("Teretite sobu za dodatne usluge")
        
        # 1. Odabir gosta/rezervacije - ČITAMO IZ POGLEDA
        aktivne_rez = run_query("SELECT * FROM view_aktivne_rezervacije")
        
        if aktivne_rez.empty:
            st.warning("Nema aktivnih rezervacija (U_TIJEKU) na koje se mogu dodati usluge.")
        else:
            # Kreiramo dropdown
            rez_dict = {
                f"Soba {row['broj_sobe']} - {row['ime']} {row['prezime']}": row['rezervacija_id'] 
                for i, row in aktivne_rez.iterrows()
            }
            odabrana_rez = st.selectbox("Odaberi sobu/gosta:", list(rez_dict.keys()))
            
            st.markdown("---")
            
            # 2. Odabir usluge - ČITAMO IZ POGLEDA
            usluge_extra = run_query("SELECT * FROM view_dodatne_usluge")
            
            if usluge_extra.empty:
                 st.error("Nema definiranih dodatnih usluga u bazi.")
            else:
                usluga_dict = {
                    f"{row['naziv']} ({row['cijena_trenutna']} €)": row['id'] 
                    for i, row in usluge_extra.iterrows()
                }
                odabrana_usluga = st.selectbox("Usluga:", list(usluga_dict.keys()))
                
                kolicina_usluge = st.number_input("Količina:", 1, 10, 1)
                napomena_usluge = st.text_input("Napomena (opcionalno):", placeholder="npr. Termin u 18h")
                
                if st.button("💳 Dodaj na račun sobe"):
                    r_id = rez_dict[odabrana_rez]
                    u_id = usluga_dict[odabrana_usluga]
                    
                    # Poziv procedure ostaje isti, to je bilo dobro
                    # Params: rezervacija_id, usluga_id, kolicina, napomena
                    succ, msg = run_action("proc_dodaj_uslugu_na_sobu", [r_id, u_id, kolicina_usluge, napomena_usluge], is_procedure=True)
                    
                    if succ:
                        st.toast("✅ Usluga uspješno dodana na račun!", icon='💆')
                        time.sleep(1)
                    else:
                        st.error(f"Greška: {msg}")

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
        
        # --- ZAMJENA SIROVOG SQL-a POGLEDOM ---
        otvorene = run_query("SELECT * FROM view_lista_otvorenih_narudzbi ORDER BY broj_stola")
        
        if otvorene.empty:
            st.warning("Nema otvorenih narudžbi.")
        else:
            # Ažuriramo dict comprehension da uključuje i lokaciju radi lakšeg snalaženja
            narudzba_dict = {
                f"Narudžba #{row['id']} (Stol {row['broj_stola']} - {row['lokacija']})": row['id'] 
                for i, row in otvorene.iterrows()
            }
            odabrana_narudzba_lbl = st.selectbox("Odaberi narudžbu", list(narudzba_dict.keys()))
            
            # Usluge
            usluge = run_query("SELECT * FROM view_meni_restoran")
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
            
            # --- ZAMJENA SIROVOG SQL-a POZIVOM POGLEDA ---
            # Koristimo %s parametar umjesto f-stringa radi sigurnosti
            stavke_na_racunu = run_query("""
                SELECT naziv_artikla, kolicina, cijena_jedinicna, ukupno_stavka, status_pripreme 
                FROM view_stavke_narudzbe 
                WHERE narudzba_id = %s
            """, [n_id_view])
            
            st.dataframe(stavke_na_racunu, use_container_width=True)

    # --- TAB 3: SERVIS (Pametno razdvajanje Hrana vs. Piće) ---
    with tab_servis:
        st.subheader("Kuhinja i Šank - Display")
        
        # Čitamo iz pogleda
        stavke_df = run_query("SELECT * FROM view_kuhinja_display")

        if stavke_df.empty:
            st.info("Nema narudžbi na čekanju.")
        else:
            st.dataframe(stavke_df, use_container_width=True)
            st.markdown("---")
            
            def get_icon(kat_id):
                return "🍔" if kat_id == 1 else "🍺" if kat_id == 2 else "📦"

            # PRILAGODBA IMENA STUPACA IZ POGLEDA:
            # 'id' -> 'stavka_id'
            # 'naziv' -> 'naziv_jela'
            
            stavka_dict = {
                f"{get_icon(row['kategorija_id'])} {row['naziv_jela']} (Kol: {row['kolicina']}) -> {row['status_pripreme']}": row['stavka_id'] 
                for i, row in stavke_df.iterrows()
            }
            
            odabrana_oznaka = st.selectbox("Odaberi stavku za obradu:", list(stavka_dict.keys()))
            odabrani_id = int(stavka_dict[odabrana_oznaka])
            
            # --- OVDJE JE BILA GREŠKA ---
            # Filtriramo po 'stavka_id', a ne po 'id'
            redak = stavke_df[stavke_df['stavka_id'] == odabrani_id].iloc[0]
            
            kategorija = int(redak['kategorija_id'])
            status = redak['status_pripreme']
            
            col_action1, col_action2 = st.columns(2)

            # Pomoćna funkcija za poziv procedure
            def izvrsi_proces_kuhinje(proc_name, stavka_id):
                try:
                    conn = get_connection()
                    cursor = conn.cursor()
                    args = [stavka_id, ''] # Drugi parametar je OUT p_poruka
                    res = cursor.callproc(proc_name, args)
                    conn.commit()
                    return res[1] # Vraćamo poruku iz baze
                except mysql.connector.Error as err:
                    return f"Greška baze: {err.msg}"
                finally:
                    if 'conn' in locals() and conn.is_connected():
                        cursor.close()
                        conn.close()

            # SCENARIJ A: HRANA
            if kategorija == 1: 
                with col_action1:
                    if status == 'NARUCENO':
                        if st.button("👨‍🍳 Stavi kuhati (Start Priprema)"):
                            msg = izvrsi_proces_kuhinje('proc_zapocni_pripremu', odabrani_id)
                            
                            if "Greška" in msg:
                                st.error(msg)
                            else:
                                st.toast(f"Kuhinja: {msg}", icon='🔥')
                                time.sleep(0.5)
                                st.rerun()
                    else:
                        st.info("Jelo se već kuha...")

                with col_action2:
                    if st.button("🔔 Jelo gotovo - Posluži", type="primary"):
                        msg = izvrsi_proces_kuhinje('proc_posluzi_stavku', odabrani_id)
                        
                        if "Greška" in msg:
                            st.error(msg)
                        else:
                            st.toast(f"Servis: {msg}", icon='🍽️')
                            time.sleep(0.5)
                            st.rerun()

            # SCENARIJ B: PIĆE (Direktno posluživanje)
            else:
                st.info("ℹ️ Piće/Ostalo ne zahtijeva pripremu u kuhinji.")
                if st.button("🍺 Natoči i Posluži", type="primary"):
                    msg = izvrsi_proces_kuhinje('proc_posluzi_stavku', odabrani_id)
                    
                    if "Greška" in msg:
                        st.error(msg) 
                    else:
                        st.toast(f"Šank: {msg}", icon='✅')
                        time.sleep(0.5)
                        st.rerun()

    # --- TAB 4: NAPLATA (Ažurirano s pregledom stavki) ---
    with tab_naplata:
        st.subheader("Naplata računa")
        
        # Čitamo iz pogleda 'view_otvorene_narudzbe_total'
        otvorene_naplata = run_query("SELECT * FROM view_otvorene_narudzbe_total")
        
        if otvorene_naplata.empty:
            st.warning("Nema otvorenih narudžbi za naplatu.")
        else:
            # Dropdown za odabir stola
            nar_naplata_dict = {
                f"Stol {int(row['broj_stola'])} (Total: {row['total_iznos']} €)": row['narudzba_id'] 
                for i, row in otvorene_naplata.iterrows()
            }
            
            odabrana_za_platiti_lbl = st.selectbox("Odaberi stol za naplatu", list(nar_naplata_dict.keys()))
            nar_id_za_platiti = int(nar_naplata_dict[odabrana_za_platiti_lbl])
            
            # --- NOVO: Prikaz stavki te narudžbe PRIJE naplate ---
            st.markdown("---")
            st.write("📝 **Sadržaj narudžbe:**")
            
            # Koristimo postojeći pogled 'view_stavke_narudzbe'
            detalji_narudzbe = run_query("""
                SELECT naziv_artikla, kolicina, cijena_jedinicna, ukupno_stavka, status_pripreme
                FROM view_stavke_narudzbe 
                WHERE narudzba_id = %s
            """, [nar_id_za_platiti])
            
            if not detalji_narudzbe.empty:
                st.dataframe(
                    detalji_narudzbe.style.format({
                        "cijena_jedinicna": "{:.2f} €", 
                        "ukupno_stavka": "{:.2f} €"
                    }),
                    use_container_width=True
                )
            else:
                st.info("Nema stavki na ovoj narudžbi.")
            
            st.markdown("---")
            
            # --- Forma za plaćanje ---
            col_pay1, col_pay2 = st.columns(2)
            
            with col_pay1:
                nacin_placanja = st.radio("Način plaćanja:", ["GOTOVINA", "KARTICA", "NA SOBU"])
            
            with col_pay2:
                soba_broj = None
                if nacin_placanja == "NA SOBU":
                    soba_broj = st.number_input("Unesi broj sobe gosta:", min_value=100, max_value=505, step=1)
                
                st.write("") # Razmak
                st.write("")
                if st.button("💳 Izvrši naplatu", type="primary"):
                    
                    sql_soba = int(soba_broj) if nacin_placanja == "NA SOBU" else None
                    sql_nacin = "VIRMANSKI" if nacin_placanja == "NA SOBU" else nacin_placanja
                    
                    try:
                        conn = get_connection()
                        cursor = conn.cursor()
                        
                        # Poziv procedure 'proc_naplati_narudzbu'
                        args = [nar_id_za_platiti, sql_nacin, sql_soba, '']
                        result_args = cursor.callproc('proc_naplati_narudzbu', args)
                        conn.commit()
                        
                        poruka_iz_baze = result_args[3]
                        
                        if poruka_iz_baze.startswith("Greška"):
                            st.error(f"⛔ {poruka_iz_baze}")
                        else:
                            st.success(f"💰 {poruka_iz_baze}")
                            time.sleep(1.5)
                            st.rerun()
                        
                    except mysql.connector.Error as err:
                        st.error(f"Sistemska greška: {err.msg}")
                        
                    finally:
                        if 'conn' in locals() and conn.is_connected():
                            cursor.close()
                            conn.close()

# =============================================================================
# MODUL 3: PREGLEDI, DOMAĆINSTVO I ODRŽAVANJE
# =============================================================================
elif menu == "📊 STANJE (Sobe i Logovi)":
    st.header("Upravljanje stanjem hotela")
    
    # Kreiramo tabove za bolju preglednost
    tab_pregled, tab_domacinstvo, tab_odrzavanje = st.tabs(["👁️ Pregled Stanja", "🧹 Domaćinstvo", "🛠️ Održavanje (Kvarovi)"])

    # --- TAB 1: PREGLED SOBA I LOGOVA (Ovo već imaš, samo je sada u tabu) ---
    with tab_pregled:
        st.subheader("Trenutno stanje soba")
        # --- OVO LIJEPIŠ UMJESTO STAROG ---
        try:
            # 1. Dohvaćamo podatke iz NOVOG pogleda koji već sadrži hex kodove boja (npr. #ff0000)
            df_boje = run_query("SELECT broj, stanje, hex_boja FROM view_status_soba_boje ORDER BY broj")
            
            # 2. Prikazujemo tablicu, ali boju čitamo direktno iz stupca 'hex_boja'
            st.dataframe(
                df_boje[['broj', 'stanje']].style.apply(
                    lambda x: [f'background-color: {df_boje.iloc[x.name]["hex_boja"]}']*len(x), 
                    axis=1
                ),
                use_container_width=True, 
                height=400
            )
        except Exception as e:
            st.error(f"Greška prikaza: {e}. Provjeri jesi li kreirao view 'view_status_soba_boje' u bazi.")

        st.markdown("---")
        st.subheader("Povijest promjena (Logovi)")
        logs = run_query("SELECT * FROM log_rezervacije ORDER BY vrijeme_promjene DESC LIMIT 20")
        st.dataframe(logs, use_container_width=True)

        # Gumb za čišćenje starih logova (Bonus funkcionalnost iz procedure.sql)
        if st.button("🗑️ Očisti logove starije od 90 dana"):
            # Poziv procedure s OUT parametrom zahtijeva malo drugačiji pristup u Pythonu,
            # ali za jednostavnost možemo pozvati proceduru i ignorirati ispis ili ga simulirati.
            try:
                conn = get_connection()
                cursor = conn.cursor()
                cursor.execute("CALL ocisti_stare_log_rez(90, @obrisano)")
                cursor.execute("SELECT @obrisano")
                broj = cursor.fetchone()[0]
                conn.commit()
                st.success(f"Obrisano {broj} starih zapisa iz loga.")
                cursor.close()
                conn.close()
                time.sleep(1)
                st.rerun()
            except Exception as e:
                st.error(f"Greška pri brisanju: {e}")

    # --- TAB 2: DOMAĆINSTVO (Ovo već imaš, malo uljepšano) ---
    with tab_domacinstvo:
        st.subheader("Lista soba za čišćenje")
        
        prljave_sobe = run_query("SELECT * FROM view_sobe_za_ciscenje")
        
        if prljave_sobe.empty:
            st.success("Sve sobe su čiste! ✨")
        else:
            col_d1, col_d2 = st.columns([2, 1])
            with col_d1:
                st.dataframe(prljave_sobe, use_container_width=True)
            
            with col_d2:
                st.write("### Akcija Čišćenja")
                soba_clean_dict = {f"Soba {row['broj']}": row['id'] for i, row in prljave_sobe.iterrows()}
                odabrana_soba_clean = st.selectbox("Označi očišćeno:", list(soba_clean_dict.keys()))
                
                # Dodajemo opciju prijave štete koju si tražio (puni tablicu ciscenje_dnevni_nalog)
                prijavi_stetu = st.checkbox("Prijavi štetu u sobi?")
                opis_stete = ""
                if prijavi_stetu:
                    opis_stete = st.text_input("Opis štete (npr. razbijena čaša):")

                if st.button("✨ Soba Očišćena i Pregledana", type="primary"):
                    s_id = soba_clean_dict[odabrana_soba_clean]
                    
                    # Logika je sada u bazi! 
                    # Šaljemo: ID sobe, Opis štete (može bit prazan), ID zaposlenika (hardcodiran 28 za demo)
                    
                    try:
                        # Poziv nove procedure 'proc_evidentiraj_ciscenje'
                        success, msg = run_action("proc_evidentiraj_ciscenje", [s_id, opis_stete, 28], is_procedure=True)
                        
                        if success:
                            st.toast(f"✅ Soba {odabrana_soba_clean} je čista! (Šteta evidentirana: {'DA' if opis_stete else 'NE'})")
                            time.sleep(1.5)
                            st.rerun()
                        else:
                            st.error(f"Greška: {msg}")
                    except Exception as e:
                         st.error(f"Sistemska greška: {e}")

    # --- TAB 3: ODRŽAVANJE (AŽURIRANO S POGLEDIMA) ---
    with tab_odrzavanje:
        st.header("🛠️ Tehnička služba")
        st.info("Ovdje prijavljujete kvarove. Soba s aktivnim kvarom postaje 'IZVAN_FUNKCIJE'.")

        col_kvar1, col_kvar2 = st.columns(2)

        # FORMA ZA PRIJAVU KVARA
        with col_kvar1:
            st.subheader("Nova prijava kvara")
            with st.form("prijava_kvara"):
                # 1. KORISTIMO NOVI POGLED: view_lista_soba_jednostavna
                sve_sobe = run_query("SELECT * FROM view_lista_soba_jednostavna")
                soba_dict_kvar = {f"Soba {row['broj']}": row['id'] for i, row in sve_sobe.iterrows()}
                odabrana_soba_kvar = st.selectbox("Soba:", list(soba_dict_kvar.keys()))
                
                # 2. KORISTIMO NOVI POGLED: view_osoblje_odrzavanja (Umjesto WHERE odjel_id=3)
                domari = run_query("SELECT * FROM view_osoblje_odrzavanja")
                
                if not domari.empty:
                    domar_dict = {row['puno_ime']: row['id'] for i, row in domari.iterrows()}
                    odabrani_domar = st.selectbox("Zaduženi serviser:", list(domar_dict.keys()))
                else:
                    st.error("Nema zaposlenika u odjelu Održavanje.")
                    domar_dict = {}
                    odabrani_domar = None

                opis_kvara = st.text_area("Opis kvara:", placeholder="npr. Klima ne hladi...")
                korisnik_kriv = st.checkbox("Kvar uzrokovao gost (naplata)?")

                if st.form_submit_button("🚨 Prijavi kvar"):
                    if odabrani_domar and opis_kvara:
                        s_id_kvar = soba_dict_kvar[odabrana_soba_kvar]
                        d_id = domar_dict[odabrani_domar]
                        
                        # INSERT i UPDATE ostaju isti (to su akcije, ne pogledi)
                        sql_insert = """
                            INSERT INTO servis_dnevni_nalog (zaposlenik_id, soba_id, opis, korisnik_placa, rijeseno)
                            VALUES (%s, %s, %s, %s, 0)
                        """
                        res1, msg1 = run_action(sql_insert, [d_id, s_id_kvar, opis_kvara, 1 if korisnik_kriv else 0])
                        
                        # Ovo aktivira tvoj trigger 'trg_sprijeci_rezervaciju_kvar'
                        res2, msg2 = run_action("UPDATE soba SET status = 'IZVAN_FUNKCIJE' WHERE id = %s", [s_id_kvar])
                        
                        if res1 and res2:
                            st.success(f"Kvar prijavljen za sobu {odabrana_soba_kvar}.")
                            time.sleep(1)
                            st.rerun()
                        else:
                            st.error(f"Greška: {msg1}")
                    else:
                        st.warning("Opišite kvar.")

        # LISTA AKTIVNIH KVAROVA
        with col_kvar2:
            st.subheader("📋 Aktivni nalozi")
            
            # 3. KORISTIMO NOVI POGLED: view_aktivni_kvarovi
            # Python kod je sada drastično kraći i čišći!
            kvarovi_df = run_query("SELECT * FROM view_aktivni_kvarovi ORDER BY datum_naloga DESC")
            
            if kvarovi_df.empty:
                st.success("Nema aktivnih kvarova. 👍")
            else:
                # Prikaz tablice
                st.dataframe(
                    kvarovi_df[['nalog_id', 'serviser', 'broj_sobe', 'opis_kvara', 'datum_naloga']], 
                    use_container_width=True
                )
                
                st.write("---")
                st.write("### Rješavanje")
                # Dropdown za zatvaranje naloga
                kvar_dict = {f"Nalog #{row['nalog_id']} (Soba {row['broj_sobe']})": row['nalog_id'] for i, row in kvarovi_df.iterrows()}
                odabrani_nalog = st.selectbox("Zatvori nalog:", list(kvar_dict.keys()))
                
                vratiti_u_funkciju = st.checkbox("Vrati sobu u status SLOBODNA?", value=True)
                
                if st.button("✅ Kvar otklonjen"):
                    nalog_id = kvar_dict[odabrani_nalog]
                    
                    # Update statusa naloga
                    run_action("UPDATE servis_dnevni_nalog SET rijeseno = 1 WHERE id = %s", [nalog_id])
                    
                    if vratiti_u_funkciju:
                        # Dohvaćamo soba_id iz našeg poglega (view_aktivni_kvarovi ima stupac soba_id)
                        # Ne moramo raditi novi query, možemo filtrirati dataframe ili napraviti brzi lookup
                        soba_id_za_fix = kvarovi_df[kvarovi_df['nalog_id'] == nalog_id].iloc[0]['soba_id']
                        
                        # Vraćamo sobu u funkciju
                        run_action("UPDATE soba SET status = 'SLOBODNA' WHERE id = %s", [int(soba_id_za_fix)])
                    
                    st.toast("Nalog zatvoren.")
                    time.sleep(1)
                    st.rerun()

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

        st.markdown("---")
        st.subheader("📖 Recepture i Normativi")
        st.caption("Ovdje možete vidjeti točan sastav svakog jela i trošak namirnica.")

        # 1. Dohvat podataka iz novog pogleda
        try:
            df_recepti = run_query("SELECT * FROM view_recepture_detaljno")
            
            if not df_recepti.empty:
                # Dropdown za odabir jela
                lista_jela = df_recepti['naziv_jela'].unique()
                odabrano_jelo = st.selectbox("Analiziraj jelo:", lista_jela)
                
                # Filtriranje za prikaz tablice sastojaka
                prikaz_df = df_recepti[df_recepti['naziv_jela'] == odabrano_jelo]
                
                # Prikaz tablice (samo informativno, frontend ne zbraja ovo za maržu)
                st.dataframe(
                    prikaz_df[['namirnica', 'kolicina_potrosnje', 'jedinica_mjere', 'trosak_sastojka']]
                    .style.format({"kolicina_potrosnje": "{:.3f}", "trosak_sastojka": "{:.2f} €"}),
                    use_container_width=True
                )
                
                # --- THICK DATABASE LOGIKA ---
                # Dohvaćamo ID jela iz dataframe-a
                jelo_id = prikaz_df.iloc[0]['jelo_id']
                
                # Pozivamo funkciju iz baze da nam vrati maržu
                # Primjeti: Ne računamo (cijena - trosak) ovdje!
                df_marza = run_query(f"SELECT izracunaj_marzu_jela({jelo_id}) as marza")
                marza_iz_baze = float(df_marza.iloc[0]['marza'])
                
                # Za prikaz troška i cijene možemo koristiti sumu iz tablice ili isto dohvat iz baze.
                # Radi jednostavnosti prikaza, ovdje sumiramo trošak vizualno, ali marža je došla iz SQL-a.
                ukupni_trosak_display = prikaz_df['trosak_sastojka'].sum()
                prodajna_cijena_display = ukupni_trosak_display + marza_iz_baze
                
                col_t1, col_t2, col_t3 = st.columns(3)
                
                col_t1.metric("Trošak namirnica", f"{ukupni_trosak_display:.2f} €")
                col_t2.metric("Prodajna cijena", f"{prodajna_cijena_display:.2f} €")
                
                # Ovdje prikazujemo vrijednost direktno iz SQL funkcije

                col_t3.metric("Bruto marža", f"{marza_iz_baze:.2f} €")
                
            else:
                st.info("Nema definiranih receptura.")
                
        except Exception as e:
             st.error(f"Nedostaju SQL objekti (vjerojatno view 'view_recepture_detaljno' ili funkcija). Greška: {e}")

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
                
                # --- ZAMJENA SIROVOG SQL-a POGLEDOM ---
                # Sada samo filtriramo pogled 'view_detalji_racuna'
                stavke_df = run_query("""
                    SELECT tip_stavke, opis, kolicina, cijena_jedinicna, iznos_ukupno
                    FROM view_detalji_racuna
                    WHERE racun_id = %s
                """, [int(odabrani_id_racuna)])
                
                # Formatiranje i prikaz (ostaje isto)
                st.table(stavke_df.style.format({"cijena_jedinicna": "{:.2f} €", "iznos_ukupno": "{:.2f} €"}))
                
                total = stavke_df['iznos_ukupno'].sum()
                st.metric(label="UKUPAN IZNOS", value=f"{total:.2f} €")
            else:
                st.info("Nema računa koji odgovaraju filterima.")
                
        except Exception as e:
            st.error(f"Greška: Moguće da pogled 'pregled_svih_racuna' još nije kreiran u bazi.\nDetalji: {e}")