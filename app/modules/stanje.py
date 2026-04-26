import streamlit as st
import mysql.connector
import time
from datetime import datetime

from app.config import get_connection
from app.db import run_query, run_action

# =============================================================================
# MODUL 3: PREGLEDI, DOMAĆINSTVO I ODRŽAVANJE
# =============================================================================
def render():
    st.header("Upravljanje stanjem hotela")

    tab_pregled, tab_domacinstvo, tab_odrzavanje, tab_provjera_dostupnosti = st.tabs(["👁️ Pregled Stanja", "🧹 Domaćinstvo", "🛠️ Održavanje (Kvarovi)", "📆 Provjera dostupnosti"])

    # --- TAB 1: PREGLED SOBA I LOGOVA ---
    with tab_pregled:
        st.subheader("Trenutno stanje soba")
        try:
            # 1. Dohvaćamo podatke iz pogleda koji već sadrži hex kodove boja
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
        except mysql.connector.Error as err:
            st.error(f"SQL Error [{err.errno}]: {err.msg}")
        except Exception as e:
            st.error(f"System Error: {e}")

        st.markdown("---")
        st.subheader("Povijest promjena (Logovi)")
        logs = run_query("SELECT * FROM log_rezervacije ORDER BY vrijeme_promjene DESC")
        st.dataframe(logs, use_container_width=True)

        # Gumb za čišćenje starih logova
        if st.button("🗑️ Očisti logove starije od 90 dana"):
            try:
                conn = get_connection()
                cursor = conn.cursor()

                cursor.execute("CALL ocisti_stare_log_rez(90, @obrisano)")

                if cursor.with_rows:
                    cursor.fetchall()

                while cursor.nextset():
                    if cursor.with_rows:
                        cursor.fetchall()

                cursor.execute("SELECT @obrisano")
                broj = cursor.fetchone()[0]

                conn.commit()
                st.success(f"Obrisano {broj} starih zapisa iz loga.")

                cursor.close()
                conn.close()
                time.sleep(1)
                st.rerun()

            except mysql.connector.Error as err:
                st.error(f"SQL Error [{err.errno}]: {err.msg}")
            except Exception as e:
                st.error(f"Python Error: {e}")

    # --- TAB 2: DOMAĆINSTVO ---
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
                sobarice = run_query("SELECT id, puno_ime FROM view_zaposlenici_domacinstvo")
                sobarica_dict = {row['puno_ime']: row['id'] for i, row in sobarice.iterrows()}

                odabrana_sobarica_lbl = st.selectbox("Očistila:", list(sobarica_dict.keys()))

                soba_clean_dict = {f"Soba {row['broj']}": row['id'] for i, row in prljave_sobe.iterrows()}
                odabrana_soba_clean = st.selectbox("Označi očišćeno:", list(soba_clean_dict.keys()))

                # Dodajemo opciju prijave štete (puni tablicu ciscenje_dnevni_nalog)
                prijavi_stetu = st.checkbox("Prijavi štetu u sobi?")
                opis_stete = ""
                if prijavi_stetu:
                    opis_stete = st.text_input("Opis štete (npr. razbijena čaša):")

                if st.button("✨ Soba Očišćena i Pregledana", type="primary"):
                    s_id = int(soba_clean_dict[odabrana_soba_clean])
                    z_id = int(sobarica_dict[odabrana_sobarica_lbl])

                    try:

                        v_ima_stete = 1 if opis_stete else 0


                        insert_log_sql = """
                            INSERT INTO ciscenje_dnevni_nalog (zaposlenik_id, rezervacija_id, prijavljena_steta, opis_stete, obavljeno)
                            VALUES (%s, (SELECT id FROM rezervacija WHERE soba_id=%s ORDER BY kraj_datum DESC LIMIT 1), %s, %s, 1)
                        """
                        run_action(insert_log_sql, [z_id, s_id, v_ima_stete, opis_stete])

                        success, msg = run_action("sp_ociscena_soba", [s_id], is_procedure=True)

                        if success:
                            st.toast(f"✅ Soba {odabrana_soba_clean} je čista! (Šteta evidentirana: {'DA' if opis_stete else 'NE'})")
                            time.sleep(1.5)
                            st.rerun()
                        else:
                            st.error(f"Greška kod promjene statusa: {msg}")
                    except Exception as e:
                            st.error(f"Sistemska greška: {e}")

    # --- TAB 3: ODRŽAVANJE ---
    with tab_odrzavanje:
        st.header("🛠️ Tehnička služba")
        st.info("Ovdje prijavljujete kvarove. Soba s aktivnim kvarom postaje 'IZVAN_FUNKCIJE'.")

        col_kvar1, col_kvar2 = st.columns(2)

        # FORMA ZA PRIJAVU KVARA
        with col_kvar1:
            st.subheader("Nova prijava kvara")
            with st.form("prijava_kvara"):

                # 1. Odabir sobe
                sve_sobe = run_query("SELECT id, broj FROM view_sve_sobe_dropdown ORDER BY broj")
                soba_dict_kvar = {f"Soba {row['broj']}": row['id'] for i, row in sve_sobe.iterrows()}
                odabrana_soba_kvar = st.selectbox("Soba:", list(soba_dict_kvar.keys()))

                # 2. Odabir servisera
                domari = run_query("SELECT id, puno_ime FROM view_zaposlenici_odrzavanje")

                if not domari.empty:
                    domar_dict = {row['puno_ime']: row['id'] for i, row in domari.iterrows()}
                    odabrani_domar = st.selectbox("Prijavio / Zadužen serviser:", list(domar_dict.keys()))
                else:
                    st.error("Nema zaposlenika u odjelu Održavanje.")
                    domar_dict = {}
                    odabrani_domar = None

                opis_kvara = st.text_area("Opis kvara:", placeholder="npr. Klima ne hladi, puknuta cijev...")
                korisnik_kriv = st.checkbox("Kvar uzrokovao gost (naplata)?")

                # GUMB ZA SLANJE
                if st.form_submit_button("🚨 Prijavi kvar"):
                    if odabrani_domar and opis_kvara:
                        s_id = int(soba_dict_kvar[odabrana_soba_kvar])
                        z_id = int(domar_dict[odabrani_domar])
                        placa_gost = 1 if korisnik_kriv else 0

                        params = [z_id, s_id, opis_kvara, placa_gost]

                        success, msg = run_action("proc_prijavi_kvar", params, is_procedure=True)

                        if success:
                            st.success(f"Kvar uspješno prijavljen! Soba {odabrana_soba_kvar} je sada IZVAN FUNKCIJE.")
                            time.sleep(1.5)
                            st.rerun()
                        else:
                            st.error(msg)
                    else:
                        st.warning("Molimo unesite opis kvara i odaberite servisera.")

        # LISTA AKTIVNIH KVAROVA
        with col_kvar2:
            st.subheader("📋 Aktivni nalozi")

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

                        soba_id_za_fix = kvarovi_df[kvarovi_df['nalog_id'] == nalog_id].iloc[0]['soba_id']

                        run_action("UPDATE soba SET status = 'SLOBODNA' WHERE id = %s", [int(soba_id_za_fix)])

                    st.toast("Nalog zatvoren.")
                    time.sleep(1)
                    st.rerun()

    # --- TAB 4: PROVJERA DOSTUPNOSTI SOBA ---
    with tab_provjera_dostupnosti:
        st.subheader("Provjeri dostupnost soba")

        col_pd1, col_pd2, col_pd3 = st.columns(3)
        with col_pd1:
            datum_checkin = st.date_input("Datum prijave", value=datetime.today().date())
        with col_pd2:
            datum_checkout = st.date_input("Datum odjave", value=datetime.today().date())
        with col_pd3:
            broj_osoba = st.number_input("Broj osoba", min_value=1, max_value=4, value=1)

        if st.button("🔍 Provjeri dostupnost"):
            if datum_checkin >= datum_checkout:
                st.error("Datum odjave mora biti nakon datuma prijave.")
            else:
                # KORISTIMO POGLED 'view_dostupne_sobe'
                dostupno = run_query("SELECT provjeri_dostupnost_kapaciteta(%s, %s, %s) AS Mogu_Li_Rezervirati_Kapacitet", [broj_osoba, datum_checkin, datum_checkout])

                if dostupno.empty or dostupno.iloc[0]['Mogu_Li_Rezervirati_Kapacitet'] == 0:
                    st.warning("Nema dostupnih soba za odabrani period.")
                else:
                    dostupno = run_query("CALL dohvati_slobodne_sobe(%s, %s, %s)", [broj_osoba, datum_checkin, datum_checkout])
                    st.success("Imaju dostupne sobe!")
                    st.dataframe(dostupno, use_container_width=True)
