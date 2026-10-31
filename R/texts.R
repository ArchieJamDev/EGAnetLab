# -----------------------------------------------------------------------------
# EGAnetLab
# A jamovi module for Exploratory Graph Analysis and evidence-based
# methodological decision support on dimensional structure.
#
# Copyright (C) 2026 Arquímedes De León Chacón Chacón
#
# This file is part of EGAnetLab.
#
# EGAnetLab is free software: you can redistribute it and/or modify
# it under the terms of the GNU General Public License as published by
# the Free Software Foundation, either version 3 of the License,
# or (at your option) any later version.
#
# EGAnetLab is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.
# See the GNU General Public License for more details.
#
# You should have received a copy of the GNU General Public License
# along with EGAnetLab.
# If not, see https://www.gnu.org/licenses/.
# -----------------------------------------------------------------------------

# -----------------------------------------------------------------------------
# Text repository.
# ES: Repositorio de textos.
#
# Every user-facing report string that is assembled at runtime lives here, in
# both report languages (en/es), keyed by (language, section, key). This is
# the `reportLang` mechanism inherited from AssumptionsLab (ARCHITECTURE.md
# §12): report text switches instantly when the user changes the analysis'
# Report Language option, independently of jamovi's own interface language.
# Static interface text (titles, labels, descriptions in the .yaml files)
# goes through jamovi's native i18n catalog instead (jamovi/i18n/es.po).
#
# ES: Todo texto del informe que se arma en tiempo de ejecución vive aquí, en
# ambos idiomas (en/es), indexado por (idioma, sección, clave). Es el
# mecanismo `reportLang` heredado de AssumptionsLab (ARCHITECTURE.md §12): el
# texto del informe cambia al instante cuando el usuario cambia la opción
# Report Language del análisis, sin depender del idioma de la interfaz de
# jamovi. El texto estático de la interfaz (títulos, etiquetas y
# descripciones de los .yaml) pasa por el catálogo i18n nativo de jamovi
# (jamovi/i18n/es.po).
#
# Writing rule: every interpretation answers four questions (what happened,
# why, what it means, what the researcher should do now). Never write a
# bracketed reference number; append "see references" / "ver referencias"
# after an author-year mention (CODE_STYLE.md §21).
#
# ES: Regla de redacción: cada interpretación responde cuatro preguntas (qué
# ocurrió, por qué, qué significa, qué debe hacer ahora el investigador).
# Nunca escribir un número de referencia entre corchetes; agregar "see
# references" / "ver referencias" después de una mención autor-año
# (CODE_STYLE.md §21).
# -----------------------------------------------------------------------------

