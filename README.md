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


pip install streamlit mysql-connector-python pandas

Odmah na vrhu se nalazi ovaj dio koda
def get_connection():
    return mysql.connector.connect(
        host="localhost",
        user="root",           # <-- TVOJ MYSQL USER (često je root)
        password="password",   # <-- TVOJA LOZINKA
        database="novi_projekt"
    )
user i pass upišete koji korisiti za spajanje na MySQL Workbench

streamlit run main.py
