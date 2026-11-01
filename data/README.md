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

`eganetlab_dynamic_sim.csv` (5,000 rows; 27 columns) is EGAnet's
`sim.dynEGA`: 24 items (`V1`–`V24`) measured 50 times in 100 simulated
persons (`ID`) in two groups (`Group`), in long format, with a `Time` column
added. Use it in **EGAnet Lab › Dynamic EGA** with `ID` as Person ID, `Time`
as Time and `Group` as grouping variable.

---

# Conjunto de datos de ejemplo de EGAnetLab

`eganetlab_wmt2.csv` (n = 1.185; 24 columnas) es el conjunto `wmt2` incluido
en el paquete de R EGAnet, escrito sin cambios por
`data-raw/prepare_dataset.R`. Los ítems `wmt1` a `wmt18` del Wiener
Matrizen-Test 2 están puntuados 0 = incorrecto, 1 = correcto; `sex`, `age` y
`age_group` sirven como variables de agrupación.

`eganetlab_dynamic_sim.csv` (5.000 filas; 27 columnas) es `sim.dynEGA` de
EGAnet: 24 ítems (`V1` a `V24`) medidos 50 veces en 100 personas simuladas
(`ID`) de dos grupos (`Group`), en formato largo, con una columna `Time`
añadida. Úselo en **EGAnet Lab › Dynamic EGA** con `ID` como Person ID,
`Time` como Time y `Group` como variable de agrupación.