.el_texts <- list(

    en = list(

        common = list(
            no_data = "No data are available.",
            too_few_items = "Select at least three items. Exploratory Graph Analysis needs at least three variables to estimate a network in which communities (dimensions) can form.",
            empty_item = "The following items have fewer than two observed values and cannot enter a correlation matrix: %s. Remove them from the analysis.",
            constant_item = "The following items have zero variance (every respondent gave the same answer), so their correlations are undefined: %s. Remove them from the analysis; a constant item carries no information about dimensional structure.",
            too_few_cases = "Fewer than two complete cases remain after listwise deletion. Switch Missing Values to pairwise, or review the missing-data pattern.",
            estimation_failed = "EGAnet could not estimate the network: %s. This usually means the correlation matrix is not positive definite (too few cases for the number of items, or items that are near-duplicates). Check the sample size and item redundancy, or try a different correlation or network model.",
            warnings_title = "Messages from EGAnet",
            not_computable = "Not computable"
        ),

        ega = list(
            intro = c(
                "Exploratory Graph Analysis (EGA) estimates how many dimensions underlie a set of items, and which items belong to each, by modeling the items as a network rather than as indicators of latent factors (Golino & Epskamp, 2017; see references).",
                "Each item is a node. Edges are regularized partial correlations: the association between two items after controlling for all the others. A community detection algorithm then groups densely connected items; each group is an estimated dimension.",
                "Read the results in this order: the number of dimensions and its fit (TEFI), the item memberships, the network loadings, and finally the network plot."
            ),
            guide_summary = c(
                "Number of dimensions: how many communities the algorithm found. Isolated items (no edges) are not assigned to any dimension.",
                "TEFI (Total Entropy Fit Index): lower values indicate a better-fitting structure. It is meaningful when comparing alternative structures for the same data, not as an absolute cut-off (Golino et al., 2021; see references).",
                "Correlation: with items that have few response categories, EGAnet's automatic option uses polychoric or tetrachoric correlations."
            ),
            guide_loadings = c(
                "Network loadings summarize how strongly each item is connected to each dimension, on a scale comparable to factor loadings (Christensen & Golino, 2021; see references).",
                "Proposed effect-size guidelines for the dominant loading: about 0.15 small, 0.25 moderate, 0.35 large."
            ),
            interp_dims_one = "EGA found a single dimension. The unidimensionality check (%s) did not separate the items into distinct communities, which supports treating the item set as measuring one construct.",
            interp_dims_many = "EGA found %d dimensions. The items group into %d communities of densely connected nodes, which suggests %d related but distinct constructs.",
            interp_isolated = "%d item(s) are not connected to any other item and were left without a dimension: %s. Isolated items share little unique variance with the rest; review their wording and content.",
            interp_tefi = "TEFI = %s. Compare it with the TEFI of an alternative structure (for example, a theoretical one) estimated on the same data; the lower value indicates the better-fitting structure.",
            interp_low_loadings = "%d item(s) have a dominant network loading below 0.15 (small): %s. Their assignment is weakly supported; the bootstrap stability analysis (Bootstrap EGA) will show whether they replicate.",
            interp_next = "Next step: run Bootstrap EGA on the same items to check whether the number of dimensions and each item's membership are stable across resamples before interpreting the structure.",
            loadings_failed = "Network loadings could not be computed for this structure: %s.",
            loadings_all_singleton = "Every item forms its own community, so network loadings are undefined."
        ),

        # Explanation of every estimation choice (one entry per option
        # value). Each paragraph says what the choice does and when to pick
        # an alternative.
        # ES: Explicación de cada elección de estimación (una entrada por
        # valor de opción). Cada párrafo dice qué hace la elección y cuándo
        # conviene otra.
        choices = list(
            intro = "Each estimation decision below is explained for the option currently selected, with guidance on when an alternative would fit your data better.",
            h_corr = "Correlation",
            h_naData = "Missing values",
            h_model = "Network model",
            h_algorithm = "Community detection",
            h_uniMethod = "Unidimensionality check",
            corr_auto = "Automatic lets EGAnet choose the correlation for each pair of items from their measurement level: polychoric for ordinal items (few categories), tetrachoric for dichotomous items and Pearson for continuous items. It is the recommended choice for Likert-type and right/wrong items, because Pearson correlations underestimate the association between categorical variables.",
            corr_pearson = "Pearson correlations treat every item as continuous and linearly related. Choose them for scale scores, reaction times or other genuinely continuous items with roughly symmetric distributions. With ordinal or dichotomous items they underestimate associations; use Automatic instead.",
            corr_spearman = "Spearman correlations use the ranks of the responses, so they capture monotonic (not only linear) relationships and are robust to skewness and outliers. They suit continuous items with markedly non-normal distributions. For items with few categories, Automatic (polychoric) is usually more accurate.",
            corr_cosine = "Cosine similarity measures the angle between response vectors rather than their linear association. It is used mainly with text-derived or high-dimensional data. For typical questionnaire items, Automatic or Pearson are better established in the EGA literature.",
            naData_pairwise = "Pairwise deletion computes each correlation from all respondents who answered both items, so no information is discarded. It is the usual choice when data are missing at random and missingness is modest. With heavy or patterned missingness the correlation matrix can become unstable; compare with Listwise.",
            naData_listwise = "Listwise deletion keeps only respondents who answered every item. Every correlation then comes from the same people, which keeps the matrix coherent, at the cost of sample size. Choose it when few cases are incomplete, or to check that pairwise results are not driven by missing-data patterns.",
            model_glasso = "GLASSO with EBIC model selection estimates a sparse network of regularized partial correlations: weak edges are shrunk to exactly zero, so only associations supported by the data remain. It is EGA's original and most studied estimator (Golino et al., 2020; see references) and works best with moderate to large samples.",
            model_TMFG = "TMFG (Triangulated Maximally Filtered Graph) keeps the strongest correlations under a fixed rule, always retaining 3(p - 2) edges for p items regardless of sample size. It does not depend on a regularization parameter, which makes it a useful robustness check against GLASSO, especially with small samples or few items per dimension.",
            model_BGGM = "BGGM estimates the network with a Bayesian Gaussian graphical model and keeps the edges whose posterior distribution supports a non-zero partial correlation. It expresses uncertainty about each edge directly and is a principled alternative to GLASSO, but it is slower. Use it to confirm a GLASSO solution from a different estimation framework.",
            algorithm_walktrap = "Walktrap groups items by short random walks along the edges: walks tend to stay inside densely connected regions, which become the dimensions. It is deterministic (the same data always give the same answer) and is the algorithm with the strongest simulation record in EGA (Golino et al., 2020; see references).",
            algorithm_louvain = "Louvain finds communities by maximizing modularity, merging items into groups level by level. It is fast and performs well in recent simulations, but it is stochastic: results can vary slightly between runs. Use it to check whether the Walktrap solution holds under a different algorithm.",
            algorithm_leiden = "Leiden refines Louvain and guarantees that every community it returns is internally connected, which Louvain does not. It is stochastic as well. Choose it as a modern alternative to Louvain, and compare its solution with Walktrap's.",
            uniMethod_louvain = "Before the multidimensional solution is accepted, EGA checks whether the items could be unidimensional. The Louvain check applies the Louvain algorithm to the zero-order correlation matrix: if it finds a single community, the structure is reported as one dimension. It is EGAnet's current default.",
            uniMethod_expand = "The Expand check is EGA's original unidimensionality test: it adds simulated variables that form a separate dimension and estimates the network again. If every real item ends up in one community, the items are treated as unidimensional. Use it to reproduce results from studies that used the original EGA procedure.",
            uniMethod_LE = "The Leading eigenvalue check applies the leading eigenvalue community algorithm to the zero-order correlation matrix: a single community means one dimension (Golino et al., 2020; see references). It is an established alternative to the Louvain check."
        )
    ),

    es = list(

        common = list(
            no_data = "No hay datos disponibles.",
            too_few_items = "Seleccione al menos tres ítems. El Análisis Exploratorio de Grafos necesita al menos tres variables para estimar una red en la que puedan formarse comunidades (dimensiones).",
            empty_item = "Los siguientes ítems tienen menos de dos valores observados y no pueden entrar en una matriz de correlaciones: %s. Quítelos del análisis.",
            constant_item = "Los siguientes ítems tienen varianza cero (todas las personas dieron la misma respuesta), por lo que sus correlaciones no están definidas: %s. Quítelos del análisis; un ítem constante no aporta información sobre la estructura dimensional.",
            too_few_cases = "Quedan menos de dos casos completos tras la eliminación por lista. Cambie Valores perdidos a pairwise o revise el patrón de datos faltantes.",
            estimation_failed = "EGAnet no pudo estimar la red: %s. Suele deberse a que la matriz de correlaciones no es definida positiva (muy pocos casos para el número de ítems, o ítems casi duplicados). Revise el tamaño de muestra y la redundancia de los ítems, o pruebe otra correlación u otro modelo de red.",
            warnings_title = "Mensajes de EGAnet",
            not_computable = "No computable"
        ),

        ega = list(
            intro = c(
                "El Análisis Exploratorio de Grafos (EGA) estima cuántas dimensiones subyacen a un conjunto de ítems, y qué ítems pertenecen a cada una, modelando los ítems como una red en lugar de como indicadores de factores latentes (Golino & Epskamp, 2017; ver referencias).",
                "Cada ítem es un nodo. Las aristas son correlaciones parciales regularizadas: la asociación entre dos ítems tras controlar todos los demás. Luego, un algoritmo de detección de comunidades agrupa los ítems densamente conectados; cada grupo es una dimensión estimada.",
                "Lea los resultados en este orden: el número de dimensiones y su ajuste (TEFI), la pertenencia de los ítems, las cargas de red y, por último, el gráfico de la red."
            ),
            guide_summary = c(
                "Número de dimensiones: cuántas comunidades encontró el algoritmo. Los ítems aislados (sin aristas) no se asignan a ninguna dimensión.",
                "TEFI (Índice de Ajuste de Entropía Total): valores más bajos indican una estructura con mejor ajuste. Tiene sentido al comparar estructuras alternativas para los mismos datos, no como punto de corte absoluto (Golino et al., 2021; ver referencias).",
                "Correlación: con ítems de pocas categorías de respuesta, la opción automática de EGAnet usa correlaciones policóricas o tetracóricas."
            ),
            guide_loadings = c(
                "Las cargas de red resumen con qué fuerza se conecta cada ítem con cada dimensión, en una escala comparable a la de las cargas factoriales (Christensen & Golino, 2021; ver referencias).",
                "Guías propuestas de tamaño del efecto para la carga dominante: alrededor de 0.15 pequeña, 0.25 moderada, 0.35 grande."
            ),
            interp_dims_one = "EGA encontró una sola dimensión. La verificación de unidimensionalidad (%s) no separó los ítems en comunidades distintas, lo que respalda tratar el conjunto de ítems como medida de un único constructo.",
            interp_dims_many = "EGA encontró %d dimensiones. Los ítems se agrupan en %d comunidades de nodos densamente conectados, lo que sugiere %d constructos relacionados pero distintos.",
            interp_isolated = "%d ítem(s) no están conectados con ningún otro y quedaron sin dimensión: %s. Los ítems aislados comparten poca varianza única con el resto; revise su redacción y contenido.",
            interp_tefi = "TEFI = %s. Compárelo con el TEFI de una estructura alternativa (por ejemplo, la teórica) estimada con los mismos datos; el valor más bajo indica la estructura con mejor ajuste.",
            interp_low_loadings = "%d ítem(s) tienen una carga de red dominante menor que 0.15 (pequeña): %s. Su asignación tiene poco respaldo; el análisis de estabilidad por bootstrap (Bootstrap EGA) mostrará si se replica.",
            interp_next = "Siguiente paso: ejecute Bootstrap EGA con los mismos ítems para verificar si el número de dimensiones y la pertenencia de cada ítem son estables entre remuestreos antes de interpretar la estructura.",
            loadings_failed = "No se pudieron calcular las cargas de red para esta estructura: %s.",
            loadings_all_singleton = "Cada ítem forma su propia comunidad, así que las cargas de red no están definidas."
        ),

        choices = list(
            intro = "Cada decisión de estimación se explica a continuación para la opción seleccionada, con orientación sobre cuándo una alternativa se ajustaría mejor a sus datos.",
            h_corr = "Correlación",
            h_naData = "Valores perdidos",
            h_model = "Modelo de red",
            h_algorithm = "Detección de comunidades",
            h_uniMethod = "Verificación de unidimensionalidad",
            corr_auto = "Automática deja que EGAnet elija la correlación de cada par de ítems según su nivel de medida: policórica para ítems ordinales (pocas categorías), tetracórica para ítems dicotómicos y Pearson para ítems continuos. Es la opción recomendada para ítems tipo Likert y de acierto/error, porque la correlación de Pearson subestima la asociación entre variables categóricas.",
            corr_pearson = "La correlación de Pearson trata cada ítem como continuo y relacionado linealmente. Elíjala para puntuaciones de escala, tiempos de reacción u otros ítems realmente continuos con distribuciones aproximadamente simétricas. Con ítems ordinales o dicotómicos subestima las asociaciones; use Automática en su lugar.",
            corr_spearman = "La correlación de Spearman usa los rangos de las respuestas, así que capta relaciones monótonas (no solo lineales) y es robusta a la asimetría y a los valores atípicos. Conviene para ítems continuos con distribuciones claramente no normales. Para ítems con pocas categorías, Automática (policórica) suele ser más precisa.",
            corr_cosine = "La similitud coseno mide el ángulo entre los vectores de respuesta en lugar de su asociación lineal. Se usa sobre todo con datos derivados de texto o de alta dimensión. Para ítems de cuestionario habituales, Automática o Pearson están mejor establecidas en la literatura de EGA.",
            naData_pairwise = "La eliminación por pares calcula cada correlación con todas las personas que respondieron ambos ítems, así que no se descarta información. Es la opción habitual cuando los datos faltan al azar y la proporción de perdidos es moderada. Con muchos perdidos o patrones sistemáticos la matriz de correlaciones puede volverse inestable; compare con Por lista.",
            naData_listwise = "La eliminación por lista conserva solo a quienes respondieron todos los ítems. Así todas las correlaciones provienen de las mismas personas, lo que mantiene la matriz coherente, a costa del tamaño de muestra. Elíjala cuando pocos casos estén incompletos, o para comprobar que los resultados por pares no dependen del patrón de perdidos.",
            model_glasso = "GLASSO con selección EBIC estima una red dispersa de correlaciones parciales regularizadas: las aristas débiles se reducen exactamente a cero, así que solo quedan las asociaciones respaldadas por los datos. Es el estimador original y más estudiado de EGA (Golino et al., 2020; ver referencias) y funciona mejor con muestras medianas o grandes.",
            model_TMFG = "TMFG (Triangulated Maximally Filtered Graph) conserva las correlaciones más fuertes bajo una regla fija, reteniendo siempre 3(p - 2) aristas para p ítems, sin importar el tamaño de muestra. No depende de un parámetro de regularización, lo que lo hace útil como verificación de robustez frente a GLASSO, sobre todo con muestras pequeñas o pocos ítems por dimensión.",
            model_BGGM = "BGGM estima la red con un modelo gráfico gaussiano bayesiano y conserva las aristas cuya distribución posterior respalda una correlación parcial distinta de cero. Expresa directamente la incertidumbre de cada arista y es una alternativa fundamentada a GLASSO, aunque más lenta. Úsela para confirmar una solución GLASSO desde otro marco de estimación.",
            algorithm_walktrap = "Walktrap agrupa los ítems mediante caminatas aleatorias cortas por las aristas: las caminatas tienden a quedarse en regiones densamente conectadas, que se convierten en las dimensiones. Es determinista (los mismos datos dan siempre la misma respuesta) y es el algoritmo con mayor respaldo de simulación en EGA (Golino et al., 2020; ver referencias).",
            algorithm_louvain = "Louvain encuentra comunidades maximizando la modularidad, uniendo ítems en grupos nivel por nivel. Es rápido y rinde bien en simulaciones recientes, pero es estocástico: los resultados pueden variar ligeramente entre ejecuciones. Úselo para comprobar si la solución de Walktrap se mantiene con otro algoritmo.",
            algorithm_leiden = "Leiden refina Louvain y garantiza que cada comunidad que devuelve esté conectada internamente, algo que Louvain no asegura. También es estocástico. Elíjalo como alternativa moderna a Louvain y compare su solución con la de Walktrap.",
            uniMethod_louvain = "Antes de aceptar la solución multidimensional, EGA verifica si los ítems podrían ser unidimensionales. La verificación Louvain aplica el algoritmo Louvain a la matriz de correlaciones de orden cero: si encuentra una sola comunidad, la estructura se informa como una dimensión. Es el valor por defecto actual de EGAnet.",
            uniMethod_expand = "La verificación Expandir es la prueba de unidimensionalidad original de EGA: agrega variables simuladas que forman una dimensión aparte y vuelve a estimar la red. Si todos los ítems reales quedan en una sola comunidad, se consideran unidimensionales. Úsela para reproducir resultados de estudios que emplearon el procedimiento EGA original.",
            uniMethod_LE = "La verificación de autovalor principal aplica el algoritmo de comunidades leading eigenvalue a la matriz de correlaciones de orden cero: una sola comunidad significa una dimensión (Golino et al., 2020; ver referencias). Es una alternativa establecida a la verificación Louvain."
        )
    )
)

