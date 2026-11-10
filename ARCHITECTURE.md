# EGAnetLab Architecture

**Version:** 1.0 (2026-10-31: adopted from AssumptionsLab's ARCHITECTURE.md
v1.2, keeping every architectural rule that came out of jamovi's official
review of AssumptionsLab; sections 6, 10, 11, 14 and 16 rewritten for
network psychometrics with EGAnet)  
**Project:** EGAnetLab  
**License:** GNU General Public License v3.0  
**Author:** Arquímedes De León Chacón Chacón

---

# Table of Contents

1. Introduction
2. Architectural Philosophy
3. High-Level Architecture
4. Directory Structure
5. Module Architecture
6. Data Flow
7. Analysis Lifecycle
8. Report Generation Architecture
9. Interpretation Engine
10. Graphical Architecture
11. Methodological Library
12. Internationalization
13. Documentation Architecture
14. Future Expansion
15. Design Principles

16. EGAnet-Specific Architecture

---

# 1. Introduction

EGAnetLab has been designed as a modular scientific software platform for
estimating and evaluating the dimensional structure of psychological
measures with network psychometrics, and supporting methodological decision
making.

The architecture prioritizes

• scientific rigor;

• modularity;

• maintainability;

• educational value;

• reproducibility.

Every component has a clearly defined responsibility.

-------------------------------------------------------------------------------

# Introducción

EGAnetLab ha sido diseñado como una plataforma modular para la evaluación
de la estructura dimensional de medidas psicológicas con psicometría de
redes y el apoyo a la toma de decisiones metodológicas.

La arquitectura prioriza

• rigor científico;

• modularidad;

• mantenibilidad;

• valor educativo;

• reproducibilidad.

Cada componente posee una responsabilidad claramente definida.

-------------------------------------------------------------------------------

# 2. Architectural Philosophy

The architecture follows five fundamental principles.

### Separation of responsibilities

Each file performs one well-defined task.

### Progressive workflow

Every analysis follows the same logical sequence.

### Educational software

The software explains statistical decisions rather than merely producing
results.

### Scientific transparency

Every methodological decision can be identified inside the source code.

### Scalability

New analyses should integrate without modifying the existing architecture.

-------------------------------------------------------------------------------

# Filosofía arquitectónica

Cada nuevo módulo debe adaptarse a la arquitectura existente.

La arquitectura nunca debe adaptarse a un módulo específico.

-------------------------------------------------------------------------------

# 3. High-Level Architecture

```
                USER

                  │

                  ▼

        User Interface (.yaml)

                  │

                  ▼

        Analysis Engine (.R)

                  │

                  ▼

    Statistical Computations

                  │

                  ▼

      Diagnostic Evaluation

                  │

                  ▼

 Methodological Interpretation

                  │

                  ▼

        Report Generation

                  │

                  ▼

            Final Output
```

-------------------------------------------------------------------------------

# Arquitectura general

Toda información sigue un flujo unidireccional.

No existen ciclos innecesarios.

-------------------------------------------------------------------------------

# 4. Directory Structure

```
EGAnetLab/

│

├── R/

├── jamovi/

│   └── assets/

├── inst/

│   └── assets/

├── data/

├── data-raw/

├── docs/

├── tests/

├── .github/

├── README.md

├── LICENSE

├── CODE_STYLE.md

├── DEVELOPER_GUIDE.md

├── ARCHITECTURE.md

├── NEWS.md

├── DESCRIPTION

└── NAMESPACE
```

-------------------------------------------------------------------------------

## Responsibilities

### R/

Implements every statistical algorithm. `R/shared-helpers.R` holds every
small function (`.el_*()`) duplicated identically across two or more
analysis files — translation, HTML block builders, row-adding wrappers,
number cleaning, plot palettes, item preparation and EGAnet error capture.
A new duplicate belongs there, not copy-pasted into a third file. See
DEVELOPER_GUIDE.md §13.

### jamovi/

Defines analysis options and user interfaces. Also holds `jamovi/assets/`,
the module's own icon and the bundled example dataset.

### inst/

Package-installed resources: icons/logos and the plain-text `CITATION` file.

### data/ and data-raw/

`data/` ships the bundled example dataset shown inside jamovi (registered
under `datasets:` in `jamovi/0000.yaml`); `data-raw/` holds the script that
produces it reproducibly from the original source export.

### docs/

Contains project documentation.

### tests/

Stores validation procedures.

-------------------------------------------------------------------------------

# 5. Module Architecture

Every analysis consists of four primary components.

