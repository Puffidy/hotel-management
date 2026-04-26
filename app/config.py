import mysql.connector

# -----------------------------------------------------------------------------
# 1. POSTAVKE I SPAJANJE NA BAZU
# -----------------------------------------------------------------------------
def get_connection():
    return mysql.connector.connect(
        host="localhost",
        user="root",           # <--- Your username goes here
        password="root",       # <--- Your password goes here
        database="novi_projekt"
    )
