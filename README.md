# Sustav_Za_Upravljanje_Hotelom
Sustav za upravljanje hotelom

 DONE - Rokovi :  17 tablica + smisleni zapisi ->> okidači ->> procedure(10) ->> transakcije ->>  pogledi(5), procedure(10) ->> web sučelje ->>  dokumenatacija

Sljedeći sastank: Četvrtak 15.01  
  - Tema Sastanka: Komentiranje gotovog projekta i integracija u frontend

Sljedeće za napraviti:

- Riješiti individualno što smo dogovorili na sastanku 12.01

- Individualnu dokumentaciju

Sve što napraviš ubaci u datoteku na GIT-hub.

Pogledajte google doc, kada odaberete što ćete raditi, napišite to ovdje u grupu.

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