# -----------------------------------------------------------------------------
# Lookup helpers.
# ES: Funciones de búsqueda.
#
# .el_normalize_lang() maps whatever jamovi passes to "en" or "es".
# .el_text() resolves (lang, section, key), falling back to English and then
# to a visible "[missing text: ...]" marker, so a missing string is caught in
# review instead of rendering as an empty paragraph.
#
# ES: .el_normalize_lang() convierte lo que entregue jamovi en "en" o "es".
# .el_text() resuelve (idioma, sección, clave), recurre al inglés y luego a
# una marca visible "[missing text: ...]", para que un texto faltante se
# detecte en revisión en lugar de mostrarse como un párrafo vacío.
# -----------------------------------------------------------------------------
.el_normalize_lang <- function(lang) {
    if (is.null(lang) || length(lang) == 0 || is.na(lang[1]))
        return("en")
    lang_low <- tolower(as.character(lang)[1])
    if (lang_low %in% c("es", "esp", "español", "espanol", "spanish"))
        return("es")
    "en"
}

.el_text <- function(lang, section, key) {
    lang <- .el_normalize_lang(lang)
    value <- .el_texts[[lang]][[section]][[key]]
    if (is.null(value))
        value <- .el_texts[["en"]][[section]][[key]]
    if (is.null(value))
        value <- paste0("[missing text: ", section, ".", key, "]")
    value
}

.el_clean_text <- function(x) {
    x <- unlist(x, recursive = TRUE, use.names = FALSE)
    x <- as.character(x)
    x <- gsub("[\t\r\n]+", " ", x)
    x <- gsub(" +", " ", x)
    x <- trimws(x)
    x[nzchar(x)]
}
