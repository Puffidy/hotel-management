# Sustav_Za_Upravljanje_Hotelom
Sustav za upravljanje hotelom



### Upute za instalaciju i pokretanje

Prvo instalirajte potrebne biblioteke putem terminala:

```bash
pip install streamlit mysql-connector-python pandas

Konfiguracija baze
Odmah na vrhu koda nalazi se funkcija za spajanje.

Napomena: user i password upišite onaj koji koristite za spajanje na MySQL Workbench.

def get_connection():
    return mysql.connector.connect(
        host="localhost",
        user="root",           # <-- TVOJ MYSQL USER (često je root)
        password="password",   # <-- TVOJA LOZINKA
        database="novi_projekt"
    )

Aplikaciju pokrenite naredbom: streamlit run main.py
