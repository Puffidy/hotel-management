import streamlit as st

from app.modules import recepcija
from app.modules import restoran
from app.modules import stanje
from app.modules import izvjestaji

# -----------------------------------------------------------------------------
# 2. UI IZGLED I GLAVNI IZBORNIK
# -----------------------------------------------------------------------------
st.set_page_config(page_title="Hotel Manager Pro", layout="wide", page_icon="🏨")

st.title("🏨 Hotel Management Sustav")
st.markdown("---")

# Glavni izbornik s lijeve strane
menu = st.sidebar.radio(
    "Odaberi modul:",
    [
        "📅 RECEPCIJA (Rezervacije)",
        "🍽️ RESTORAN (Narudžbe & Kuhinja)",
        "📊 STANJE (Sobe i Logovi)",
        "📈 IZVJEŠTAJI (Financije & Zalihe)"
    ]
)

if menu == "📅 RECEPCIJA (Rezervacije)":
    recepcija.render()
elif menu == "🍽️ RESTORAN (Narudžbe & Kuhinja)":
    restoran.render()
elif menu == "📊 STANJE (Sobe i Logovi)":
    stanje.render()
elif menu == "📈 IZVJEŠTAJI (Financije & Zalihe)":
    izvjestaji.render()
