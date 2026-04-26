import mysql.connector
import pandas as pd
from app.config import get_connection

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

        raw_error_message = f"SQL Error [{err.errno}]: {err.msg}"
        return False, raw_error_message

    finally:
        # Provjera prije zatvaranja za slučaj da konekcija nije uspjela
        if 'cursor' in locals() and cursor:
            cursor.close()
        if 'conn' in locals() and conn.is_connected():
            conn.close()
