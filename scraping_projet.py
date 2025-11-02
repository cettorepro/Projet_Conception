# ========= Parse raw PDF tables into clean structured columns =========
import re
import requests
import pdfplumber
import pandas as pd
from io import BytesIO

PDF_URL = "https://images.hertz.com/pdfs/Affichette-Leg-Corp-Tarifs-HERTZ-DTG-VP-VU-JUILLET-2025-clean.pdf"

print("📥 Downloading the PDF...")
response = requests.get(PDF_URL)
response.raise_for_status()
pdf_data = BytesIO(response.content)
print("✅ PDF downloaded successfully.\n")

# --- Extract all tables from the PDF ---
with pdfplumber.open(pdf_data) as pdf:
    tables = []
    for i, page in enumerate(pdf.pages):
        extracted = page.extract_tables()
        tables.extend(extracted or [])

print(f"✅ Detected {len(tables)} tables in total.")

# --- Select table 0 (VP) and table 6 (VU) ---
vp_raw = tables[0]
vu_raw = tables[6]

# --- Clean function: remove line breaks and extra spaces ---
def clean_table(raw):
    cleaned = []
    for row in raw:
        if not row:
            continue
        cleaned.append([str(c).replace("\n", " ").strip() if c else "" for c in row])
    return cleaned

vp = clean_table(vp_raw)
vu = clean_table(vu_raw)

# --- Define headers for VP and VU tables ---
VP_HEADERS = [
    "Category",
    "Model (or similar) depending on availability",
    "1 day - Unlimited mileage (€)",
    "Max damage or theft deductible (€)",
    "CDW (damage)",
    "TP (theft)",
    "Reduced CDW deductible (€)",
    "Reduced TP deductible (€)",
    "Super Cover (€)",
]

VU_HEADERS = [
    "Category",
    "Model (or similar) depending on availability",
    "Volume (m³)",
    "1 day 100km, CDW/TP included (€)",
    "Additional km (€)",
    "Reduced CDW deductible (€)",
    "Reduced TP deductible (€)",
    "Super Cover (€)",
    "Top-part guarantee (With Super Cover)",
]

# --- Numeric token recognition pattern ---
_num_re = re.compile(r"^\d{1,3}(?: \d{3})*(?:[.,]\d+)?$")

def _is_num(tok: str) -> bool:
    tok = tok.strip()
    if not tok:
        return False
    return bool(_num_re.match(tok))

def _tokens(row):
    return [c.strip() for c in row if isinstance(c, str) and c.strip()]

# ---- Parse VP (table 0): rows like A/B/C... ----
vp_rows_clean = []
for row in vp:
    toks = _tokens(row)
    if not toks:
        continue
    # Skip headers or descriptive rows
    head_join = " ".join(toks).upper()
    if (
        "VEHICULES" in head_join
        or "MODÈLES" in head_join
        or "KILOMÉTRAGE" in head_join
        or "ILLIMITÉ" in head_join
        or head_join.startswith("CAT")
    ):
        continue

    # Expect first token to be a category (A/B/C/D...)
    cat = toks[0]
    if not re.match(r"^[A-Z]$", cat):
        continue

    # Model: from second token until first numeric token
    i = 1
    model_parts = []
    while i < len(toks) and not _is_num(toks[i]):
        model_parts.append(toks[i])
        i += 1
    model = " ".join(model_parts).strip()

    # Helper: get next numeric token
    def next_num(idx):
        while idx < len(toks) and not _is_num(toks[idx]):
            idx += 1
        return (toks[idx] if idx < len(toks) else ""), (idx + 1 if idx < len(toks) else idx)

    # Sequentially extract numeric columns
    v_1j, i = next_num(i)        # 1 day - Unlimited mileage (€)
    v_fran_max, i = next_num(i)  # Max deductible
    v_cdw, i = next_num(i)       # CDW
    v_tp, i = next_num(i)        # TP
    v_frcdw, i = next_num(i)     # Reduced CDW deductible
    v_frtp, i = next_num(i)      # Reduced TP deductible
    v_super, i = next_num(i)     # Super Cover

    vp_rows_clean.append([
        cat, model, v_1j, v_fran_max, v_cdw, v_tp, v_frcdw, v_frtp, v_super
    ])

# ---- Parse VU (table 6): rows like B4/C4... ----
vu_rows_clean = []
for row in vu:
    toks = _tokens(row)
    if not toks:
        continue
    head_join = " ".join(toks).upper()
    if (
        "VEHICULES UTILITAIRES" in head_join
        or head_join.startswith("CAT")
        or "KILOMÉTRAGE SUPPLÉMENTAIRE" in head_join
        or "GARANTIE" in head_join
        or "PARTIES HAUTES" in head_join
        or "COVER" in head_join
        or ("VOLUME" in head_join and not re.match(r"^[A-Z]\d+", toks[0]))
    ):
        continue

    cat = toks[0]
    if not re.match(r"^[A-Z]\d+$", cat):
        continue

    # Model: from 2nd token until encountering volume or numeric value
    i = 1
    model_parts = []
    while i < len(toks) and not _is_num(toks[i]) and not re.match(r"^\d+(?: \+)?$", toks[i]):
        model_parts.append(toks[i])
        i += 1
    model = " ".join(model_parts).strip()

    # ---- Volume detection ----
    vol_parts = []
    while i < len(toks):
        t = toks[i]
        # Volume numbers should be integers (possibly with '+')
        if re.match(r"^\d+(?: \+)?$", t):
            vol_parts.append(t)
            i += 1
            continue
        # Special case “20 + Hayon”
        if t == "+" and i + 1 < len(toks):
            vol_parts.append("+" + " " + toks[i + 1])
            i += 2
            continue
        if "HAYON" in t.upper():
            vol_parts.append(t)
            i += 1
            continue
        # Stop when a decimal number is found
        if _is_num(t) and ("," in t or "." in t):
            break
        break
    volume = " ".join(vol_parts).strip()

    # Following numeric fields
    def next_num(idx):
        while idx < len(toks) and not _is_num(toks[idx]):
            idx += 1
        return (toks[idx] if idx < len(toks) else ""), (idx + 1 if idx < len(toks) else idx)

    v_1j, i = next_num(i)   # 1 day 100km
    v_km, i = next_num(i)   # Additional km
    v_frcdw, i = next_num(i)  # Reduced CDW deductible
    v_frtp, i = next_num(i)   # Reduced TP deductible
    v_super, i = next_num(i)  # Super Cover
    v_gar, i = next_num(i)    # Top-part guarantee

    vu_rows_clean.append([
        cat, model, volume, v_1j, v_km, v_frcdw, v_frtp, v_super, v_gar
    ])

# ---- Create DataFrames and export as CSV ----
vp_df = pd.DataFrame(vp_rows_clean, columns=VP_HEADERS)
vu_df = pd.DataFrame(vu_rows_clean, columns=VU_HEADERS)

vp_df.to_csv("hertz_vehicules_tourism.csv", index=False, encoding="utf-8-sig")
vu_df.to_csv("hertz_vehicules_utility.csv", index=False, encoding="utf-8-sig")

print("\n💾 Clean CSV files generated:")
print("   • hertz_vehicules_tourism.csv")
print("   • hertz_vehicules_utility.csv")
