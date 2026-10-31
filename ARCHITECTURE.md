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
(`jamovi/i18n/es.po`), with no `reportLang` option;

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
i18n nativo de jamovi (`jamovi/i18n/es.po`), sin opción `reportLang`;

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

EGAnetLab follows a bilingual philosophy, implemented as three
separate mechanisms that must not be confused with one another.

```
Source code                Report content              Interface
comments                   (reportLang)                 (jamovi i18n)

English, then       Chosen per-analysis by    Follows jamovi's own
a Spanish "# ES:"    the user, independent     UI-language setting,
block below          of jamovi's own UI        independent of
(CODE_STYLE.md)       language (tr()/          reportLang
                       texts.R)
                                                jamovi/i18n/catalog.pot
                                                + es.po, auto-extracted
                                                from every title/
                                                description/label in
                                                .a.yaml/.u.yaml/.r.yaml/
                                                0000.yaml — no markup
                                                needed in the yaml
                                                itself
```

The interface catalog is jamovi's own native mechanism, not a custom
reimplementation: its compiler scans every yaml definition file and
extracts translatable strings automatically. `jmvtools::i18nCreate("es")`
seeds a translation file; `jmvtools::i18nUpdate("es")` re-syncs it as
strings change. Because gettext's model is one source string to one
translation, every yaml source string must be written in one consistent
language (English) — a module with mixed-language yaml text produces a
mixed-language catalog no translation file can fix.

A future language added to any of the three mechanisms should not require
architectural modification — source comments simply gain no new language
(bilingual is fixed), report content gains a new `reportLang` choice plus
`texts.R` entries, and the interface gains one more `.po` file.

## Why report content keeps its own `reportLang`, on purpose

`reportLang`/`tr()`/`texts.R` is not a stopgap waiting to be replaced by
jamovi's native `.()` catalog. `.()` is only safe for text jamovi's
compiler extracts from yaml — `jmvcore::Options$translate()` builds its
translator once per R engine process and never invalidates it, so text
assembled dynamically in R and routed through `.()` freezes at whatever
language was active when that process started; nothing short of
restarting jamovi picks up a change. Confirmed by reading `jmvcore`
directly after the regression first shipped (and was reverted) in a
sibling module, FiabilityLab.

Instant, reliable switching also serves the module's teaching mission
directly, not just its mechanics. EGAnetLab is built to teach
methodology to novice researchers and students. Seeing the same
analytical paragraph in Spanish and then, with one click, in English is
itself part of that lesson — it shows a student early why precise
methodological vocabulary matters, since that precision is what
eventually gets read and published. A mechanism that cannot guarantee an
instant, reliable switch would undermine that, not just inconvenience it.

-------------------------------------------------------------------------------

# Internacionalización

La arquitectura de EGAnetLab sigue una filosofía bilingüe,
implementada como tres mecanismos separados que no deben confundirse entre
sí.

```
Comentarios de           Contenido del informe        Interfaz
código fuente             (reportLang)                 (i18n de jamovi)

Inglés, seguido de   Elegido por el usuario     Sigue el propio ajuste
un bloque "# ES:"     para cada análisis,        de idioma de interfaz
en español debajo     independiente del idioma   de jamovi, independiente
(CODE_STYLE.md)        de interfaz de jamovi      de reportLang
                        (tr()/texts.R)
                                                   jamovi/i18n/catalog.pot
                                                   + es.po, extraídos
                                                   automáticamente de
                                                   cada title/
                                                   description/label en
                                                   .a.yaml/.u.yaml/
                                                   .r.yaml/0000.yaml —
                                                   sin necesitar ninguna
                                                   marca en el yaml
```

El catálogo de interfaz es el propio mecanismo nativo de jamovi, no una
reimplementación propia: su compilador escanea cada archivo de definición
yaml y extrae los strings traducibles automáticamente.
`jmvtools::i18nCreate("es")` siembra un archivo de traducción;
`jmvtools::i18nUpdate("es")` lo resincroniza a medida que cambian los
strings. Como el modelo de gettext es un string fuente por cada
traducción, todo string fuente del yaml debe escribirse en un solo idioma
consistente (inglés) — un módulo con texto yaml en idiomas mezclados
produce un catálogo mezclado que ningún archivo de traducción puede
arreglar.

Un idioma futuro agregado a cualquiera de los tres mecanismos no debería
requerir modificación arquitectónica — los comentarios de código
simplemente no ganan un idioma nuevo (el bilingüismo es fijo), el
contenido del informe gana una nueva opción de `reportLang` más entradas
en `texts.R`, y la interfaz gana un archivo `.po` más.

## Por qué el contenido del informe conserva su propio `reportLang`, a propósito

`reportLang`/`tr()`/`texts.R` no es una solución provisional a la espera
de ser reemplazada por el catálogo nativo `.()` de jamovi. `.()` solo es
seguro para texto que el compilador de jamovi extrae del yaml —
`jmvcore::Options$translate()` construye su traductor una sola vez por
proceso del motor de R y nunca lo invalida, así que el texto ensamblado
dinámicamente en R y enrutado por `.()` queda congelado en el idioma que
estaba activo cuando ese proceso arrancó; nada salvo reiniciar jamovi
recoge un cambio. Confirmado leyendo `jmvcore` directamente después de que
la regresión se publicara (y se revirtiera) en un módulo hermano,
FiabilityLab.

El cambio de idioma instantáneo y confiable también sirve directamente a
la misión pedagógica del módulo, no solo a su mecánica. EGAnetLab
está construido para enseñar metodología a investigadores noveles y
estudiantes. Ver el mismo párrafo analítico en español y luego, con un
clic, en inglés es en sí mismo parte de esa lección — le muestra al
estudiante desde temprano por qué importa la precisión del vocabulario
metodológico, ya que esa precisión es lo que eventualmente se lee y se
publica. Un mecanismo que no puede garantizar un cambio instantáneo y
confiable socavaría eso, no solo lo haría menos cómodo.

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