```
analysis.a.yaml

↓

analysis.u.yaml

↓

analysis.r.yaml

↓

analysis.b.R
```

-------------------------------------------------------------------------------

## analysis.a.yaml

Defines

• options

• variables

• controls

• defaults

-------------------------------------------------------------------------------

## analysis.u.yaml

Defines

• layout

• groups

• visibility

• interface organization

-------------------------------------------------------------------------------

## analysis.r.yaml

Defines

• result tables

• images

• HTML outputs

• textual reports

-------------------------------------------------------------------------------

## analysis.b.R

Implements

• validation

• computations

• diagnostics

• graphics

• interpretations

• reporting

-------------------------------------------------------------------------------

# 6. Data Flow

```
Item Selection

↓

Input Validation (Category A: >= 3 items, no empty or constant item)

↓

Missing Data Handling (pairwise or listwise, chosen by the user, reported)

↓

Correlation Matrix (Pearson, Spearman, cosine or automatic polychoric)

↓

Network Estimation (GLASSO, TMFG or BGGM)

↓

Community Detection (Walktrap, Louvain or Leiden + unidimensionality check)

↓

Structure Diagnostics (TEFI, network loadings, stability, redundancy)

↓

Network Graphics

↓

Interpretation Engine

↓

Report Assembly

↓

Output
```

-------------------------------------------------------------------------------

# Flujo de datos

Cada etapa depende únicamente de la anterior.

No deben existir cálculos redundantes: cada objeto devuelto por EGAnet se
calcula una sola vez por ejecución y se reutiliza para tablas, gráficos e
interpretación.

-------------------------------------------------------------------------------

# 7. Analysis Lifecycle

Every module should follow exactly the same lifecycle.

```
Initialization

↓

Validation

↓

Preparation

↓

Analysis

↓

Diagnostics

↓

Interpretation

↓

Recommendations

↓

Report

↓

Finish
```

This workflow must remain consistent throughout the project.

-------------------------------------------------------------------------------

# Ciclo de vida del análisis

La experiencia del usuario debe ser idéntica en todos los módulos.

-------------------------------------------------------------------------------

# 8. Report Generation Architecture

Reports are generated after every statistical computation has been completed.

The report is composed of

Introduction

↓

Descriptive Statistics

↓

Assumption Diagnostics

↓

Interpretation

↓

Recommendations

↓

References

Each section should be generated independently.

A report is only ever fully blocked (`jmvcore::reject()`) by a condition
that prevents the whole analysis from running. A single failed diagnostic
test never blocks the report — its row always renders, tiered "Not
computable" with a specific footnote. See CODE_STYLE.md §19.1.

-------------------------------------------------------------------------------

# Arquitectura del informe

La generación del informe nunca debe mezclarse con los cálculos estadísticos.

Un informe solo queda completamente bloqueado (`jmvcore::reject()`) por
una condición que impide ejecutar todo el análisis. Una única prueba
diagnóstica fallida nunca bloquea el informe — su fila siempre se
renderiza, como "No computable" con una nota al pie específica. Ver
CODE_STYLE.md §19.1.

-------------------------------------------------------------------------------

# 9. Interpretation Engine

The interpretation engine represents one of the most important components of
EGAnetLab.

Its objective is to transform statistical outputs into methodological
recommendations.

```
Statistical Results

↓

Methodological Rules

↓

Interpretation Templates

↓

Educational Explanation

↓

Recommendations
```

The engine should never merely reproduce numerical values.

-------------------------------------------------------------------------------

# Motor de interpretación

Toda interpretación debe responder

¿Qué ocurrió?

¿Por qué?

¿Qué significa?

¿Qué debe hacer ahora el investigador?

-------------------------------------------------------------------------------

# 10. Graphical Architecture

Graphs are organized according to methodological purpose.

```
Network Structure (nodes colored by dimension)

↓

Stability (item and dimension replication across bootstrap samples)

↓

Redundancy (wTO between item pairs)

↓

Fit Comparison (TEFI across alternative structures)
```

Graphs should reinforce interpretation rather than duplicate numerical
results.

Ordinary plots (stability bars, fit comparisons) inherit their visual identity
from jamovi's own Theme/Palette settings via its native `ggtheme`/`theme`
mechanism, exactly as in AssumptionsLab. Network plots are the one exception:
EGAnet draws them itself (GGally::ggnet2) with a manual color scale, and adding
jamovi's ggtheme on top would draw axes and a panel background behind the
network. For those, the `plotPalette` option offers EGAnet's default palette
plus two colorblind-safe alternatives (Okabe-Ito, viridis), and the render
function receives only the network matrix and memberships through
`image$state`, never the whole EGA object.

