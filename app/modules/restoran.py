import streamlit as st
import mysql.connector
import time

from app.config import get_connection
from app.db import run_query, run_action

# =============================================================================
# MODUL 2: RESTORAN - NARUDŽBE
# =============================================================================
def render():

    tab_otvori, tab_dodaj, tab_servis, tab_naplata = st.tabs(["1. Otvori Stol", "2. Dodaj Stavke", "3. Kuhinja/Servis", "4. Naplata"])

    # --- TAB 1: OTVARANJE ---
    with tab_otvori:
        st.subheader("Otvaranje nove narudžbe")

        # 1. DOHVAT KONOBARA
        konobari = run_query("SELECT id, puno_ime FROM view_zaposlenici_konobari")
        konobar_dict = {row['puno_ime']: row['id'] for i, row in konobari.iterrows()}

        # 2. DOHVAT STOLOVA
        stolovi = run_query("SELECT id, broj_stola, lokacija FROM restoran_stol")
        stol_dict = {f"Stol {row['broj_stola']} ({row['lokacija']})": row['id'] for i, row in stolovi.iterrows()}

        col_res1, col_res2 = st.columns(2)
        with col_res1:
            odabrani_konobar_lbl = st.selectbox("Konobar:", list(konobar_dict.keys()))
        with col_res2:

            odabrani_stol_lbl = st.selectbox("Odaberi stol", list(stol_dict.keys()))

        if st.button("Otvori narudžbu na stolu"):

            k_id = int(konobar_dict[odabrani_konobar_lbl])
            stol_id = int(stol_dict[odabrani_stol_lbl])

            try:
                conn = get_connection()
                cursor = conn.cursor()

                cursor.callproc('proc_otvori_narudzbu', [k_id, stol_id, 0])
                conn.commit()
                st.toast("Narudžba otvorena!")

            except mysql.connector.Error as err:
                st.error(f"SQL Error [{err.errno}]: {err.msg}")

            finally:
                if 'conn' in locals() and conn.is_connected():
                    cursor.close()
                    conn.close()

    # --- TAB 2: DODAVANJE STAVKI ---
    with tab_dodaj:
        st.subheader("Dodaj na narudžbu")

        # --- ZAMJENA SIROVOG SQL-a POGLEDOM ---
        otvorene = run_query("SELECT * FROM view_otvorene_narudzbe_total ORDER BY broj_stola")

        if otvorene.empty:
            st.warning("Nema otvorenih narudžbi.")
        else:
            # PAŽNJA: U view_otvorene_narudzbe_total ID se zove 'narudzba_id', a ne 'id'
            narudzba_dict = {
                f"Narudžba #{row['narudzba_id']} (Stol {row['broj_stola']} - {row['lokacija']})": row['narudzba_id']
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
                    time.sleep(0.5) # Kratka pauza da se vidi poruka
                    st.rerun()      # Osvježi da se vidi u tablici dolje
                else:
                    st.error(msg)

            st.markdown("---")
            st.info(f"Trenutno na odabranoj narudžbi:")

            n_id_view = int(narudzba_dict[odabrana_narudzba_lbl])

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

            stavka_dict = {
                f"{get_icon(row['kategorija_id'])} {row['naziv_jela']} (Kol: {row['kolicina']}) -> {row['status_pripreme']}": row['stavka_id']
                for i, row in stavke_df.iterrows()
            }

            odabrana_oznaka = st.selectbox("Odaberi stavku za obradu:", list(stavka_dict.keys()))

            odabrani_id = int(stavka_dict[odabrana_oznaka])


            redak = stavke_df[stavke_df['stavka_id'] == odabrani_id].iloc[0]

            kategorija = int(redak['kategorija_id'])
            status = redak['status_pripreme']

            col_action1, col_action2 = st.columns(2)

            def izvrsi_proces_kuhinje(proc_name, stavka_id):
                conn = None
                cursor = None
                try:
                    conn = get_connection()
                    cursor = conn.cursor()

                    s_id_fixed = int(stavka_id)

                    args = [s_id_fixed, '']
                    res = cursor.callproc(proc_name, args)
                    conn.commit()
                    poruka_iz_baze = res[1]

                    if poruka_iz_baze and "Greška" in poruka_iz_baze:
                        return f"SQL Error [Logic]: {poruka_iz_baze}"

                    return poruka_iz_baze

                except mysql.connector.Error as err:
                    return f"SQL Error [{err.errno}]: {err.msg}"
                except Exception as e:
                    return f"System Error: {str(e)}"
                finally:
                    if 'conn' in locals() and conn and conn.is_connected():
                        cursor.close()
                        conn.close()

            # SCENARIJ A: HRANA
            if kategorija == 1:
                with col_action1:
                    if status == 'NARUCENO':
                        if st.button("👨‍🍳 Stavi kuhati (Start Priprema)"):
                            msg = izvrsi_proces_kuhinje('proc_zapocni_pripremu', odabrani_id)

                            if "Greška" in msg or "Error" in msg:
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

                        if "Greška" in msg or "Error" in msg:
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

                    if "Greška" in msg or "Error" in msg:
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

            # --- Prikaz stavki te narudžbe PRIJE naplate ---
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

                st.write("")
                st.write("")
                if st.button("💳 Izvrši naplatu", type="primary"):

                    sql_soba = int(soba_broj) if nacin_placanja == "NA SOBU" else None
                    sql_nacin = "VIRMANSKI" if nacin_placanja == "NA SOBU" else nacin_placanja

                    try:
                        conn = get_connection()
                        cursor = conn.cursor()

                        # Poziv procedure 'proc_naplati_narudzbu'
                        args = [int(nar_id_za_platiti), sql_nacin, sql_soba, '']
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
                        st.error(f"SQL Error [{err.errno}]: {err.msg}")

                    finally:
                        if 'conn' in locals() and conn.is_connected():
                            cursor.close()
                            conn.close()
