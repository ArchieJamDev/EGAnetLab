# EGAnetLab example dataset

`eganetlab_wmt2.csv` (n = 1,185; 24 columns) is the `wmt2` data set shipped
with the EGAnet R package, written out unchanged by
`data-raw/prepare_dataset.R`.

| Columns | Content |
| --- | --- |
| `wmt1` ... `wmt18` | Items of the Wiener Matrizen-Test 2 (WMT-2), scored 0 = incorrect, 1 = correct |
| `education`, `monthly_income`, `income_group` | Socioeconomic variables (with missing values) |
| `sex`, `age`, `age_group` | Demographic variables, usable as grouping variables |

Suggested use in jamovi: open it from the Data Library and select `wmt1`–`wmt18`
in **EGAnet Lab › Exploratory Graph Analysis**.

---

# Conjunto de datos de ejemplo de EGAnetLab

`eganetlab_wmt2.csv` (n = 1.185; 24 columnas) es el conjunto `wmt2` incluido
en el paquete de R EGAnet, escrito sin cambios por
`data-raw/prepare_dataset.R`. Los ítems `wmt1` a `wmt18` del Wiener
Matrizen-Test 2 están puntuados 0 = incorrecto, 1 = correcto; `sex`, `age` y
`age_group` sirven como variables de agrupación.
