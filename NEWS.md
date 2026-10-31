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

## Plataforma (fase 0)

* Esqueleto del módulo adoptado de AssumptionsLab 1.6.0, primer análisis
  (Análisis Exploratorio de Grafos), conjunto de datos de ejemplo, integración
  continua y documentación.
