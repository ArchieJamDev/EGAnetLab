# EGAnetLab example datasets

Three datasets ship with the module. In jamovi they appear under
**File › Open › Data Library › EGAnet Lab** once the module is installed.
All three are public data redistributed under their own licences, which are
compatible with EGAnetLab's GPL-3; [`data-raw/prepare_dataset.R`](../data-raw/prepare_dataset.R)
rebuilds every file from its source package.

| File | Rows × columns | Use it for |
|---|---|---|
| `eganetlab_wmt2.csv` | 1,185 × 24 | EGA with dichotomous items (tetrachoric correlations), bootstrap, groups by sex or age |
| `eganetlab_bfi.csv` | 2,800 × 28 | EGA with Likert items, real missing data, negatively worded items (riEGA), groups by gender, CFA |
| `eganetlab_dynamic_sim.csv` | 5,000 × 27 | Dynamic EGA (long format, many time points per person) |

## Sources and licences

| File | Source | Licence | Cite |
|---|---|---|---|
| `eganetlab_wmt2.csv` | `wmt2` in the EGAnet R package (version 2.4.1) | AGPL-3 | Golino & Christensen (2026); the test is the Wiener Matrizen-Test 2 (Formann, Waldherr & Piswanger, 2011) |
| `eganetlab_bfi.csv` | `bfi` in the psychTools R package (version 2.4.2), from the SAPA web project; items from the public-domain International Personality Item Pool (IPIP) | GPL (≥ 2) | Revelle (2024) |
| `eganetlab_dynamic_sim.csv` | `sim.dynEGA` in the EGAnet R package (version 2.4.1), simulated with `simDFM()` | AGPL-3 | Golino & Christensen (2026) |

- Formann, A. K., Waldherr, K., & Piswanger, K. (2011). *Wiener Matrizen-Test 2 (WMT-2)*. Hogrefe. https://www.hogrefe.com/at/shop/wiener-matrizen-test-2.html
- Golino, H., & Christensen, A. P. (2026). *EGAnet: Exploratory graph analysis – A framework for estimating the number of dimensions in multivariate data using network psychometrics* (Version 2.4.1) [R package]. https://r-ega.net
- Revelle, W. (2024). *psychTools: Tools to accompany the 'psych' package for psychological research* (Version 2.4.2) [R package]. Northwestern University. https://CRAN.R-project.org/package=psychTools

## `eganetlab_wmt2.csv`

| Columns | Content |
| --- | --- |
| `wmt1` ... `wmt18` | Items of the Wiener Matrizen-Test 2 (WMT-2), scored 0 = incorrect, 1 = correct |
| `education`, `monthly_income`, `income_group` | Socioeconomic variables (with missing values) |
| `sex`, `age`, `age_group` | Demographic variables, usable as grouping variables |

Written unchanged from EGAnet (factor labels trimmed of spaces). Select
`wmt1`–`wmt18` in **EGAnet Lab › Exploratory Graph Analysis**.

## `eganetlab_bfi.csv`

| Columns | Content |
| --- | --- |
| `A1`–`A5`, `C1`–`C5`, `E1`–`E5`, `N1`–`N5`, `O1`–`O5` | 25 Big Five items (Agreeableness, Conscientiousness, Extraversion, Neuroticism, Openness), 1 = very inaccurate to 6 = very accurate |
| `gender` | Male, Female |
| `education` | Some high school, High school, Some college, College graduate, Graduate degree (223 missing) |
| `age` | Age in years |

Item responses are kept as published, missing values included: 364 people
skipped at least one item, so the file exercises the Missing Values option
(pairwise or listwise). The negatively worded items are `A1`, `C4`, `C5`,
`E1`, `E2`, `O2` and `O5`: enter them under negatively worded items to use
riEGA, and use `gender` as the grouping variable to compare groups. The
expected structure is five dimensions.

## `eganetlab_dynamic_sim.csv`

EGAnet's `sim.dynEGA`: 24 items (`V1`–`V24`) measured 50 times in 100
simulated persons (`ID`) in two groups (`Group`), in long format, with a
`Time` column added. Use it in **EGAnet Lab › Dynamic EGA** with `ID` as
Person ID, `Time` as Time and `Group` as grouping variable.

---

# Conjuntos de datos de ejemplo de EGAnetLab

El módulo incluye tres conjuntos de datos. En jamovi aparecen en
**Archivo › Abrir › Biblioteca de datos › EGAnet Lab** una vez instalado el
módulo. Los tres son datos públicos redistribuidos bajo sus propias
licencias, compatibles con la GPL-3 de EGAnetLab;
[`data-raw/prepare_dataset.R`](../data-raw/prepare_dataset.R) reconstruye
cada archivo desde su paquete de origen.

| Archivo | Filas × columnas | Úselo para |
|---|---|---|
| `eganetlab_wmt2.csv` | 1.185 × 24 | EGA con ítems dicotómicos (correlaciones tetracóricas), bootstrap, grupos por sexo o edad |
| `eganetlab_bfi.csv` | 2.800 × 28 | EGA con ítems Likert, datos ausentes reales, ítems redactados en negativo (riEGA), grupos por género, AFC |
| `eganetlab_dynamic_sim.csv` | 5.000 × 27 | EGA dinámico (formato largo, muchas mediciones por persona) |

**Fuentes y licencias.** `eganetlab_wmt2.csv` es `wmt2` del paquete EGAnet
2.4.1 (AGPL-3; la prueba es el Wiener Matrizen-Test 2 de Formann, Waldherr y
Piswanger, 2011). `eganetlab_bfi.csv` es `bfi` del paquete psychTools 2.4.2
(GPL ≥ 2; Revelle, 2024), del proyecto web SAPA, con ítems de dominio
público del International Personality Item Pool (IPIP).
`eganetlab_dynamic_sim.csv` es `sim.dynEGA` de EGAnet 2.4.1 (AGPL-3),
simulado con `simDFM()`. Las referencias completas están arriba.

**`eganetlab_bfi.csv`.** 25 ítems de los Cinco Grandes en escala de 1 (muy
inexacto) a 6 (muy exacto), más `gender`, `education` y `age`. Las
respuestas se conservan tal cual, con sus datos ausentes: 364 personas
dejaron al menos un ítem sin responder. Los ítems redactados en negativo son
`A1`, `C4`, `C5`, `E1`, `E2`, `O2` y `O5` (úselos con riEGA), y `gender`
sirve como variable de agrupación. La estructura esperada es de cinco
dimensiones.

**`eganetlab_wmt2.csv`.** Los ítems `wmt1` a `wmt18` del Wiener Matrizen-Test
2 están puntuados 0 = incorrecto, 1 = correcto; `sex`, `age` y `age_group`
sirven como variables de agrupación.

**`eganetlab_dynamic_sim.csv`.** `sim.dynEGA` de EGAnet: 24 ítems (`V1` a
`V24`) medidos 50 veces en 100 personas simuladas (`ID`) de dos grupos
(`Group`), en formato largo, con una columna `Time` añadida. Úselo en
**EGAnet Lab › Dynamic EGA** con `ID` como Person ID, `Time` como Time y
`Group` como variable de agrupación.
