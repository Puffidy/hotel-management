import streamlit as st
import mysql.connector
import pandas as pd
import time

from app.config import get_connection
from app.db import run_query, run_action

# =============================================================================
# MODUL 1: RECEPCIJA - KREIRANJE, PREGLED I UPRAVLJANJE REZERVACIJAMA
# =============================================================================
def render():

    tab_nova, tab_lista, tab_gost, tab_usluge = st.tabs(["➕ Nova Rezervacija", "📋 Lista i Akcije", "👤 Novi Gost", "💆 Dodatne Usluge"])

    # --- TAB 1: NOVA REZERVACIJA ---
    with tab_nova:
        st.header("Nova Rezervacija")
        st.info("Ovdje kreirate novu rezervaciju. Sustav automatski računa cijenu i provjerava zauzeće.")

        # 1. Dohvat podataka

        recepcioneri = run_query("SELECT id, puno_ime FROM view_zaposlenici_recepcija")
        recep_dict = {row['puno_ime']: row['id'] for i, row in recepcioneri.iterrows()}

        odabrani_recep_lbl = st.selectbox("Rezervaciju kreira (Recepcioner):", list(recep_dict.keys()))

        gosti_df = run_query("SELECT id, ime, prezime FROM gost")

        sobe_df = run_query("SELECT * FROM view_sve_sobe_dropdown")

        promocije_df = run_query("SELECT id, naziv, popust_postotak FROM promocija WHERE aktivna=1")

        # Rječnici za dropdown menije
        gost_dict = {f"{row['ime']} {row['prezime']} (ID: {row['id']})": row['id'] for i, row in gosti_df.iterrows()}

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
            z_id = int(recep_dict[odabrani_recep_lbl])
            g_id = int(gost_dict[odabrani_gost_lbl])
            s_id = int(soba_dict[odabrana_soba_lbl])

            raw_promo_id = promo_dict[odabrana_promo_lbl]
            p_id = int(raw_promo_id) if raw_promo_id is not None else None
            br_osoba = int(broj_osoba)

            # Lista parametara mora odgovarati redoslijedu u 'proc_kreiraj_rezervaciju'
            params = [g_id, s_id, p_id, datum_dolaska, datum_odlaska, br_osoba, napomena, z_id]

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

    # --- TAB 3: NOVI GOST ---
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

                success, msg = run_action("sp_dodaj_gosta_na_rezervaciju", [r_id, g_id], is_procedure=True)
                if success:
                    st.success("Gost dodan!")
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

                params = [ng_ime, ng_prezime, p_dok, ng_dok_broj, p_grad, ng_adresa, p_drz]

                succ, msg = run_action("proc_kreiraj_gosta", params, is_procedure=True)

                if succ:
                    st.success(f"✅ Uspješno dodan gost: **{ng_ime} {ng_prezime}**")
                    st.session_state["treba_ocistiti_formu"] = True
                    time.sleep(1.5)
                    st.rerun()
                else:
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

                    succ, msg = run_action("proc_dodaj_uslugu_na_sobu", [r_id, u_id, kolicina_usluge, napomena_usluge], is_procedure=True)

                    if succ:
                        st.toast("✅ Usluga uspješno dodana na račun!", icon='💆')
                        time.sleep(1)
                    else:
                        st.error(f"Greška: {msg}")
