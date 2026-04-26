import mysql.connector

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