-------------------------------------------------------------------------------

# Arquitectura gráfica

Los gráficos constituyen herramientas metodológicas.

No elementos decorativos.

Los gráficos ordinarios (barras de estabilidad, comparaciones de ajuste)
heredan su identidad visual de los ajustes de Tema/Paleta de jamovi vía su
mecanismo nativo `ggtheme`/`theme`, igual que en AssumptionsLab. Los gráficos
de red son la excepción: EGAnet los dibuja por su cuenta (GGally::ggnet2) con
una escala de color manual, y agregar encima el ggtheme de jamovi dibujaría
ejes y un fondo de panel detrás de la red. Para ellos, la opción
`plotPalette` ofrece la paleta por defecto de EGAnet más dos alternativas
aptas para daltonismo (Okabe-Ito, viridis), y la función de render recibe
solo la matriz de la red y las pertenencias vía `image$state`, nunca el
objeto EGA completo.

-------------------------------------------------------------------------------

# 11. Methodological Library

The EGA Library is an independent educational subsystem, built as a jamovi
analysis that reads nothing from the user's dataset, following the final
design of AssumptionsLab's Assumption Library:

• its content (network psychometrics concepts, network models, community
detection algorithms, TEFI, stability, redundancy) is static `content:` text
in `jamovi/egalibrary.r.yaml`, translated through jamovi's native i18n catalog
(`jamovi/i18n/es.po`);

• `.run()` only shows or hides sections by topic;

• long topics are split into several `Html` items, because a single R string
literal with Unicode escapes cannot exceed about 10,000 characters;

• it carries no `refs:` (jamovi renders `refs:` only under `Table` results)
and points to `docs/Bibliography.md` instead.

Per-analysis citations use jamovi's native mechanism (`jamovi/00refs.yaml` +
`refs:` on each `Table`). The complete APA 7th edition reference list lives in
`docs/Bibliography.md`. There is no Bibliography analysis in the menu.

-------------------------------------------------------------------------------

# Biblioteca metodológica

La EGA Library es un subsistema educativo independiente, construido como un
análisis de jamovi que no lee nada del conjunto de datos del usuario,
siguiendo el diseño final de la Assumption Library de AssumptionsLab:

• su contenido (conceptos de psicometría de redes, modelos de red, algoritmos
de detección de comunidades, TEFI, estabilidad, redundancia) es texto
estático `content:` en `jamovi/egalibrary.r.yaml`, traducido por el catálogo
i18n nativo de jamovi (`jamovi/i18n/es.po`);

• `.run()` solo muestra u oculta secciones por tema;

• los temas largos se dividen en varios ítems `Html`, porque un literal de
cadena de R con escapes Unicode no puede superar unos 10.000 caracteres;

• no lleva `refs:` (jamovi solo muestra `refs:` bajo resultados `Table`) y en
su lugar remite a `docs/Bibliography.md`.

Las citas por análisis usan el mecanismo nativo de jamovi
(`jamovi/00refs.yaml` + `refs:` en cada `Table`). La lista completa en APA 7.ª
edición vive en `docs/Bibliography.md`. No hay un análisis Bibliography en el
menú.

-------------------------------------------------------------------------------

# 12. Internationalization

EGAnetLab is bilingual through two separate mechanisms.

```
Source code comments          Everything the user reads
                              (jamovi i18n)

English, then a Spanish       Follows jamovi's own language setting:
"# ES:" block below           menus, result titles and the report text
(CODE_STYLE.md)               alike. One catalog, jamovi/i18n/catalog.pot
                              + es.po, compiled to inst/i18n/es.json.
```

The catalog is jamovi's native mechanism. Its compiler extracts every
title, description and label from the .a.yaml, .u.yaml, .r.yaml and
0000.yaml files, and every literal string inside jmvcore's `.()` in `R/`.
Report text assembled at runtime lives in `R/texts.R`, in English, as
`.("...")` literals keyed by (section, key) and read with
`.el_text(self, section, key)`; short labels are written as `.("...")`
where they are used. Variable parts go in `sprintf()` placeholders after
translation, so each sentence stays one translatable unit.

Rules that follow from how `.()` works:

• `.()` finds the analysis (`self`) in its calling frame, so a helper
outside the analysis class takes `self` as its first argument (as jmv's
own `errors.R` does), or receives text already translated.

• Each string passed to `.()` is a literal, so the catalog tooling can
extract it; a computed key is resolved inside `.el_text()`, never by
building the English text at runtime.

