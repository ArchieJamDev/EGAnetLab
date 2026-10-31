# EGAnetLab 0.1.0 (development)

## EGA: compare structures with TEFI (phase 3)

* New **Compare structures (TEFI)** box in the EGA analysis. It scores the
  EGA solution, the solutions of the other community algorithms (Walktrap,
  Louvain, Leiden; seed 2026 for the random ones) and a theoretical
  structure typed by the user with `EGAnet::tefi()` on the same correlation
  matrix, so the values are comparable (Golino et al., 2021).
* The theoretical structure is written as `Name = item, item; Name = ...`;
  lavaan's `=~` and `+` also work, and `*` matches any characters (`PA*`).
  Unknown or duplicated items are explained without stopping the analysis.
* The table reports dimensions, TEFI, the difference from the lowest TEFI
  and how many items each structure places as EGA does; a second table
  shows every item's dimension in each structure. One-dimensional
  structures are flagged (their TEFI is always 0) instead of compared.
* Optional CFA fit (CFI, RMSEA, SRMR) for each structure.

## EGA: confirmatory factor analysis with an optional random split (phase 2)

* New **Confirmatory factor analysis** box in the EGA analysis. It fits the
  EGA structure as a CFA with lavaan (estimator automatic as in EGAnet's
  `CFA()`: WLSMV for items with fewer than 6 categories, MLR otherwise; or
  ML, MLR, WLSMV by choice), and reports χ², CFI, TLI, RMSEA with its 90%
  interval, SRMR and standardized loadings, read against Hu and Bentler's
  (1999) guidelines.
* **Split the sample at random**: EGA in part A (derivation, default 50%),
  CFA of that structure in part B (validation), with a visible seed. A
  side-by-side table shows the total sample, part A and part B (cases,
  dimensions, TEFI and fit), and an item table shows each item's dimension
  in the three samples, with labels aligned to the total sample and items
  that change dimension marked. **Save sample part** adds an A/B column to
  the dataset. The split never alters the global random stream.
* `lavaan` is now a direct dependency (it already came with EGAnet).

## EGA: network scores (phase 2)

* New **Network scores** box in the EGA analysis, wrapping
  `EGAnet::net.scores()` on the estimated network and memberships.
  **Network scores summary** shows, per dimension, the number of items,
  N, mean, SD and the correlation with the unweighted mean of the same items.
  **Save network scores** adds one column per dimension to the jamovi
  dataset, on the right rows even when the data are filtered.
  The guide explains that network scores are loading-weighted sums of
  z-standardized items, centered at 0 (negative values are below the sample
  average), and the table reports their mean as exactly 0.
  **Save item means** adds one column per dimension with the mean of the
  items each person answered, on the original response scale.

## EGA: redundancy by Unique Variable Analysis (phase 2)

* New optional section **Redundancy (UVA)** inside the EGA analysis,
  wrapping `EGAnet::UVA()` with the same estimation options. It lists every
  item pair with weighted topological overlap (wTO) of .20 or more, graded
  as EGAnet does (small-to-moderate, moderate-to-large, large-to-very
  large) and marked by whether both items share a dimension; the redundant
  sets at the cutoff (default .25, Christensen, Garrido & Golino, 2023);
  and EGAnet's automatic keep/remove suggestion, presented as a starting
  point for a content-based decision.
* The interpretation names redundant pairs split across dimensions and,
  when the bootstrap also runs, items that are both redundant and
  unstable.
* "About your choices" explains the wTO cutoff when the section is on.

## EGA: stability by bootstrap (phase 1)

* New optional section **Stability (bootstrap)** inside the EGA analysis,
  wrapping `EGAnet::bootEGA()`. It lives in the same analysis, not in a
  separate menu entry, so the bootstrap always resamples exactly the
  estimation shown above it. It reports the median and 95% interval of the
  number of dimensions, the frequency of each solution, structural
  consistency and mean item stability per dimension, item stability with a
  user-chosen cutoff, a stability interpretation, an item stability plot
  and a dimension frequency plot.
* Nothing runs until **Run bootstrap** is ticked; parametric or resampling
  bootstrap, number of samples and seed are visible options. The bootstrap
  summary is cached, so changing the language, cutoff or plot options does
  not resample again (ARCHITECTURE.md §16).
* "About your choices" explains the bootstrap type, the number of samples
  and the seed as well as the five estimation decisions, now shared by
  every EGA-based analysis (`.el_choices_guide()`).
* A failed bootstrap leaves the EGA results intact and explains the failure
  in the stability section.

## EGA: explained choices and network plot customization

* New "About your choices" block (option **Explain my choices**, on by
  default): one explanatory paragraph per estimation decision (correlation,
  missing values, network model, community detection, unidimensionality
  check) for the option currently selected, with guidance on when an
  alternative fits better. English and Spanish.
* Network plot customization in four new option boxes, with EGAnet's own
  defaults: layout (spring, Kamada-Kawai, circle, MDS, eigenvector) and
  title; node size, shape and fill opacity; label size and color; edge
  width, positive/negative colors and negative line type; hiding edges below
  a weight; edge-weight labels with chosen size and decimals; legend
  visibility, position and title.
* `R/plot-helpers.R` (`.el_ega_plot()`, `.el_add_edge_labels()`) and plot
  tests for every layout, shape, edge style and the two options EGAnetLab
  applies itself.

# EGAnetLab 0.1.0 (2026-10-31)

## Platform (phase 0)

* Module skeleton adopted from AssumptionsLab 1.6.0: four-file analysis
  anatomy, Category A/B error handling, `reportLang` bilingual reports,
  jamovi's native i18n catalog for the interface, native `refs:` citations,
  jamovi plot themes.
* `R/shared-helpers.R` with `.el_*` helpers, including item preparation
  (`.el_prepare_items()`) and EGAnet error/warning capture (`.el_capture()`).
* `R/texts.R` report text repository (English/Spanish).
* First analysis: **Exploratory Graph Analysis** (`ega`): number of
  dimensions, item memberships, TEFI, standardized network loadings, network
  plot and applied interpretation.
* Example dataset: WMT-2 items from EGAnet (`data/eganetlab_wmt2.csv`).
* GitHub Actions: `jmvtools::check()` plus the testthat edge-case suite.
* Documentation: README, ARCHITECTURE, DEVELOPER_GUIDE, CODE_STYLE,
  CONTRIBUTING, Bibliography.

---

## Bootstrap EGA (fase 1)

* Nuevo análisis Bootstrap EGA (estabilidad): distribución del número de
  dimensiones, consistencia estructural, estabilidad de ítems,
  interpretación y dos gráficos, con botón Ejecutar, semilla visible y
  resultados en caché.

## EGA: elecciones explicadas y personalización del gráfico

* Nuevo bloque "Acerca de sus elecciones" con un párrafo explicativo por
  cada decisión de estimación seleccionada, en inglés y español.
* Personalización del gráfico de red: disposición, nodos, etiquetas,
  aristas (colores, tipo de línea, umbral, pesos visibles) y leyenda, con los
  valores por defecto de EGAnet.

## Plataforma (fase 0)

* Esqueleto del módulo adoptado de AssumptionsLab 1.6.0, primer análisis
  (Análisis Exploratorio de Grafos), conjunto de datos de ejemplo, integración
  continua y documentación.
