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
            interp_low_loadings = "%d item(s) have a dominant network loading below 0.15 (small): %s. Their assignment is weakly supported; the Stability (bootstrap) section will show whether they replicate.",
            interp_next = "Next step: tick Run bootstrap in the Stability (bootstrap) box to check whether the number of dimensions and each item's membership are stable across resamples before interpreting the structure. It uses exactly the estimation options above.",
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
            uniMethod_LE = "The Leading eigenvalue check applies the leading eigenvalue community algorithm to the zero-order correlation matrix: a single community means one dimension (Golino et al., 2020; see references). It is an established alternative to the Louvain check.",
            h_bootType = "Bootstrap type",
            bootType_parametric = "Parametric bootstrap draws each new sample from a multivariate normal distribution with the correlation matrix of your data and the same number of cases. It reproduces the estimated correlation structure exactly in expectation and is EGAnet's default (Christensen & Golino, 2021; see references).",
            bootType_resampling = "Resampling bootstrap draws cases from your data with replacement. It keeps the real response distributions (skewness, number of categories, outliers) instead of assuming normality, so prefer it when items are markedly non-normal or when you want the stability estimate to reflect the observed responses.",
            uva_cut = "Redundancy is flagged when two items reach a weighted topological overlap (wTO) of %s or more. The value .25 is the cutoff recommended by Christensen, Garrido and Golino (2023; see references) after extensive simulation; lower it only to explore borderline pairs, not to decide which items to remove.",
            iter_seed = "The analysis uses %d bootstrap samples with seed %d. More samples give more precise stability estimates; 500 is the usual minimum for reporting. The same seed with the same data and options always reproduces the same results; report it with your findings."
        ),

        scores = list(
            guide = c(
                "Network scores weight each item by its network loading on its own dimension (Christensen & Golino, 2021; see references), so items more central to a dimension count more. They are the network counterpart of factor scores.",
                "Scale: EGAnet first standardizes each item (z score: mean 0, SD 1 in this sample) and then adds the items weighted by their loadings. The scores are therefore centered at 0: negative values are below the sample average and positive values above it. They are not on the response scale of the items, and their mean is 0 by construction.",
                "r with mean score: correlation between the network score and the unweighted mean of the same items (the mean keeps dimensions with different numbers of items on the same scale). Values near 1 mean the weighting changes little; lower values mean the items contribute very unequally to the dimension.",
                "Save network scores (in the Network scores box) adds one column per dimension to the dataset, so the scores can be used in other analyses. People with a missing response on any item of a dimension get no score for it.",
                "Save item means adds one column per dimension with the mean of the items each person answered, on the original response scale (for example, 1 to 5). Use them when you need scores that are easy to read in the units of the questionnaire."
            ),
            failed = "EGAnet could not compute network scores: %s.",
            saved_title = "Network score %s",
            saved_desc = "Network score for dimension %s (EGAnetLab, EGAnet::net.scores)",
            mean_title = "Item mean %s",
            mean_desc = "Mean of the answered items of dimension %s (EGAnetLab)"
        ),

        uva = list(
            intro = c(
                "Unique Variable Analysis (UVA) looks for redundant items: pairs that share so many of their connections in the network that they behave almost like the same item (Christensen, Garrido & Golino, 2023; see references).",
                "It uses the weighted topological overlap (wTO) of the network estimated above: the more two items are linked to the same other items with similar strength, the higher their wTO. Redundant items inflate a dimension and can create small artificial dimensions made only of near-duplicates."
            ),
            guide = c(
                "Pairs: every pair with wTO of .20 or more, from highest to lowest. Above .30 is large-to-very-large redundancy, .25 to .30 moderate-to-large, .20 to .25 small-to-moderate.",
                "Same dimension: redundant items usually fall in the same dimension; a redundant pair split across dimensions deserves a close look at its wording.",
                "Redundant sets: items linked by wTO at or above the cutoff. The suggestion follows EGAnet's automatic rule: with two items it keeps the one less redundant with the rest of the scale; with three or more it keeps the one most central to the set."
            ),
            mag_large = "Large to very large",
            mag_moderate = "Moderate to large",
            mag_small = "Small to moderate",
            yes = "Yes",
            no = "No",
            no_pairs = "No pair reaches wTO .20",
            failed = "EGAnet could not complete the redundancy analysis: %s. The EGA results above are not affected.",
            interp_none = "No pair of items reaches a wTO of %s, so there is no evidence of redundancy (local dependence) at the recommended cutoff. Each item contributes its own information to the network.",
            interp_borderline = "%d pair(s) fall between .20 and the cutoff (%s). They are not redundant by the recommended rule, but check their wording if they also stand out elsewhere (low stability or low loadings).",
            interp_sets = "%d redundant set(s) at wTO %s or more: %s. Items in a set share most of their connections, so together they add less information than their number suggests and can pull the dimensional structure toward themselves.",
            interp_suggest = "EGAnet's automatic rule would keep %s and remove %s. Treat this as a starting point: decide by content (which item best covers the construct, has the clearest wording, or is needed for a balanced scale), and consider combining items instead of removing them when both cover essential content.",
            interp_split = "Redundant pair(s) placed in different dimensions: %s. This often signals an item that bridges two dimensions; review its content before keeping it.",
            interp_unstable = "Item(s) that are both redundant and unstable in the bootstrap: %s. These are the strongest candidates for revision.",
            interp_unstable_borderline = "Borderline pair(s) that involve an item unstable in the bootstrap: %s. The overlap is below the redundancy cutoff, but it may explain why the item moves between dimensions across samples; review the wording of both items.",
            interp_next = "Next step: if you remove or combine items, run the analysis again on the revised item set and compare the number of dimensions, the stability and the TEFI with the original solution. Report the cutoff and the items you changed."
        ),

        bootega = list(
            intro = c(
                "The bootstrap checks whether the dimensions found above are a stable property of the items or an accident of this particular sample (Christensen & Golino, 2021; see references).",
                "It draws many new samples from your data, runs EGA with the same estimation options on each one and records how many dimensions appear and where each item ends up. A solid structure appears again and again; an unstable one changes from sample to sample.",
                "Read the results in this order: the distribution of the number of dimensions, the stability of each dimension, the stability of each item, and the stability interpretation."
            ),
            done = "Bootstrap complete: %d samples (%s), seed %d. Changing only the report language, the stability cutoff or the plot options reuses these results without running the bootstrap again.",
            failed = "EGAnet could not complete the bootstrap: %s. The EGA above was estimated, so the problem lies in some bootstrap samples: try the resampling bootstrap, or fewer items with very few categories.",
            guide_summary = c(
                "Median and interval: the typical number of dimensions across samples, and the range that contains the middle 95% of samples.",
                "Frequency: how often each number of dimensions appeared. A dominant value that matches the original sample supports the structure.",
                "Structural consistency: the proportion of samples in which a dimension reappears with exactly the same items.",
                "Item stability: the proportion of samples in which an item is placed in its original dimension."
            ),
            stable = "Stable",
            unstable = "Below cutoff",
            isolated = "Isolated (no edges)",
            interp_mode_match = "Across %d samples, the most frequent solution has %d dimensions (%s of samples), the same number found in the original sample. The median is %s, with 95%% of samples between %s and %s dimensions.",
            interp_mode_mismatch = "Across %d samples, the most frequent solution has %d dimensions (%s of samples), while the original sample showed %d. The original structure is not the typical one across samples; interpret it with caution and look at which items are unstable. The median is %s, with 95%% of samples between %s and %s dimensions.",
            interp_mode_weak = "The most frequent solution appears in only %s of samples, below the %s cutoff, so the number of dimensions itself is not firmly established: neighbouring solutions are also common. Report the full frequency distribution, not only the most frequent value.",
            interp_dims_low = "Dimension(s) with structural consistency below %s: %s. These dimensions are often not reproduced with exactly the same items; usually one or more of their items move to another dimension in some samples (see item stability).",
            interp_dims_ok = "Every dimension reappears with exactly the same items in at least %s of samples.",
            interp_items_low = "%d item(s) stay in their original dimension in fewer than %s of samples: %s. Low stability usually means an item relates to more than one dimension, overlaps heavily with another item, or is ambiguously worded. A commonly used cutoff is .70.",
            interp_items_ok = "Every item stays in its original dimension in at least %s of samples, which supports the stability of the structure.",
            interp_next = "Next step: if some items are unstable, check them for redundancy (the Redundancy (UVA) box) and for content before deciding to remove or rewrite them, then run the analysis again, with the bootstrap, on the revised item set. Report the number of samples, the bootstrap type and the seed.",
            plot_stability = "Proportion of samples in the original dimension",
            plot_dims = "Number of dimensions",
            plot_prop = "Proportion of samples",
            plot_original = "Original sample",
            plot_other = "Other"
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
            interp_low_loadings = "%d ítem(s) tienen una carga de red dominante menor que 0.15 (pequeña): %s. Su asignación tiene poco respaldo; la sección Stability (bootstrap) mostrará si se replica.",
            interp_next = "Siguiente paso: marque Run bootstrap en la caja Stability (bootstrap) para verificar si el número de dimensiones y la pertenencia de cada ítem son estables entre remuestreos antes de interpretar la estructura. Usa exactamente las opciones de estimación de arriba.",
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
            uniMethod_LE = "La verificación de autovalor principal aplica el algoritmo de comunidades leading eigenvalue a la matriz de correlaciones de orden cero: una sola comunidad significa una dimensión (Golino et al., 2020; ver referencias). Es una alternativa establecida a la verificación Louvain.",
            h_bootType = "Tipo de bootstrap",
            bootType_parametric = "El bootstrap paramétrico extrae cada muestra nueva de una distribución normal multivariada con la matriz de correlaciones de sus datos y el mismo número de casos. Reproduce en promedio exactamente la estructura de correlaciones estimada y es el valor por defecto de EGAnet (Christensen y Golino, 2021; ver referencias).",
            bootType_resampling = "El bootstrap por remuestreo extrae casos de sus datos con reemplazo. Conserva las distribuciones reales de respuesta (asimetría, número de categorías, valores atípicos) en lugar de suponer normalidad, así que prefiéralo cuando los ítems sean claramente no normales o cuando quiera que la estabilidad refleje las respuestas observadas.",
            uva_cut = "La redundancia se señala cuando dos ítems alcanzan un solapamiento topológico ponderado (wTO) de %s o más. El valor .25 es el punto de corte recomendado por Christensen, Garrido y Golino (2023; ver referencias) tras una amplia simulación; bájelo solo para explorar pares limítrofes, no para decidir qué ítems eliminar.",
            iter_seed = "El análisis usa %d muestras bootstrap con semilla %d. Más muestras dan estimaciones de estabilidad más precisas; 500 es el mínimo habitual para informar. La misma semilla con los mismos datos y opciones reproduce siempre los mismos resultados; infórmela junto con sus hallazgos."
        ),

        scores = list(
            guide = c(
                "Las puntuaciones de red ponderan cada ítem por su carga de red en su propia dimensión (Christensen y Golino, 2021; ver referencias), así que los ítems más centrales de una dimensión pesan más. Son el equivalente en redes de las puntuaciones factoriales.",
                "Escala: EGAnet primero estandariza cada ítem (puntuación z: media 0 y DE 1 en esta muestra) y luego suma los ítems ponderados por sus cargas. Por eso las puntuaciones están centradas en 0: los valores negativos están por debajo del promedio de la muestra y los positivos por encima. No están en la escala de respuesta de los ítems, y su media es 0 por construcción.",
                "r con el promedio: correlación entre la puntuación de red y el promedio sin ponderar de los mismos ítems (el promedio mantiene en la misma escala dimensiones con distinto número de ítems). Valores cercanos a 1 indican que la ponderación cambia poco; valores menores indican que los ítems aportan de forma muy desigual a la dimensión.",
                "Guardar puntuaciones de red (en la caja Network scores) añade una columna por dimensión al conjunto de datos, para usar las puntuaciones en otros análisis. Quien tenga una respuesta perdida en algún ítem de una dimensión queda sin puntuación en ella.",
                "Guardar promedios de los ítems añade una columna por dimensión con el promedio de los ítems que cada persona respondió, en la escala original de respuesta (por ejemplo, de 1 a 5). Úselos cuando necesite puntuaciones fáciles de leer en las unidades del cuestionario."
            ),
            failed = "EGAnet no pudo calcular las puntuaciones de red: %s.",
            saved_title = "Puntuación de red %s",
            saved_desc = "Puntuación de red de la dimensión %s (EGAnetLab, EGAnet::net.scores)",
            mean_title = "Promedio de ítems %s",
            mean_desc = "Promedio de los ítems respondidos de la dimensión %s (EGAnetLab)"
        ),

        uva = list(
            intro = c(
                "El Análisis de Variables Únicas (UVA) busca ítems redundantes: pares que comparten tantas de sus conexiones en la red que se comportan casi como el mismo ítem (Christensen, Garrido y Golino, 2023; ver referencias).",
                "Usa el solapamiento topológico ponderado (wTO) de la red estimada arriba: cuanto más se conectan dos ítems con los mismos otros ítems y con fuerza similar, mayor es su wTO. Los ítems redundantes inflan una dimensión y pueden crear dimensiones pequeñas y artificiales formadas solo por casi duplicados."
            ),
            guide = c(
                "Pares: todo par con wTO de .20 o más, de mayor a menor. Por encima de .30 es redundancia grande a muy grande, de .25 a .30 moderada a grande, de .20 a .25 pequeña a moderada.",
                "Misma dimensión: los ítems redundantes suelen caer en la misma dimensión; un par redundante repartido entre dimensiones merece una revisión cuidadosa de su redacción.",
                "Conjuntos redundantes: ítems unidos por un wTO igual o mayor que el punto de corte. La sugerencia sigue la regla automática de EGAnet: con dos ítems conserva el menos redundante con el resto de la escala; con tres o más conserva el más central del conjunto."
            ),
            mag_large = "Grande a muy grande",
            mag_moderate = "Moderada a grande",
            mag_small = "Pequeña a moderada",
            yes = "Sí",
            no = "No",
            no_pairs = "Ningún par alcanza wTO .20",
            failed = "EGAnet no pudo completar el análisis de redundancia: %s. Los resultados de EGA de arriba no se ven afectados.",
            interp_none = "Ningún par de ítems alcanza un wTO de %s, así que no hay evidencia de redundancia (dependencia local) con el punto de corte recomendado. Cada ítem aporta su propia información a la red.",
            interp_borderline = "%d par(es) quedan entre .20 y el punto de corte (%s). No son redundantes según la regla recomendada, pero revise su redacción si además destacan en otros resultados (baja estabilidad o cargas bajas).",
            interp_sets = "%d conjunto(s) redundante(s) con wTO de %s o más: %s. Los ítems de un conjunto comparten la mayoría de sus conexiones, así que juntos aportan menos información de la que sugiere su número y pueden atraer la estructura dimensional hacia sí.",
            interp_suggest = "La regla automática de EGAnet conservaría %s y eliminaría %s. Tómelo como punto de partida: decida por el contenido (qué ítem cubre mejor el constructo, tiene la redacción más clara o es necesario para una escala equilibrada), y considere combinar ítems en lugar de eliminarlos cuando ambos cubren contenido esencial.",
            interp_split = "Par(es) redundante(s) ubicados en dimensiones distintas: %s. Suele indicar un ítem que hace de puente entre dos dimensiones; revise su contenido antes de conservarlo.",
            interp_unstable = "Ítem(s) que son a la vez redundantes e inestables en el bootstrap: %s. Son los candidatos más claros a revisión.",
            interp_unstable_borderline = "Par(es) limítrofe(s) que incluyen un ítem inestable en el bootstrap: %s. El solapamiento está por debajo del punto de corte de redundancia, pero puede explicar por qué el ítem cambia de dimensión entre muestras; revise la redacción de ambos ítems.",
            interp_next = "Siguiente paso: si elimina o combina ítems, vuelva a ejecutar el análisis con el conjunto revisado y compare el número de dimensiones, la estabilidad y el TEFI con la solución original. Informe el punto de corte y los ítems que cambió."
        ),

        bootega = list(
            intro = c(
                "El bootstrap verifica si las dimensiones halladas arriba son una propiedad estable de los ítems o un accidente de esta muestra en particular (Christensen y Golino, 2021; ver referencias).",
                "Extrae muchas muestras nuevas de sus datos, ejecuta EGA con las mismas opciones de estimación en cada una y registra cuántas dimensiones aparecen y dónde queda cada ítem. Una estructura sólida aparece una y otra vez; una inestable cambia de una muestra a otra.",
                "Lea los resultados en este orden: la distribución del número de dimensiones, la estabilidad de cada dimensión, la estabilidad de cada ítem y la interpretación de la estabilidad."
            ),
            done = "Bootstrap completado: %d muestras (%s), semilla %d. Si cambia solo el idioma del informe, el punto de corte de estabilidad o las opciones de gráfico, se reutilizan estos resultados sin volver a ejecutar el bootstrap.",
            failed = "EGAnet no pudo completar el bootstrap: %s. El EGA de arriba sí se estimó, así que el problema está en algunas muestras bootstrap: pruebe el bootstrap por remuestreo, o menos ítems con muy pocas categorías.",
            guide_summary = c(
                "Mediana e intervalo: el número típico de dimensiones entre muestras y el rango que contiene el 95% central de las muestras.",
                "Frecuencia: cuántas veces apareció cada número de dimensiones. Un valor dominante que coincide con la muestra original respalda la estructura.",
                "Consistencia estructural: la proporción de muestras en que una dimensión reaparece exactamente con los mismos ítems.",
                "Estabilidad del ítem: la proporción de muestras en que un ítem queda en su dimensión original."
            ),
            stable = "Estable",
            unstable = "Bajo el punto de corte",
            isolated = "Aislado (sin aristas)",
            interp_mode_match = "En %d muestras, la solución más frecuente tiene %d dimensiones (%s de las muestras), el mismo número hallado en la muestra original. La mediana es %s, y el 95%% de las muestras está entre %s y %s dimensiones.",
            interp_mode_mismatch = "En %d muestras, la solución más frecuente tiene %d dimensiones (%s de las muestras), mientras que la muestra original mostró %d. La estructura original no es la típica entre muestras; interprétela con cautela y revise qué ítems son inestables. La mediana es %s, y el 95%% de las muestras está entre %s y %s dimensiones.",
            interp_mode_weak = "La solución más frecuente aparece solo en %s de las muestras, por debajo del punto de corte de %s, así que el número de dimensiones en sí no está firmemente establecido: las soluciones vecinas también son comunes. Informe la distribución completa de frecuencias, no solo el valor más frecuente.",
            interp_dims_low = "Dimensión(es) con consistencia estructural menor que %s: %s. Estas dimensiones a menudo no se reproducen con exactamente los mismos ítems; por lo general uno o más de sus ítems pasan a otra dimensión en algunas muestras (ver estabilidad de los ítems).",
            interp_dims_ok = "Cada dimensión reaparece con exactamente los mismos ítems en al menos %s de las muestras.",
            interp_items_low = "%d ítem(s) permanecen en su dimensión original en menos de %s de las muestras: %s. Una estabilidad baja suele indicar que el ítem se relaciona con más de una dimensión, se superpone mucho con otro ítem o tiene una redacción ambigua. Un punto de corte de uso común es .70.",
            interp_items_ok = "Cada ítem permanece en su dimensión original en al menos %s de las muestras, lo que respalda la estabilidad de la estructura.",
            interp_next = "Siguiente paso: si hay ítems inestables, revise su redundancia (caja Redundancy (UVA)) y su contenido antes de decidir eliminarlos o reescribirlos; luego vuelva a ejecutar el análisis, con el bootstrap, sobre el conjunto revisado. Informe el número de muestras, el tipo de bootstrap y la semilla.",
            plot_stability = "Proporción de muestras en la dimensión original",
            plot_dims = "Número de dimensiones",
            plot_prop = "Proporción de muestras",
            plot_original = "Muestra original",
            plot_other = "Otro"
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