• Every source string is written in English. gettext maps one source string
to one translation, so the same English string cannot take two different
Spanish translations; reword one of them instead.

• Outside jamovi (tests, a plain R session), `.()` follows LANGUAGE, then
LC_MESSAGES, then English; the tests use `LANGUAGE=es` to check the Spanish
report.

A new language is one more `.po` file, with no R code changes. The module
had a per-analysis Report Language option until 1.0.0; jamovi's library
review (2026) asked for it to be replaced by this mechanism, so the report
now follows the language a user chose for jamovi. If a feature jamovi lacks
is needed (for example, a results language independent of the interface),
it is requested from jamovi rather than rebuilt in the module.

-------------------------------------------------------------------------------

# Internacionalización

EGAnetLab es bilingüe mediante dos mecanismos separados.

```
Comentarios de código         Todo lo que lee el usuario
                              (i18n de jamovi)

Inglés, seguido de un         Sigue el ajuste de idioma de jamovi: menús,
bloque "# ES:" en español     títulos de resultados y texto del informe
debajo (CODE_STYLE.md)        por igual. Un solo catálogo,
                              jamovi/i18n/catalog.pot + es.po, compilado
                              en inst/i18n/es.json.
```

El catálogo es el mecanismo nativo de jamovi. Su compilador extrae cada
title, description y label de los archivos .a.yaml, .u.yaml, .r.yaml y
0000.yaml, y cada texto literal dentro de `.()` de jmvcore en `R/`. El
texto del informe que se arma en tiempo de ejecución vive en `R/texts.R`,
en inglés, como literales `.("...")` indexados por (sección, clave) y
leídos con `.el_text(self, sección, clave)`; las etiquetas cortas se
escriben como `.("...")` donde se usan. Las partes variables van en
marcadores de `sprintf()` después de traducir, para que cada oración siga
siendo una sola unidad traducible.

Reglas que se derivan de cómo funciona `.()`:

• `.()` busca el análisis (`self`) en el marco que lo llama, así que una
función auxiliar fuera de la clase del análisis recibe `self` como primer
argumento (igual que `errors.R` de jmv), o recibe el texto ya traducido.

• Cada texto pasado a `.()` es un literal, para que las herramientas del
catálogo puedan extraerlo; una clave calculada se resuelve dentro de
`.el_text()`, nunca armando el texto en inglés en tiempo de ejecución.

• Todo texto fuente se escribe en inglés. gettext asigna una traducción a
cada texto fuente, así que un mismo texto en inglés no puede tener dos
traducciones distintas al español; en ese caso se reformula uno de ellos.

• Fuera de jamovi (pruebas, una sesión simple de R), `.()` sigue LANGUAGE,
luego LC_MESSAGES y luego el inglés; las pruebas usan `LANGUAGE=es` para
comprobar el informe en español.

Un idioma nuevo es un archivo `.po` más, sin cambios en el código R. El
módulo tuvo una opción Report Language por análisis hasta la 1.0.0; la
revisión de la biblioteca de jamovi (2026) pidió reemplazarla por este
mecanismo, así que el informe sigue ahora el idioma que el usuario eligió
para jamovi. Si hace falta algo que jamovi no ofrece (por ejemplo, un
idioma de resultados independiente de la interfaz), se le solicita a
jamovi en lugar de reconstruirlo en el módulo.

-------------------------------------------------------------------------------

# 13. Documentation Architecture

Documentation exists at four levels.

```
Repository

↓

Module

↓

Source File

↓

Function
```

Each level should answer progressively more detailed questions.

Repository

What is EGAnetLab?

Module

What analysis is implemented?

Source File

How is the analysis organized?

Function

How is each task performed?

-------------------------------------------------------------------------------

# Arquitectura documental

La documentación constituye un componente de la arquitectura.

No un elemento accesorio.

-------------------------------------------------------------------------------

# 14. Future Expansion

The architecture is designed so that each EGAnet capability is added as one
more analysis, without structural changes. Planned analyses, in release
order:

| Phase | Analysis | EGAnet functions |
| --- | --- | --- |
| 1 | Exploratory Graph Analysis | `EGA`, `EGA.fit`, `riEGA`, `tefi`, `net.loads`, `net.scores` |
| 2 | Bootstrap EGA | `bootEGA`, `dimensionStability`, `itemStability`, `itemDiagnostics` |
| 3 | Redundancy (UVA) | `UVA`, `wto` |
| 3 | Model Comparison | `CFA`, `LCT`, `tefi.compare`, `network.fit` |
| 4 | Hierarchical EGA | `hierEGA`, `genTEFI` |
| 5 | Measurement Invariance | `invariance`, `community.compare` |
| 5 | Network Comparison | `network.compare`, `network.confusion` |
| 6 | Dynamic EGA | `dynEGA`, `glla`, `Embed` |
| 7 | EGA Library | none (static content) |

