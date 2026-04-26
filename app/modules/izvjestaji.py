import streamlit as st
import mysql.connector
import time
from datetime import datetime

from app.config import get_connection
from app.db import run_query, run_action

# =============================================================================
# MODUL 4: IZVJEŠTAJI (FINANCIJE I SKLADIŠTE)
# =============================================================================
def render():

    tab_zalihe, tab_racuni, tab_pdv, tab_recenzije = st.tabs(["📦 Skladište (Zalihe)", "💶 Financije (Računi)", "🏛️ PDV (Obaveze)", "⭐ Recenzije"])

    # --- TAB 1: ZALIHE ---
    with tab_zalihe:
        st.header("Stanje Skladišta")

        # 1. Prikaz kritičnih zaliha
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

        # 2. Glavna tablica zaliha
        df_artikli = run_query("SELECT * FROM pregled_zaliha_skladiste ORDER BY stanje_zaliha ASC")

        # Funkcija za bojanje redaka
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

                # Prikaz tablice
                st.dataframe(
                    prikaz_df[['namirnica', 'kolicina_potrosnje', 'jedinica_mjere', 'trosak_sastojka']]
                    .style.format({"kolicina_potrosnje": "{:.3f}", "trosak_sastojka": "{:.2f} €"}),
                    use_container_width=True
                )

                # --- THICK DATABASE LOGIKA ---
                # Dohvaćamo ID jela iz dataframe-a
                jelo_id = prikaz_df.iloc[0]['jelo_id']

                # Pozivamo funkciju iz baze da nam vrati maržu
                df_marza = run_query(f"SELECT izracunaj_marzu_jela({jelo_id}) as marza")
                marza_iz_baze = float(df_marza.iloc[0]['marza'])


                ukupni_trosak_display = prikaz_df['trosak_sastojka'].sum()
                prodajna_cijena_display = ukupni_trosak_display + marza_iz_baze

                col_t1, col_t2, col_t3 = st.columns(3)

                col_t1.metric("Trošak namirnica", f"{ukupni_trosak_display:.2f} €")
                col_t2.metric("Prodajna cijena", f"{prodajna_cijena_display:.2f} €")


                col_t3.metric("Bruto marža", f"{marza_iz_baze:.2f} €")

            else:
                st.info("Nema definiranih receptura.")

        except Exception as e:
             st.error(f"Nedostaju SQL objekti (vjerojatno view 'view_recepture_detaljno' ili funkcija). Greška: {e}")

    # --- TAB 2: RAČUNI ---
    with tab_racuni:
        st.header("Pregled Računa")

        col_fil1, col_fil2 = st.columns(2)
        with col_fil1:
            filter_tip = st.selectbox("Filtriraj po tipu:", ["SVI", "HOTEL", "RESTORAN"])
        with col_fil2:
            filter_status = st.selectbox("Filtriraj po statusu:", ["SVI", "PLACENO", "OTVOREN", "STORNIRANO"])

        sql_base = "SELECT * FROM pregled_svih_racuna WHERE 1=1"
        params = []

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

            col_dataframe, col_actions = st.columns([4, 1])

            with col_dataframe:
                # Prikaz liste računa
                st.dataframe(
                    df_racuni.style.format({"iznos_ukupno": "{:.2f} €"}),
                    use_container_width=True
                )
            with col_actions:
                st.write("### Akcije")
                if not df_racuni.empty:
                    otvoreni_racuni = df_racuni[df_racuni['status_racuna'] == 'OTVOREN']
                    if otvoreni_racuni.empty:
                        st.info("Nema otvorenih računa za plaćanje.")
                    else:
                        racun_dict = {f"Račun #{row['racun_id']}": row['rezervacija_id'] for i, row in otvoreni_racuni.iterrows()}
                        odabrani_racun_akcija = st.selectbox("Označi račun kao PLAĆENO:", list(racun_dict.keys()))
                        nacin_placanja = st.selectbox("Način plaćanja:", ["KARTICA", "GOTOVINA", "VIRMANSKI", "ONLINE"])

                        if st.button("✅ Označi kao PLAĆENO"):
                            racun_id_za_placanje = int(racun_dict[odabrani_racun_akcija])

                            success, msg = run_action("generiranje_finalnog_racuna_za_rezervaciju", [racun_id_za_placanje, nacin_placanja], is_procedure=True)

                            if success:
                                st.toast(f"Račun #{racun_id_za_placanje} je sada PLAĆEN!", icon='💶')
                                time.sleep(1)
                                st.rerun()
                            else:
                                st.error(f"Greška: {msg}")

            st.markdown("---")
            st.subheader("🔍 Detalji Računa")

            # Odabir računa za detalje
            lista_racuna = df_racuni['racun_id'].tolist()
            odabrani_id_racuna = st.selectbox("Odaberi ID računa za prikaz stavki:", lista_racuna)

            query = "SELECT * FROM view_detalji_racuna WHERE racun_id = %s"
            stavke_df = run_query(query, [int(odabrani_id_racuna)])

            # Formatiranje i prikaz
            st.table(stavke_df.style.format({"cijena_jedinicna": "{:.2f} €", "iznos_ukupno": "{:.2f} €"}))

            total = stavke_df['iznos_ukupno'].sum()
            st.metric(label="UKUPAN IZNOS", value=f"{total:.2f} €")

            # TODO: when the selectbox has a new value, update the details

        except Exception as e:
            st.error(f"Greška: Moguće da pogled 'pregled_svih_racuna' još nije kreiran u bazi.\nDetalji: {e}")

    with tab_pdv:
        st.header("Izvještaj o PDV obavezama")

        pdv_godina = st.number_input(
            "Godina:",
            min_value=2000,
            max_value=datetime.today().year,
            value=datetime.today().year
        )

        if st.button("Generiraj Izvještaj o PDV-u"):
            try:
                pdv_df = run_query("SELECT pdv_za_godinu(%s)", [pdv_godina])

                if pdv_df.empty or pdv_df.iloc[0, 0] is None:
                    st.info("Nema podataka za odabranu godinu.")
                else:
                    iznos_pdv = pdv_df.iloc[0, 0]
                    st.success(f"PDV za godinu {pdv_godina}: {iznos_pdv:.2f} €")

            except Exception as e:
                st.error(f"Greška pri generiranju izvještaja: {e}")

    with tab_recenzije:
        st.header("📋 Menadžment Recenzija")

        # 1. Prikaz tablice
        recenzije_df = run_query("SELECT * FROM pregled_recenzija_za_menadzera")

        if recenzije_df.empty:
            st.info("Trenutno nema recenzija.")
        else:
            # Funkcija za bojanje statusa
            def highlight_row(val):
                # Pazi: SQL vraća 'Potrebna akcija' (case sensitive!), provjeri točan tekst u bazi
                color = '#ffcccb' if val == 'Potrebna akcija' else '#d4edda'
                return f'background-color: {color}'

            st.dataframe(
                recenzije_df.style.map(highlight_row, subset=['Status']),
                use_container_width=True,
                column_config={
                    "rezervacija_id": st.column_config.NumberColumn("ID Rez.", format="%d"),
                    "Ocjena": st.column_config.NumberColumn("Ocjena", format="%d ⭐")
                }
            )

        st.divider()

        # 2. Forma za odgovaranje
        st.subheader("✍️ Odgovori gostu")

        if not recenzije_df.empty:
            # --- OVDJE JE BILA GREŠKA ---
            # Stupac u bazi se zove 'Ime gosta', ne 'Gost'
            opcije = {f"{row['rezervacija_id']} - {row['Ime gosta']} ({row['Status']})": row['rezervacija_id'] for i, row in recenzije_df.iterrows()}

            with st.form("forma_odgovor"):
                odabir = st.selectbox("Odaberite recenziju:", list(opcije.keys()))
                tekst_odgovora = st.text_area("Vaš odgovor:", height=100)

                submit = st.form_submit_button("Pošalji odgovor", type="primary")

                if submit:
                    if not tekst_odgovora:
                        st.warning("Morate napisati tekst odgovora.")
                    else:
                        try:
                            # Izvlačimo ID
                            rez_id = int(opcije[odabir])
                            print(rez_id, tekst_odgovora)

                            run_action("odgovori_na_recenziju", [rez_id, tekst_odgovora], is_procedure=True)

                            st.success("Odgovor uspješno zabilježen!")
                            time.sleep(1)
                            st.rerun()

                        except Exception as e:
                            st.error(f"Greška: {e}")
