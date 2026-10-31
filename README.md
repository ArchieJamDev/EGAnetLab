# EGAnetLab

[![License: GPL v3](https://img.shields.io/badge/License-GPLv3-blue.svg)](LICENSE)
[![CI](https://github.com/ArchieJamDev/EGAnetLab/actions/workflows/jamovi-check.yml/badge.svg)](https://github.com/ArchieJamDev/EGAnetLab/actions/workflows/jamovi-check.yml)

> **A jamovi module for Exploratory Graph Analysis and evidence-based decisions about dimensional structure.**

EGAnetLab is an open-source [jamovi](https://www.jamovi.org/) module that
brings the network psychometrics methods of the
[EGAnet](https://r-ega.net) R package to researchers, students and
practitioners. Like its sibling module
[AssumptionsLab](https://github.com/ArchieJamDev/AssumptionsLab), it does not
stop at the numbers: every result comes with methodological guidance,
plain-language interpretation and the next step to take.

**Status:** version 0.1.0, platform phase. The module architecture, bilingual
report system, citations, tests and continuous integration are in place,
together with a first Exploratory Graph Analysis. The remaining analyses
arrive phase by phase (see [Roadmap](#roadmap)).

---

## Analyses

| Menu | Analysis | Status |
| --- | --- | --- |
| Dimensionality | Exploratory Graph Analysis | 0.1.0: dimensions, memberships, TEFI, network loadings, network plot |
| Dimensionality | Bootstrap EGA | Planned (phase 2) |
| Item quality | Redundancy (UVA) | Planned (phase 3) |
| Item quality | Model Comparison | Planned (phase 3) |
| Dimensionality | Hierarchical EGA | Planned (phase 4) |
| Groups and time | Measurement Invariance | Planned (phase 5) |
| Groups and time | Network Comparison | Planned (phase 5) |
| Groups and time | Dynamic EGA | Planned (phase 6) |
| Methodological Guide | EGA Library | Planned (phase 7) |

## Methodological philosophy

Every interpretation answers four questions: what happened, why, what it
means, and what the researcher should do now. Thresholds come from the
published literature and are cited in jamovi's native reference format under
each table; the complete APA 7th edition list is in
[docs/Bibliography.md](docs/Bibliography.md).

Reports are available in English and Spanish through each analysis' *Report
Language* option, independently of jamovi's interface language, which is
translated through jamovi's own catalog.

## Installation

Until the first release is published in the jamovi library, install from
source with [jmvtools](https://dev.jamovi.org/):

```r
install.packages("jmvtools", repos = c("https://repo.jamovi.org", "https://cran.r-project.org"))
jmvtools::install()   # run from the repository root, with jamovi installed
```

The bundled example dataset (`eganetlab_wmt2.csv`, the WMT-2 items from
EGAnet) appears in jamovi's Data Library.

## For developers

- [ARCHITECTURE.md](ARCHITECTURE.md): how the module is organized.
- [DEVELOPER_GUIDE.md](DEVELOPER_GUIDE.md): how to add an analysis.
- [CODE_STYLE.md](CODE_STYLE.md): coding, error-handling and i18n rules.
- [CONTRIBUTING.md](CONTRIBUTING.md): how to contribute.

## Roadmap

0. Platform (this release).
1. Exploratory Graph Analysis, complete (EGA.fit, riEGA, network scores).
2. Bootstrap EGA: dimension and item stability.
3. Redundancy (UVA) and Model Comparison.
4. Hierarchical EGA.
5. Measurement Invariance and Network Comparison.
6. Dynamic EGA.
7. EGA Library, validation report and first public release.

## License and author

GNU General Public License v3.0. EGAnet itself is distributed under AGPL-3.0;
GPL-3.0 section 13 permits combining the two.

Arquímedes De León Chacón Chacón, Universidad Católica Andrés Bello (UCAB),
Caracas, Venezuela.

---

# EGAnetLab (Español)

EGAnetLab es un módulo de código abierto para jamovi que lleva los métodos de
psicometría de redes del paquete de R EGAnet a investigadores, estudiantes y
profesionales. Igual que AssumptionsLab, acompaña cada resultado con
orientación metodológica, interpretación en lenguaje claro y el siguiente paso
recomendado. Los informes están disponibles en español e inglés mediante la
opción *Report Language* de cada análisis.

**Estado:** versión 0.1.0, fase de plataforma. Ya están la arquitectura del
módulo, el sistema de informes bilingüe, las citas, las pruebas y la
integración continua, junto con un primer Análisis Exploratorio de Grafos. Los
demás análisis llegan por fases (ver la hoja de ruta anterior).