-------------------------------------------------------------------------------

# Expansión futura

La escalabilidad constituye un principio fundamental del proyecto. Cada
capacidad de EGAnet se agrega como un análisis más, en el orden de la tabla
anterior, sin cambios estructurales.

-------------------------------------------------------------------------------

# 15. Design Principles

Every architectural decision should satisfy the following principles.

### Scientific

Algorithms should faithfully implement accepted statistical procedures.

### Educational

Users should understand every methodological decision.

### Modular

Components should remain independent whenever possible.

### Transparent

Every important decision should be documented.

### Maintainable

Future developers should understand the architecture without external guidance.

### Consistent

Every module should behave as part of the same software ecosystem.

### Reproducible

Analyses should produce reproducible results from identical data.

-------------------------------------------------------------------------------

# Principios de diseño

La arquitectura de EGAnetLab pretende equilibrar

ingeniería del software,

metodología estadística,

experiencia del usuario

y

valor educativo.

Estos principios deberán preservarse durante toda la evolución del proyecto.

-------------------------------------------------------------------------------

# 16. EGAnet-Specific Architecture

Four conditions that AssumptionsLab never faced shape every EGAnetLab
analysis.

**Computation time.** `bootEGA()`, `invariance()` and `UVA()` can take minutes,
and jamovi re-runs an analysis on every option change. Analyses that resample
therefore (1) expose an explicit "Run" checkbox that is off by default,
(2) declare strict `clearWith` lists so that cosmetic options never trigger a
recomputation, (3) cache their results with `setState()`, and (4) report
partial progress with `private$.checkpoint()`.

**Reproducibility.** Every resampling analysis exposes its seed in the
interface, with a fixed default, and prints it in the report notes, so that a
result can be reproduced exactly.

**Dependencies.** EGAnet imports igraph, qgraph, semPlot, lavaan, glasso,
GGally and sna, and needs compilation. The `.jmo` is therefore large, and
must be built with `jmvtools::install()` against jamovi's own R version on
each platform before every release.

**Ordinal data and missing values.** EGAnet's automatic correlation switches
to polychoric/tetrachoric correlations for items with few categories. The
report always states which correlation was used and why, and how many cases
entered the analysis under the missing-data rule the user chose. Observations
are never removed silently.

-------------------------------------------------------------------------------

# Arquitectura específica de EGAnet

Cuatro condiciones que AssumptionsLab nunca enfrentó dan forma a cada
análisis de EGAnetLab.

**Tiempo de cómputo.** `bootEGA()`, `invariance()` y `UVA()` pueden tardar
minutos, y jamovi vuelve a ejecutar un análisis con cada cambio de opción. Por
eso, los análisis que remuestrean (1) exponen una casilla explícita "Run"
desactivada por defecto, (2) declaran listas `clearWith` estrictas para que
las opciones cosméticas nunca provoquen un nuevo cálculo, (3) guardan sus
resultados con `setState()` y (4) informan el progreso parcial con
`private$.checkpoint()`.

**Reproducibilidad.** Cada análisis con remuestreo expone su semilla en la
interfaz, con un valor fijo por defecto, y la imprime en las notas del
informe, para que un resultado pueda reproducirse exactamente.

**Dependencias.** EGAnet importa igraph, qgraph, semPlot, lavaan, glasso,
GGally y sna, y necesita compilación. Por eso el `.jmo` es grande y debe
construirse con `jmvtools::install()` contra la versión de R de jamovi en cada
plataforma antes de cada publicación.

**Datos ordinales y valores perdidos.** La correlación automática de EGAnet
cambia a correlaciones policóricas/tetracóricas para ítems con pocas
categorías. El informe siempre dice qué correlación se usó y por qué, y
cuántos casos entraron al análisis bajo la regla de datos faltantes que eligió
el usuario. Nunca se eliminan observaciones en silencio.

-------------------------------------------------------------------------------

# Final Statement

EGAnetLab is designed to make network psychometrics teachable: every
dimensional decision it reports can be traced to its source literature and
explained in plain language.

-------------------------------------------------------------------------------

# Declaración final

EGAnetLab está diseñado para que la psicometría de redes pueda enseñarse:
cada decisión dimensional que informa puede rastrearse hasta su literatura de
origen y explicarse en lenguaje claro.

-------------------------------------------------------------------------------


**End of document**
