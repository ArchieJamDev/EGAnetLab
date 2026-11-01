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
            estimation_failed = "EGAnetLab could not estimate the network: %s. This usually means the correlation matrix is not positive definite (too few cases for the number of items, or items that are near-duplicates). Check the sample size and item redundancy, or try a different correlation or network model.",
            warnings_title = "Messages from EGAnetLab",
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
                "Correlation: with items that have few response categories, EGAnetLab's automatic option uses polychoric or tetrachoric correlations."
            ),
            guide_loadings = c(
                "Network loadings summarize how strongly each item is connected to each dimension, on a scale comparable to factor loadings (Christensen & Golino, 2021; see references).",
                "Proposed effect-size guidelines for the dominant loading: about 0.15 small, 0.25 moderate, 0.35 large."
            ),
            edges_none = "The estimated network has no edges.",
            edges_note = "Weights are the partial correlations of the estimated network (each pair of items, controlling for all the others), from strongest to weakest in absolute value. A negative weight means the two items move in opposite directions once the rest are held constant.",
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
            corr_auto = "Automatic lets EGAnetLab choose the correlation for each pair of items from their measurement level: polychoric for ordinal items (few categories), tetrachoric for dichotomous items and Pearson for continuous items. It is the recommended choice for Likert-type and right/wrong items, because Pearson correlations underestimate the association between categorical variables.",
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
            uniMethod_louvain = "Before the multidimensional solution is accepted, EGA checks whether the items could be unidimensional. The Louvain check applies the Louvain algorithm to the zero-order correlation matrix: if it finds a single community, the structure is reported as one dimension. It is EGAnetLab's current default.",
            uniMethod_expand = "The Expand check is EGA's original unidimensionality test: it adds simulated variables that form a separate dimension and estimates the network again. If every real item ends up in one community, the items are treated as unidimensional. Use it to reproduce results from studies that used the original EGA procedure.",
            uniMethod_LE = "The Leading eigenvalue check applies the leading eigenvalue community algorithm to the zero-order correlation matrix: a single community means one dimension (Golino et al., 2020; see references). It is an established alternative to the Louvain check.",
            h_bootType = "Bootstrap type",
            bootType_parametric = "Parametric bootstrap draws each new sample from a multivariate normal distribution with the correlation matrix of your data and the same number of cases. It reproduces the estimated correlation structure exactly in expectation and is EGAnetLab's default (Christensen & Golino, 2021; see references).",
            bootType_resampling = "Resampling bootstrap draws cases from your data with replacement. It keeps the real response distributions (skewness, number of categories, outliers) instead of assuming normality, so prefer it when items are markedly non-normal or when you want the stability estimate to reflect the observed responses.",
            uva_cut = "Redundancy is flagged when two items reach a weighted topological overlap (wTO) of %s or more. The value .25 is the cutoff recommended by Christensen, Garrido and Golino (2023; see references) after extensive simulation; lower it only to explore borderline pairs, not to decide which items to remove.",
            h_derivative = "Derivative analysed",
            derivative_0 = "The level (derivative 0) is the smoothed value of each item within the window. Its structure is closest to that of the raw scores and keeps stable differences between occasions; choose it to describe states rather than change.",
            derivative_1 = "The first derivative is the rate of change of each item from one time point to the next. It is dynEGA's default and the most studied choice (Golino et al., 2022; see references): the dimensions group items that rise and fall together.",
            derivative_2 = "The second derivative is the acceleration of each item. It captures how changes speed up or slow down together, but it amplifies measurement noise and needs many time points per person; use it only with dense series.",
            bn_iter_seed = "Network stability (bootnet) uses %d samples resampling cases and %d samples dropping cases, with seed %d. About 1000 of each is the usual recommendation (Epskamp et al., 2018; see references); fewer give less precise intervals and CS coefficients. The same seed with the same data and options reproduces the same results.",
            iter_seed = "The analysis uses %d bootstrap samples with seed %d. More samples give more precise stability estimates; 500 is the usual minimum for reporting. The same seed with the same data and options always reproduces the same results; report it with your findings."
        ),

        scores = list(
            guide = c(
                "Network scores weight each item by its network loading on its own dimension (Christensen & Golino, 2021; see references), so items more central to a dimension count more. They are the network counterpart of factor scores.",
                "Scale: EGAnetLab first standardizes each item (z score: mean 0, SD 1 in this sample) and then adds the items weighted by their loadings. The scores are therefore centered at 0: negative values are below the sample average and positive values above it. They are not on the response scale of the items, and their mean is 0 by construction.",
                "r with mean score: correlation between the network score and the unweighted mean of the same items (the mean keeps dimensions with different numbers of items on the same scale). Values near 1 mean the weighting changes little; lower values mean the items contribute very unequally to the dimension.",
                "Save network scores (in the Network scores box) adds one column per dimension to the dataset, so the scores can be used in other analyses. People with a missing response on any item of a dimension get no score for it.",
                "Save item means adds one column per dimension with the mean of the items each person answered, on the original response scale (for example, 1 to 5). Use them when you need scores that are easy to read in the units of the questionnaire."
            ),
            failed = "EGAnetLab could not compute network scores: %s.",
            saved_title = "Network score %s",
            saved_desc = "Network score for dimension %s (EGAnetLab)",
            mean_title = "Item mean %s",
            mean_desc = "Mean of the answered items of dimension %s (EGAnetLab)"
        ),

        cfa = list(
            intro = c(
                "Confirmatory factor analysis (CFA) tests the structure found by EGA as a factor model: each dimension becomes a factor and each item loads only on its own factor (lavaan; Rosseel, 2012; see references).",
                "Fitting the CFA on the same data that produced the structure gives an optimistic fit. Splitting the sample at random gives an honest check: EGA finds the structure in subsample A (exploration) and the CFA tests it in subsample B (confirmation). The table shows the total sample and both subsamples side by side."
            ),
            estimator_auto_ordinal = "Estimator: WLSMV with items treated as ordinal (some items have fewer than 6 categories), as EGAnetLab's CFA() does.",
            estimator_auto_cont = "Estimator: MLR (robust maximum likelihood) with full-information handling of missing values, as EGAnetLab's CFA() does for items with 6 or more categories.",
            estimator_fixed = "Estimator: %s, as chosen in the options.",
            estimator_rule = "Why the ordinal rule differs from EGA: EGA's automatic correlations treat items with 7 or fewer categories as ordinal (polychoric), while the CFA uses WLSMV only below 6 categories, as EGAnetLab's CFA() does. With 6 or 7 categories the network therefore uses polychoric correlations and the CFA uses robust maximum likelihood, which performs well with that many categories (Rhemtulla, Brosseau-Liard & Savalei, 2012; see references). To use the same treatment in both, choose the CFA estimator in the options.",
            no_split_note = "The CFA uses the same sample as EGA, so its fit is optimistic. Tick Split the sample at random for a check in an independent subsample.",
            row_n = "Cases",
            row_dims = "Dimensions found by EGA",
            row_tefi = "TEFI",
            row_structure = "Structure tested by the CFA",
            row_structure_total = "EGA in the total sample",
            row_structure_A = "EGA in subsample A",
            row_chisq = "χ² (df), p",
            row_cfi = "CFI",
            row_tli = "TLI",
            row_rmsea = "RMSEA [90% CI]",
            row_srmr = "SRMR",
            row_chisq_df = "χ²/df",
            row_converged = "Converged",
            row_admissible = "Admissible solution",
            yes = "Yes",
            no = "No",
            changed = "Changes",
            new_dim = "new",
            dropped_factor = "Dimension(s) with a single item cannot form a factor and were left out of the CFA: %s.",
            failed = "lavaan could not fit the CFA%s: %s.",
            fit_guide = "Conventional guidelines (Hu & Bentler, 1999; see references): CFI and TLI of .95 or more, RMSEA of .06 or less and SRMR of .08 or less suggest good fit; CFI/TLI of .90 and RMSEA of .08 are often taken as acceptable. With WLSMV these cutoffs are only approximate.",
            fit_guide_more = "Other indices (Schermelleh-Engel, Moosbrugger & Müller, 2003; see references): χ²/df of 2 or less is good and 3 or less acceptable; GFI and NFI of .95 or more are good and .90 acceptable; AGFI of .90 or more is good and .85 acceptable; IFI is read like CFI. GFI and AGFI depend on sample size and are reported mostly by tradition; CFI, TLI, RMSEA and SRMR are the most recommended. AIC and BIC only compare models fitted to the same data (lower is better) and are not available with WLSMV.",
            interp_fit = "In %s, the CFA of the EGA structure gives CFI = %s, TLI = %s, RMSEA = %s and SRMR = %s, which suggests %s fit.",
            fit_good = "good",
            fit_acceptable = "acceptable",
            fit_poor = "poor",
            sample_total = "the total sample",
            sample_B = "subsample B (confirmation)",
            interp_dims_same = "EGA finds %s dimensions in the total sample, %s in subsample A and %s in subsample B: the number of dimensions replicates across random subsamples.",
            interp_dims_diff = "EGA finds %s dimensions in the total sample, %s in subsample A and %s in subsample B: the number of dimensions does not fully replicate across random subsamples, so interpret the structure with caution.",
            interp_agree = "%s of the items fall in the same dimension in subsamples A and B.",
            interp_changes = "Items that change dimension between subsamples A and B: %s. Compare them with the bootstrap item stability and the redundancy results.",
            interp_seed = "Split: %d cases in subsample A and %d in subsample B (seed %d). Report the seed so the split can be reproduced; a different seed gives a different split.",
            interp_next = "Next step: report the confirmation fit (subsample B) as the main evidence for the structure, and the total-sample fit as a reference. If the fit is poor, look at the items with low loadings or that change dimension."
        ),

        compare = list(
            intro = c(
                "This section compares the structure found by EGA with alternative structures for the same items, using the Total Entropy Fit Index (TEFI; Golino et al., 2021; see references). Every structure is evaluated on the same correlation matrix as the EGA above, so their TEFI values can be compared directly.",
                "Lower TEFI means a better fit: the items within each dimension share more information with each other than with the rest of the items."
            ),
            guide = c(
                "Other community algorithms: EGA is run again with the same network and each of the other algorithms (Walktrap, Louvain, Leiden). Louvain and Leiden start from random values, so they use the fixed seed 2026 and always give the same result with the same data.",
                "Theoretical structure: build it as in jamovi's Confirmatory Factor Analysis. Drag the items of each dimension into a factor, use Add New Factor for the next one, and click a factor's name to rename it. Items left out of every factor are not part of the theoretical structure.",
                "Items placed as in EGA: how many items fall in the same dimension as in the EGA solution, after matching each dimension with the EGA dimension it shares most items with.",
                "Difference from lowest: how far each structure is from the lowest TEFI among the structures that use the same items. There is no established cutoff for a meaningful difference.",
                "One dimension: TEFI is always 0 for a single dimension, so it cannot compare a unidimensional structure with multidimensional ones. EGA judges unidimensionality with its own check (see the choices above)."
            ),
            cfa_guide = "CFA fit for each structure: confirmatory factor analysis of each structure with lavaan (automatic estimator: WLSMV for items with fewer than 6 categories, otherwise MLR), with CFI, RMSEA and SRMR. It is estimated on the same data that produced the EGA solution, which favors that solution; for an independent test use the random split in the Confirmatory factor analysis box.",
            ega_label = "EGA solution (%s)",
            alt_label = "EGA with %s",
            theory_label = "Theoretical",
            agree = "%d of %d (%s%%)",
            alt_failed = "EGAnetLab could not estimate this structure: %s.",
            single = "One dimension: TEFI is always 0, so it is not compared.",
            unassigned = "Not in any dimension: %s. They are left out of TEFI, so this value is not compared with the others.",
            cfa_failed = "The CFA could not be estimated: %s.",
            theory_unknown = "The theoretical structure includes variables that are not among the Items of the analysis: %s. Add them to Items or remove them from the factors.",
            theory_duplicated = "These items are in more than one factor of the theoretical structure: %s. Each item can belong to one factor only.",
            theory_dup_dims = "These factor names are used more than once: %s.",
            theory_none = "The theoretical structure has no item of the analysis in any factor.",
            interp_best_ega = "The EGA solution has the lowest TEFI (%s) among the structures compared, so by entropy fit it is the structure that best separates the items into dimensions.",
            interp_best_other = "%s has the lowest TEFI (%s), %s below the EGA solution (%s). By entropy fit it separates the items into dimensions better than the EGA solution.",
            interp_same = "After removing it, EGA still finds %s dimensions with the same items, so the dimensional structure does not depend on this component.",
            interp_differs = "%s places %d of %d items as EGA (TEFI %s; %s from the lowest). Items that change dimension: %s.",
            interp_theory_vs_ega = "The theoretical structure places %d of %d items as EGA. The items EGA places elsewhere (%s) are the ones to examine: read their content and check whether they are also unstable in the bootstrap or redundant in UVA.",
            interp_theory_match = "The theoretical structure and the EGA solution group the items in the same way, which supports the intended structure.",
            interp_no_theory = "To compare the theoretical structure as well, drag its items into the factors of Theoretical structure, in the Compare structures (TEFI) box.",
            interp_single = "%s has a single dimension. TEFI is always 0 for one dimension, so it is not compared with the multidimensional structures; use the unidimensionality check of EGA for that question.",
            interp_cfa = "The CFA indices come from the same data that produced the EGA solution, so they favor it. Use them as a second view, and confirm with the random split in the Confirmatory factor analysis box.",
            interp_no_cutoff = "There is no established cutoff for a meaningful TEFI difference. Read the differences together with the bootstrap stability, the CFA fit and the content of the items that move, and report the TEFI of every structure compared."
        ),

        cfa_hier = list(
            unavailable = "The hierarchical EGA could not be estimated, so the hierarchical models were not fitted.",
            m_one = "One factor",
            m_ega = "Correlated factors (EGA)",
            m_ega_same = "Correlated factors (EGA = hierEGA lower order)",
            m_lower = "Correlated factors (hierEGA lower order)",
            m_higher = "Higher order (%s higher-order factor(s))",
            m_bifactor = "Bifactor (general + lower-order specific factors)",
            failed = "lavaan could not fit this model: %s.",
            not_converged = "lavaan did not reach convergence; do not interpret this row.",
            warning_note = "lavaan warned about this model: %s. The solution looks admissible, but review its estimates before preferring it.",
            interp_excluded = "%s is left out when picking the best fit: %s. Its fit indices are shown, but they cannot be read until that problem is resolved.",
            inadmissible_note = "lavaan flagged a problem with this solution: %s. Do not interpret or prefer this model until you review its estimates.",
            intro = "Every model here is fitted on the total sample and on the same items, so the rows can be compared directly. The correlated-factors models have no hierarchy; the higher-order model places the hierEGA higher-order dimensions above the lower-order factors, and the bifactor model adds a general factor on every item next to the lower-order factors (all uncorrelated; Reise, 2012; see references).",
            interp_none = "No model reached a converged and admissible solution, so there is no comparison to read.",
            interp_best_cfi = "The highest CFI is that of %s (%s).",
            interp_best_bic = "The lowest BIC, which balances fit and the number of parameters, is that of %s (%s).",
            interp_bic_gap_strong = "It is %s points below the next model: strong evidence in its favor.",
            interp_bic_gap_weak = "It is only %s points below the next model (less than 10), so BIC does not clearly separate them; choose by theory and by the loadings.",
            interp_no_ic = "AIC and BIC are not available with this estimator (WLSMV for ordinal items), so the comparison rests on CFI, TLI, RMSEA and SRMR.",
            interp_equivalent = "The higher-order model fits exactly as well as the correlated lower-order factors: with two or three lower-order factors under one higher-order factor, the higher level only re-expresses their correlations. The data cannot tell the two apart; the choice rests on theory and on how the scores will be used.",
            interp_higher_close = "The higher-order model reaches CFI %s against %s for the correlated lower-order factors. The loss of fit is limited (.01 or less) under this descriptive criterion, and the model is more restrictive; interpreting the structure as hierarchical requires further evaluation (theory, the loadings of the higher-order factors and replication in another sample).",
            interp_higher_worse = "The higher-order model reaches CFI %s against %s for the correlated lower-order factors. The loss is larger than .01: under this descriptive criterion the higher-order factors do not reproduce the correlations among the lower-order factors well, so the model without hierarchy is preferable.",
            interp_no_higher = "The hierarchical EGA found no higher-order level, so the higher-order model is not fitted.",
            interp_bifactor = "The bifactor model usually fits best because it is very flexible and also absorbs noise and response styles. Prefer it only when the general factor carries most of the common variance and the specific factors keep clear loadings; otherwise its better fit is not evidence of a general factor.",
            interp_optimistic = "These models are fitted on the same data that produced the EGA and hierEGA solutions, so their fit is optimistic. Report them as a comparison, and confirm the chosen model in a new sample."
        ),

        bifactor = list(
            intro = "This table opens up the bifactor model of the comparison above: for each item, its loading on the general factor (every item) and on its specific factor (the hierEGA lower-order dimension), and its residual variance. It shows whether the specific factors keep their own variance or collapse into the general factor, which is the usual source of inadmissible bifactor solutions (Rodriguez, Reise & Haviland, 2016; see references).",
            guide = c(
                "General and Specific: standardized loadings. In a sound bifactor model, items load clearly on the general factor and still keep visible loadings (.20 or more) on their specific factor.",
                "Residual variance: the part of the item not explained by either factor. A negative value is a Heywood case: the solution is not admissible.",
                "Check: Heywood case, loading above 1, a specific loading below .20 (the item adds almost nothing to its specific factor) or a general loading below .20."
            ),
            flag_heywood = "Heywood case",
            flag_above = "Loading above 1",
            flag_weak = "Weak specific loading",
            interp_ecv_high = "The general factor explains %s of the common variance (explained common variance, ECV = %s). From .70 upward, the items are close to unidimensional: the specific factors add little, and a single score is often defensible.",
            interp_ecv_low = "The general factor explains %s of the common variance (explained common variance, ECV = %s). Below .70, the specific factors keep an important part of the common variance, so the scale is not essentially unidimensional.",
            interp_collapse = "Specific factor %s collapses into the general factor: its loadings are mostly below .20 (mean absolute loading %s). The model probably has one specific factor too many; consider a bifactor model without it (bifactor S-1) or the correlated-factors model.",
            interp_few_items = "Specific factors with three items or fewer (number of items in parentheses): %s. A specific factor with so few items is weakly identified next to a general factor and is a common source of Heywood cases.",
            interp_weak_general = "Items with a general loading below .20: %s. They do not share the general factor; check their wording (for example, negatively worded items not reversed) or whether they belong to the scale.",
            flag_weak_general = "Weak general loading",
            interp_heywood = "Items with a negative residual variance (Heywood case): %s. Their loadings are pushed beyond what the data allow, usually because their specific factor is nearly empty or has very few items. Do not interpret the bifactor model while this happens.",
            interp_above = "Items with a standardized loading above 1: %s. This is not possible in an admissible solution; read it together with the Heywood cases.",
            interp_admissible = "No Heywood case or loading above 1 appears, so the bifactor solution is admissible; judge it by the ECV and by whether each specific factor keeps its own loadings.",
            interp_next = "Next step: if a specific factor collapses or has very few items, fit the model without it or keep the correlated-factors model. Do not add parameters suggested by modification indices to rescue an inadmissible bifactor: that tends to fit the noise of this sample."
        ),

        hier = list(
            intro = c(
                "Hierarchical EGA (hierEGA; Jiménez et al., 2023; see references) asks whether the dimensions are themselves grouped under broader, higher-order dimensions, such as a general factor.",
                "It works in two steps: it finds the lower-order dimensions with the lower level of the Louvain algorithm, computes each person's network score on them, and then runs EGA on those scores to find the higher-order dimensions. Louvain starts from random values, so it uses the fixed seed 2026."
            ),
            guide = c(
                "Lower and higher order: how many dimensions there are at each level. Higher-order dimensions group lower-order dimensions, not items.",
                "Item membership by level: the EGA column is the solution above; the lower-order column uses the same numbers where the dimensions match; the higher-order column shows the broader dimension each item ends up in.",
                "TEFI by level: EGAnetLab compares the entropy fit of the lower-order level with that of the higher-order level. A lower TEFI at the lower level favors correlated dimensions without a hierarchy; a lower TEFI at the higher level favors the hierarchical structure (EGAnetLab calls it bifactor)."
            ),
            cosine_note = "hierEGA does not accept the cosine similarity, so it uses the automatic correlation here.",
            failed = "EGAnetLab could not estimate the hierarchical EGA: %s. The results above are not affected.",
            row_lower = "Lower-order dimensions",
            row_higher = "Higher-order dimensions",
            row_tefi_lower = "TEFI, lower order",
            row_tefi_higher = "TEFI, higher order",
            row_tefi_general = "Generalized TEFI",
            row_better = "Better fit by TEFI",
            better_lower = "Correlated lower-order dimensions",
            better_higher = "Hierarchical structure",
            interp_one_lower = "hierEGA finds a single lower-order dimension, so there is no hierarchy to estimate.",
            interp_dims = "hierEGA finds %s lower-order dimensions grouped into %s higher-order dimension(s).",
            interp_lower_same = "The lower-order dimensions are the same as in the EGA solution above.",
            interp_lower_diff = "The lower-order level has %s dimensions against %s in the EGA solution above, and places %d of %d items as EGA does. Items in a different dimension: %s. The lower level of Louvain tends to split broad dimensions, so this is expected.",
            interp_no_higher = "Each lower-order dimension stays on its own at the higher level, so there is no evidence of broader dimensions grouping them.",
            interp_general = "All lower-order dimensions group into one higher-order dimension, which is consistent with a general factor behind the specific dimensions.",
            interp_several = "The lower-order dimensions group into %s higher-order dimensions, which suggests broader domains above the specific dimensions.",
            interp_tefi_lower = "TEFI is lower at the lower-order level (%s) than at the higher-order level (%s), so by entropy fit the correlated lower-order dimensions describe the data better than the hierarchical structure.",
            interp_tefi_higher = "TEFI is lower at the higher-order level (%s against %s at the lower level), so by entropy fit the hierarchical structure describes the data better than correlated lower-order dimensions.",
            interp_few = "With only %s lower-order dimensions, the higher level rests on very few scores; read it as a hint and confirm it with a higher-order or bifactor CFA.",
            plot_lower = "Lower order",
            plot_higher = "Higher order",
            interp_cfa_hint = "To test the hierarchy as a factor model, tick Confirm with CFA: its section then compares the higher-order and bifactor models with the models without hierarchy.",
            interp_cfa_below = "The Confirmatory factor analysis section below compares the higher-order and bifactor models with the models without hierarchy.",
            interp_experimental = "EGAnetLab marks hierEGA as experimental. Report it as exploratory evidence together with the content of the dimensions."
        ),

        ri = list(
            intro = c(
                "Random-intercept EGA (riEGA, in EGAnetLab; see references) checks whether some dimensions come from how the items are worded rather than from their content. Scales that mix positively and negatively worded items often produce an extra dimension made of the negative items, caused by acquiescence (the tendency to agree regardless of content).",
                "riEGA first fits a random-intercept factor with the same loading for every item, which captures that wording effect, removes it, and then runs EGA on what is left."
            ),
            warning = "Before reading this section: riEGA only makes sense when the scale mixes positively and negatively worded items, and the negatively worded items are in their original direction, not recoded. With recoded items, or with a scale whose items are all worded in the same direction, the random intercept absorbs shared variance that is part of the content and the result is not a wording effect.",
            guide = c(
                "Random-intercept model: whether the random-intercept component could be estimated. If it does not converge, the result cannot be interpreted: it is evidence neither for nor against a wording effect.",
                "Dimensions with and without the wording control: if the number of dimensions drops after the control, some of the original dimensions probably reflected wording rather than content."
            ),
            bggm = "riEGA does not work with the BGGM network model; choose GLASSO or TMFG in Estimation",
            failed = "EGAnetLab could not estimate the random-intercept EGA: %s. The results above are not affected.",
            row_model = "Random-intercept model",
            converged = "Converged",
            not_converged = "Did not converge",
            row_dims_ega = "Dimensions without wording control (EGA)",
            row_dims_ri = "Dimensions after wording control (riEGA)",
            row_loadings = "Standardized random-intercept loadings",
            row_tefi = "TEFI (residual correlations)",
            interp_not_converged = "The random-intercept model did not converge, so this result cannot be interpreted: non-convergence is not evidence that there is no wording effect, nor that there is one. riEGA then runs EGA on the ordinary correlations, so the riEGA column repeats an ordinary EGA without any wording control. Check the direction of the items and the sample size before drawing conclusions about wording.",
            interp_converged = "A random-intercept component was estimated (standardized loadings %s). Reading it as acquiescence or a wording effect requires justifying the direction and the content of the items: the component captures whatever all items share to the same degree, and that can include content.",
            interp_same = "Tras quitarlo, EGA sigue encontrando %s dimensiones con los mismos ítems, así que la estructura dimensional no depende de este componente.",
            interp_fewer = "After removing it, EGA finds %s dimensions instead of %s. This is compatible with some original dimensions reflecting wording rather than content, but also with the random intercept absorbing content that the items share. Look at which items change dimension and at their wording before choosing an explanation.",
            interp_more = "After removing it, EGA finds %s dimensions instead of %s. The random-intercept component may have been masking some distinctions in content, or the control may be splitting dimensions; read the new dimensions with care and check them against the item content.",
            interp_moved = "Items that change dimension after the wording control: %s.",
            interp_no_neg = "No item is marked in Negatively worded items, so nothing in this analysis supports reading the random intercept as a wording effect. Mark the negatively worded items, or read riEGA only as a sensitivity check.",
            labels_note = "riEGA dimensions take the number of the EGA dimension with which they share the most items, so the numbers are labels, not a count.",
            neg_none = "No item is marked in Negatively worded items, so the items are used exactly as they are in the data. Mark the negative items there so that riEGA can use them in their original direction even if they are already reversed in the data.",
            neg_raw = "Negatively worded items: %s. They are as answered in the data, so riEGA uses them as they are (the other analyses use them reversed).",
            neg_recoded = "Negatively worded items: %s. They are already reversed in the data, so riEGA reverses them back to their original direction (observed minimum plus maximum, minus the score).",
            interp_neg_dim = "EGA dimension %s is made only of negatively worded items (%s): the classic sign of a wording factor rather than a content dimension.",
            interp_neg_moved = "%s of the %s items that change dimension with the wording control are negatively worded, which points to wording rather than content.",
            interp_validity = "This result is valid only if the negatively worded items are in their original, unrecoded direction and the scale mixes both directions. If all items are worded in the same direction, do not read it as a wording effect.",
            interp_tefi = "The riEGA TEFI is computed on the residual correlations, so it is not comparable with the TEFI of the EGA solution above."
        ),

        uva = list(
            intro = c(
                "Unique Variable Analysis (UVA) looks for redundant items: pairs that share so many of their connections in the network that they behave almost like the same item (Christensen, Garrido & Golino, 2023; see references).",
                "It uses the weighted topological overlap (wTO) of the network estimated above: the more two items are linked to the same other items with similar strength, the higher their wTO. Redundant items inflate a dimension and can create small artificial dimensions made only of near-duplicates."
            ),
            guide = c(
                "Pairs: every pair with wTO of .20 or more, from highest to lowest. Above .30 is large-to-very-large redundancy, .25 to .30 moderate-to-large, .20 to .25 small-to-moderate.",
                "Same dimension: redundant items usually fall in the same dimension; a redundant pair split across dimensions deserves a close look at its wording.",
                "Redundant sets: items linked by wTO at or above the cutoff. The suggestion follows EGAnetLab's automatic rule: with two items it keeps the one less redundant with the rest of the scale; with three or more it keeps the one most central to the set."
            ),
            mag_large = "Large to very large",
            mag_moderate = "Moderate to large",
            mag_small = "Small to moderate",
            yes = "Yes",
            no = "No",
            no_pairs = "No pair reaches wTO .20",
            failed = "EGAnetLab could not complete the redundancy analysis: %s. The EGA results above are not affected.",
            interp_none = "No pair of items reaches a wTO of %s, so there is no evidence of redundancy (local dependence) at the recommended cutoff. Each item contributes its own information to the network.",
            interp_borderline = "%d pair(s) fall between .20 and the cutoff (%s). They are not redundant by the recommended rule, but check their wording if they also stand out elsewhere (low stability or low loadings).",
            interp_sets = "%d redundant set(s) at wTO %s or more: %s. Items in a set share most of their connections, so together they add less information than their number suggests and can pull the dimensional structure toward themselves.",
            interp_suggest = "EGAnetLab's automatic rule would keep %s and remove %s. Treat this as a starting point: decide by content (which item best covers the construct, has the clearest wording, or is needed for a balanced scale), and consider combining items instead of removing them when both cover essential content.",
            interp_split = "Redundant pair(s) placed in different dimensions: %s. This often signals an item that bridges two dimensions; review its content before keeping it.",
            interp_unstable = "Item(s) that are both redundant and unstable in the bootstrap: %s. These are the strongest candidates for revision.",
            interp_unstable_borderline = "Borderline pair(s) that involve an item unstable in the bootstrap: %s. The overlap is below the redundancy cutoff, but it may explain why the item moves between dimensions across samples; review the wording of both items.",
            interp_next = "Next step: if you remove or combine items, run the analysis again on the revised item set and compare the number of dimensions and the stability with the original solution. Do not compare TEFI values between the original and the revised item sets: TEFI is only comparable between structures of the same items. Report the cutoff and the items you changed."
        ),

        bootega = list(
            intro = c(
                "The bootstrap checks whether the dimensions found above are a stable property of the items or an accident of this particular sample (Christensen & Golino, 2021; see references).",
                "It draws many new samples from your data, runs EGA with the same estimation options on each one and records how many dimensions appear and where each item ends up. A solid structure appears again and again; an unstable one changes from sample to sample.",
                "Read the results in this order: the distribution of the number of dimensions, the stability of each dimension, the stability of each item, and the stability interpretation."
            ),
            done = "Bootstrap complete: %d samples (%s), seed %d. Changing only the report language, the stability cutoff or the plot options reuses these results without running the bootstrap again.",
            failed = "EGAnetLab could not complete the bootstrap: %s. The EGA above was estimated, so the problem lies in some bootstrap samples: try the resampling bootstrap, or fewer items with very few categories.",
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
        ),
        groups = list(
            intro = "This section compares the network of the items between groups of people. With a grouping variable it compares independent groups (for example, women and men, or two countries). With a second measurement of the same items it compares the same people at two moments (for example, before and after an intervention).",
            small_dropped = "Group(s) with fewer than 10 cases were left out of the comparison: %s. Networks cannot be estimated reliably with so few people.",
            missing_group = "%d case(s) have no value in the grouping variable and were left out of the comparison between groups.",
            need_two = "The comparison between independent groups needs at least two groups with 10 or more cases each, so it was not run.",
            pairwise = "The grouping variable has %d groups, so every pair of groups is compared separately. With many pairs, some differences will appear by chance: focus on differences that repeat across pairs or that survive the correction for multiple tests.",
            paired_count = "The second measurement has %d variable(s), but the analysis uses %d items. Add one variable for each item, in the same order as the items, to compare the two measurements.",
            nothing = "To compare groups, add a grouping variable (independent groups) or the items of a second measurement of the same people (paired groups)."
        ),

        inv = list(
            intro = c(
                "Metric invariance checks whether each item is related to its dimension with the same strength in every group (Jamison, Christensen & Golino, 2024; see references).",
                "EGAnetLab estimates the network in each group with the same dimensional structure and compares the network loadings item by item. Then it shuffles people between groups many times to see how large the differences would be if group membership did not matter. An item whose loading differs more than expected by chance is not invariant: the item does not measure its dimension in the same way in the two groups."
            ),
            no_groups = "To test invariance, add a grouping variable with at least two groups of 10 or more cases. Invariance compares independent groups; it does not use the second measurement.",
            structure_configural = "Structure tested: the structure that is stable across groups (configural invariance). EGAnetLab first runs a bootstrap EGA on all cases, keeps only the items that stay in their dimension in enough samples and re-estimates the structure without the unstable items.",
            structure_ega = "Structure tested: the dimensions found by the EGA above, applied to every group.",
            iter_seed = "Permutations: %d, seed %d.",
            isolated = "Items without edges in the network, left out of the invariance test: %s.",
            failed = "EGAnetLab could not complete the invariance test: %s. The EGA results above are not affected. Check that every group has enough cases and that no item is constant within a group.",
            configural_failed = "Configural invariance was not reached: after removing the unstable items, fewer than two items keep a stability of %.2f or more, so there is no common structure to compare. The groups do not share the same dimensions; compare their networks with the Network Comparison Test or run the EGA within each group.",
            configural_ok = "Configural invariance: every item stays in its dimension in enough bootstrap samples, so all items were tested.",
            configural_partial = "Configural invariance: %d item(s) were unstable and were left out before the metric test: %s.",
            guide = c(
                "Loadings: the network loading of the item on its own dimension in each group.",
                "Difference: loading in the first group minus loading in the second group.",
                "p: proportion of permutations with a difference at least as large as the observed one. p (BH): the same p value corrected for the number of items with the Benjamini-Hochberg method.",
                "Direction: the group with the larger loading, shown only when p is .05 or less."
            ),
            interp_invariant = "No item shows a loading difference between groups beyond what is expected by chance (all p values above .05). The evidence supports metric invariance: the items relate to their dimensions with similar strength in the groups, so scores built from these dimensions can be compared between groups more safely.",
            interp_noninvariant = "Items whose loadings differ between groups (p of .05 or less), %d of %d: %s. These items relate to their dimension with different strength in each group, so a dimension score is not fully comparable: part of a group difference on the score could come from these items rather than from the construct.",
            interp_fdr_none = "None of these differences remains significant after the Benjamini-Hochberg correction for the number of items tested. Treat them as tentative: they may be chance findings, and they need replication in another sample.",
            interp_fdr_some = "Item(s) that remain different after the Benjamini-Hochberg correction: %s. These are the clearest cases of non-invariance.",
            interp_partial = "Because some items were removed in the configural step, the metric test only applies to the remaining items. Report which items were removed and why.",
            interp_next = "Next step: review the content of the non-invariant items (wording, cultural meaning, relevance in each group). If they cannot be fixed, compare groups with scores that exclude them, or report the comparison with and without them. Report the structure tested, the number of permutations, the seed and both p values."
        ),

        nct = list(
            intro = c(
                "The Network Comparison Test (NCT) compares two whole networks: whether their connections differ, and whether the total strength of their connections differs (van Borkulo et al., 2023; see references).",
                "It estimates the network of each group, records the differences, and then shuffles people between the groups many times (for the same people measured twice, it shuffles the two measurements within each person) to see how large the differences would be by chance."
            ),
            estimator_ordinal = "Each network is estimated with the graphical lasso (EBIC, gamma .50) on polychoric correlations, because the items have few categories and Same as EGA was chosen in Correlations (NCT). They are recomputed in every permutation, so the test is slow.",
            estimator_pearson = "Each network is estimated with the graphical lasso (EBIC, gamma .50) on Pearson correlations.",
            estimator_pearson_ordinal = "Each network is estimated with the graphical lasso (EBIC, gamma .50) on Pearson correlations, the default of the NCT. With ordinal items Pearson slightly underestimates the associations, but both networks are estimated the same way, so the comparison stays fair. Choose Same as EGA in Correlations (NCT) for polychoric correlations; they are recomputed in every permutation, so the test takes several times longer.",
            iter_seed = "Permutations: %d, seed %d.",
            model_note = "The network above was estimated with the %s model, but the NCT always uses the graphical lasso. The networks compared here may therefore differ slightly from the one above.",
            complete_cases = "The NCT needs complete data, so each comparison uses only the cases with every item answered.",
            nothing = "To run the NCT, add a grouping variable with at least two groups of 10 or more cases, or the items of a second measurement of the same people.",
            guide = c(
                "Network structure (M): the largest difference in a single edge between the two networks. A small p means at least one connection differs.",
                "Global strength (S): the difference in the sum of the absolute edge weights of each network. A small p means one network is, overall, more strongly connected.",
                "Edges: every connection whose weight differs between the networks (p of .05 or less after the chosen correction).",
                "Centrality: the difference in strength and expected influence of each item between the networks, with the chosen correction."
            ),
            failed = "EGAnetLab could not run the NCT for %s: %s. Check that both groups have enough complete cases and that no item is constant within a group.",
            row_M = "Network structure (M)",
            row_S = "Global strength (S)",
            no_edges_note = "No edge differs between the networks at p of .05 or less after the correction.",
            note_table = "M = largest difference in a single edge; S = difference in global strength (sum of absolute edge weights). p values come from the permutations.",
            interp_n = "%s: %s (n = %d) and %s (n = %d)%s.",
            paired_word = ", the same people measured twice",
            interp_M_sig = "The network structure differs: the largest difference in a single connection (M = %s) is larger than expected by chance (%s). At least one relation between items is not the same in the two networks. The edge test (Test every edge) looks for which ones; after its correction for many tests, a single edge may not reach significance even when M does, so read M as evidence that the networks differ somewhere.",
            interp_M_ns = "There is no evidence that the network structure differs: the largest difference in a single connection (M = %s) is within what is expected by chance (%s). This does not prove the networks are equal; with small groups the test has little power.",
            interp_S_sig = "Global strength differs: %s in %s and %s in %s (%s). In one network the items are, overall, more strongly connected, which often goes with a more homogeneous or more severe presentation of the construct.",
            interp_S_ns = "Global strength is similar: %s in %s and %s in %s (%s). The overall level of connection among the items does not differ beyond chance.",
            interp_edges_none = "No individual connection differs after the correction for multiple tests.",
            interp_edges_some = "%d connection(s) differ between the networks after the correction for multiple tests (see the edge table).",
            interp_cen_none = "No item differs in centrality between the networks after the correction for multiple tests.",
            interp_cen_some = "%d centrality value(s) differ between the networks after the correction for multiple tests (see the centrality table).",
            interp_next = "Next step: interpret differences in connections together with the invariance test, because a different network can change the meaning of a dimension score between groups. Report the estimator, the number of permutations, the seed, the correction and the size of each group."
        ),

        cen = list(
            intro = c(
                "Centrality describes the position of each item in the estimated network. Strength is the sum of the absolute weights of an item's connections; expected influence is the same sum keeping the sign, so negative connections subtract (Opsahl et al., 2010; Robinaugh et al., 2016; see references).",
                "In a network of items, a central item shares much unique variance with the rest of the set. That describes the item within this item set; it does not show that the item causes or defines the construct."
            ),
            guide = c(
                "Strength: how strongly the item is connected overall, on the same network as EGA.",
                "Expected influence: like strength, but negative connections count against. It differs from strength only when the item has negative connections.",
                "Closeness and betweenness (optional): based on the shortest paths between items. They are less stable and harder to interpret in psychological networks (Bringmann et al., 2019; see references)."
            ),
            guide_z = "Values are standardized across items (mean 0, SD 1). A value above 1 marks an item clearly more central than the average item; below -1, clearly less central.",
            guide_raw = "Values are raw: strength and expected influence are sums of partial correlations, closeness and betweenness keep their own scales.",
            empty = "The estimated network has no edges, so centrality is not defined.",
            failed = "EGAnetLab could not compute centrality: %s.",
            interp_top = "By strength, the most central item(s): %s. They share the most unique variance with the rest of the set. If they are also redundant (see Redundancy, UVA), their centrality may reflect overlapping content rather than importance.",
            interp_low = "The least central item(s): %s. Weakly connected items add little to the network; check their network loadings and their stability.",
            interp_ei_same = "There are no negative connections, so expected influence orders the items exactly as strength does.",
            interp_ei_diff = "%d item(s) have negative connections, so their expected influence is lower than their strength: %s. Check whether they are negatively worded or describe the opposite pole of the construct.",
            interp_dims = "Centrality is computed over the whole network, across dimensions. An item can be central because it connects dimensions, not only because it is central within its own.",
            interp_closbetw = "Closeness and betweenness are shown because they were requested. In psychological networks they are often unstable and have no clear meaning (Bringmann et al., 2019); give them less weight than strength.",
            interp_next = "Next step: tick Stability of edges and centrality (bootnet) to check whether the order of the items by centrality holds before interpreting differences between items.",
            interp_with_bn = "Read the order of the items together with the CS coefficient in Network stability: below .25, differences in centrality between items should not be interpreted."
        ),

        bn = list(
            intro = c(
                "This section checks how accurate the estimated network is, with the bootnet procedures (Epskamp et al., 2018; see references). It re-estimates the same network as EGA (same correlation, model and missing-value handling) in many bootstrap samples.",
                "Two procedures are used: resampling cases with replacement, which gives an interval for each edge weight, and dropping growing proportions of cases, which shows whether the order of the items by centrality holds with fewer people."
            ),
            done = "Done: %d samples resampling cases and %d samples dropping cases, seed %d. The results are kept while the estimation options do not change.",
            failed = "EGAnetLab could not run the network stability analysis: %s.",
            empty = "The estimated network has no edges, so its stability cannot be assessed.",
            guide = c(
                "CS coefficient: the largest proportion of cases that can be dropped while the centrality order still correlates .70 or more with the original in 95% of the samples. Below .25 the order should not be interpreted; .50 or more is preferred (Epskamp et al., 2018).",
                "Edge intervals: the range that covers 95% of the bootstrap weights of each edge. A wide interval means the weight is imprecise; an interval that includes 0 means the edge may be absent in other samples.",
                "Samples with the edge: the percentage of bootstrap samples in which the edge was estimated as different from zero."
            ),
            cs_good = "Stable (.50 or more)",
            cs_mid = "Interpret with care (.25 to .50)",
            cs_bad = "Not interpretable (below .25)",
            cs_note = "CS = largest proportion of cases that can be dropped keeping a correlation of .70 or more with the original order in 95% of the samples. The largest value tested is .75.",
            edges_note = "Only the edges of the estimated network are listed, strongest first. The intervals are percentile intervals from resampling cases. In regularized networks the weights are pulled toward zero, so the intervals describe precision and are not significance tests (Epskamp et al., 2018).",
            interp_cs_good = "The order of the items by %s is stable (CS = %s): it holds when up to %s of the cases are dropped, so differences between items can be interpreted.",
            interp_cs_mid = "The order of the items by %s is moderately stable (CS = %s): interpret only large differences between items, and with care.",
            interp_cs_bad = "The order of the items by %s is not stable (CS = %s): it changes when only a few cases are dropped, so differences between items should not be interpreted.",
            interp_edges = "%d of the %d edges of the network were estimated in at least 90%% of the samples; %d have an interval that includes zero, so they may be absent in other samples.",
            interp_width = "The mean width of the edge intervals is %s. Two edges whose intervals overlap widely cannot be said to differ in strength.",
            interp_next = "Next step: report the number of samples, the seed and the CS coefficient together with the centrality results. If stability is low, a larger sample is the main remedy; removing items to raise it changes the construct being measured."
        ),

        dyn = list(
            intro = c(
                "Dynamic Exploratory Graph Analysis (dynEGA) estimates the dimensional structure of intensive longitudinal data: the same items answered many times by each person, for example in daily diaries or ecological momentary assessment (Golino et al., 2022; see references).",
                "For each person, it first estimates how every item changes from one time point to the next (its derivatives, with generalized local linear approximation; Boker et al., 2010). It then applies EGA to those derivatives, so the dimensions group items that change together over time, not items that are simply high or low together.",
                "The structure can be estimated for the whole sample (population), for each group and for each person. Comparing them shows whether one structure describes everyone or whether people differ."
            ),
            embed_text = "Embedding dimension %d: each derivative is estimated from a window of %d consecutive time points. Larger windows smooth out measurement noise but need more time points per person and hide fast changes; 5 is the usual value. Lag tau = %d: with tau = 1 the window uses consecutive time points; larger values skip time points and smooth the series further. Delta = %s is the time between measurements; it only rescales the derivatives.",
            choose_id = "Select the items, and the variable that identifies each person, to run Dynamic EGA. The data must be in long format: one row per person and time point.",
            constant_item = "The following items do not vary in the data and cannot enter the analysis: %s. Remove them.",
            too_few_persons = "Fewer than two persons have enough time points (at least %d, the embedding dimension plus 2). Dynamic EGA needs many time points per person; lower the embedding dimension or check the Person ID variable.",
            group_varies = "The grouping variable changes within %d person(s); each person was assigned to the group of their first time point.",
            dropped = "%d person(s) have fewer than %d time points and were left out: %s.",
            failed = "EGAnetLab could not estimate Dynamic EGA: %s. This usually means too few time points per person for the number of items, or items that barely change over time. Try a smaller embedding dimension, fewer items, or the population level only.",
            done = "Estimated: population%s%s, derivative %s, embedding dimension %d, seed %d. The results are kept while the estimation options do not change.",
            done_groups = ", groups",
            done_individual = ", each person",
            deriv_0 = "level",
            deriv_1 = "rate of change",
            deriv_2 = "acceleration",
            interp_dims_one = "In the population, the items form a single dimension (derivative analysed: %s): they tend to change together over time.",
            interp_dims_many = "In the population, the items form %d dimensions (derivative analysed: %s): within each dimension the items change together over time, and partly independently of the other dimensions.",
            interp_isolated = "%d item(s) were left without a dimension in the population: %s. Their changes over time are not connected to those of the other items.",
            interp_deriv_1 = "Because the first derivative was analysed, this is a structure of change: it describes which items rise and fall together from moment to moment. It can differ from the structure of a cross-sectional EGA of the same items, which describes which people score high or low together.",
            interp_deriv_0 = "Because the level (derivative 0) was analysed, the structure reflects the smoothed values of the items within each person's window, closer to a structure of states than of change.",
            interp_deriv_2 = "Because the second derivative was analysed, the structure describes how the speed of change accelerates together; it is noisier and needs many time points per person.",
            interp_groups_detail = "By group, %s.",
            interp_pooled = "No group reproduces the population structure. The population's %s dimensions combine structures that differ between groups, so they describe neither group well. Report the structure of each group rather than the population result alone.",
            dims_word_1 = "1 dimension",
            dims_word_n = "%s dimensions",
            group_word = "group %s has %s",
            agree_group_identical = "Same item membership as their own group (ARI = 1)",
            agree_group_median = "Median agreement with their own group (ARI)",
            interp_ind_group_high = "Compared with their own group, %s of the persons show exactly their group's item membership (median ARI = %s). The differences between persons are explained by the group they belong to, not by idiosyncratic structures: describe each group's structure.",
            interp_ind_group_low = "Even within their own group, persons differ (median ARI with their group = %s): individual structures vary beyond group membership.",
            interp_ind_pop_group = "The agreement with the population (median ARI = %s) is lower because the population mixes the groups.",
            interp_groups_same = "Every group shows the same number of dimensions as the population.",
            interp_groups_diff = "Not every group shows the population's number of dimensions (see Structure of each group). The structure of change may differ between groups; check the group sizes before interpreting it.",
            interp_next = "Next step: tick Structure of each person to see whether the population structure describes individuals. Population structures of intensive longitudinal data often do not hold for every person.",
            ind_intro = "Each person's own network is estimated from their derivatives. Individual structures rely on fewer data points than the population structure, so they are noisier; read their distribution, not each one separately.",
            ind_few_points = "%d person(s) have fewer derivative estimates (time points minus the embedding dimension plus 1) than items (%d), so their individual networks rest on very little information and are unreliable. Individual structures need many more time points than items.",
            ind_failed = "The structure of %d person(s) could not be estimated (too few time points or items without change): %s.",
            agree_persons = "Persons with an estimated structure",
            agree_same_n = "Same number of dimensions as the population",
            agree_identical = "Same item membership as the population (ARI = 1)",
            agree_median = "Median agreement with the population (ARI)",
            agree_note = "ARI = adjusted Rand index between each person's item membership and the population's (Hubert & Arabie, 1985): 1 = identical, about 0 = no more agreement than chance. Items without a dimension count as their own group.",
            interp_ind_modal = "Number of dimensions across persons: %s. %s of the persons show the population's number of dimensions (%s).",
            interp_ind_high = "The median agreement with the population membership is high (ARI = %s) and most persons show the population's number of dimensions, so the population structure is a reasonable summary of individuals.",
            interp_ind_mid = "The median agreement with the population membership is moderate (ARI = %s): the population structure describes individuals only partly. Report the individual heterogeneity together with the population result.",
            interp_ind_low = "The median agreement with the population membership is low (ARI = %s): individual structures differ markedly from the population structure, which should not be read as the structure of each person (a non-ergodic process).",
            interp_ind_next = "Next step: report the population structure together with the distribution of individual structures, the number of time points per person and the derivative analysed. Check whether persons who differ from the population share characteristics (group, adherence, number of time points).",
            summary_persons = "Persons",
            summary_points = "Time points per person (min / median / max)",
            summary_rows = "Rows used",
            summary_glla = "Derivatives (GLLA)",
            summary_glla_value = "embedding %d, tau %d, delta %s; derivative analysed: %s",
            summary_ndim = "Dimensions (population)",
            plot_x = "Number of dimensions",
            plot_y = "Proportion of persons",
            plot_population = "Population's number (%s)",
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
            estimation_failed = "EGAnetLab no pudo estimar la red: %s. Suele deberse a que la matriz de correlaciones no es definida positiva (muy pocos casos para el número de ítems, o ítems casi duplicados). Revise el tamaño de muestra y la redundancia de los ítems, o pruebe otra correlación u otro modelo de red.",
            warnings_title = "Mensajes de EGAnetLab",
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
                "Correlación: con ítems de pocas categorías de respuesta, la opción automática de EGAnetLab usa correlaciones policóricas o tetracóricas."
            ),
            guide_loadings = c(
                "Las cargas de red resumen con qué fuerza se conecta cada ítem con cada dimensión, en una escala comparable a la de las cargas factoriales (Christensen & Golino, 2021; ver referencias).",
                "Guías propuestas de tamaño del efecto para la carga dominante: alrededor de 0.15 pequeña, 0.25 moderada, 0.35 grande."
            ),
            edges_none = "La red estimada no tiene aristas.",
            edges_note = "Los pesos son las correlaciones parciales de la red estimada (cada par de ítems, controlando por todos los demás), de la más fuerte a la más débil en valor absoluto. Un peso negativo indica que los dos ítems van en direcciones opuestas una vez que se mantiene constante el resto.",
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
            corr_auto = "Automática deja que EGAnetLab elija la correlación de cada par de ítems según su nivel de medida: policórica para ítems ordinales (pocas categorías), tetracórica para ítems dicotómicos y Pearson para ítems continuos. Es la opción recomendada para ítems tipo Likert y de acierto/error, porque la correlación de Pearson subestima la asociación entre variables categóricas.",
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
            uniMethod_louvain = "Antes de aceptar la solución multidimensional, EGA verifica si los ítems podrían ser unidimensionales. La verificación Louvain aplica el algoritmo Louvain a la matriz de correlaciones de orden cero: si encuentra una sola comunidad, la estructura se informa como una dimensión. Es el valor por defecto actual de EGAnetLab.",
            uniMethod_expand = "La verificación Expandir es la prueba de unidimensionalidad original de EGA: agrega variables simuladas que forman una dimensión aparte y vuelve a estimar la red. Si todos los ítems reales quedan en una sola comunidad, se consideran unidimensionales. Úsela para reproducir resultados de estudios que emplearon el procedimiento EGA original.",
            uniMethod_LE = "La verificación de autovalor principal aplica el algoritmo de comunidades leading eigenvalue a la matriz de correlaciones de orden cero: una sola comunidad significa una dimensión (Golino et al., 2020; ver referencias). Es una alternativa establecida a la verificación Louvain.",
            h_bootType = "Tipo de bootstrap",
            bootType_parametric = "El bootstrap paramétrico extrae cada muestra nueva de una distribución normal multivariada con la matriz de correlaciones de sus datos y el mismo número de casos. Reproduce en promedio exactamente la estructura de correlaciones estimada y es el valor por defecto de EGAnetLab (Christensen y Golino, 2021; ver referencias).",
            bootType_resampling = "El bootstrap por remuestreo extrae casos de sus datos con reemplazo. Conserva las distribuciones reales de respuesta (asimetría, número de categorías, valores atípicos) en lugar de suponer normalidad, así que prefiéralo cuando los ítems sean claramente no normales o cuando quiera que la estabilidad refleje las respuestas observadas.",
            uva_cut = "La redundancia se señala cuando dos ítems alcanzan un solapamiento topológico ponderado (wTO) de %s o más. El valor .25 es el punto de corte recomendado por Christensen, Garrido y Golino (2023; ver referencias) tras una amplia simulación; bájelo solo para explorar pares limítrofes, no para decidir qué ítems eliminar.",
            h_derivative = "Derivada analizada",
            derivative_0 = "El nivel (derivada 0) es el valor suavizado de cada ítem dentro de la ventana. Su estructura es la más cercana a la de las puntuaciones brutas y conserva las diferencias estables entre ocasiones; elíjalo para describir estados más que cambio.",
            derivative_1 = "La primera derivada es la velocidad de cambio de cada ítem de un momento al siguiente. Es el valor por defecto de dynEGA y la opción más estudiada (Golino et al., 2022; ver referencias): las dimensiones agrupan ítems que suben y bajan juntos.",
            derivative_2 = "La segunda derivada es la aceleración de cada ítem. Capta cómo los cambios se aceleran o frenan juntos, pero amplifica el error de medida y necesita muchos momentos por persona; úsela solo con series densas.",
            bn_iter_seed = "La estabilidad de la red (bootnet) usa %d muestras remuestreando casos y %d muestras eliminando casos, con semilla %d. Lo habitual es usar unas 1000 de cada tipo (Epskamp et al., 2018; ver referencias); menos dan intervalos y coeficientes CS menos precisos. La misma semilla con los mismos datos y opciones reproduce los mismos resultados.",
            iter_seed = "El análisis usa %d muestras bootstrap con semilla %d. Más muestras dan estimaciones de estabilidad más precisas; 500 es el mínimo habitual para informar. La misma semilla con los mismos datos y opciones reproduce siempre los mismos resultados; infórmela junto con sus hallazgos."
        ),

        scores = list(
            guide = c(
                "Las puntuaciones de red ponderan cada ítem por su carga de red en su propia dimensión (Christensen y Golino, 2021; ver referencias), así que los ítems más centrales de una dimensión pesan más. Son el equivalente en redes de las puntuaciones factoriales.",
                "Escala: EGAnetLab primero estandariza cada ítem (puntuación z: media 0 y DE 1 en esta muestra) y luego suma los ítems ponderados por sus cargas. Por eso las puntuaciones están centradas en 0: los valores negativos están por debajo del promedio de la muestra y los positivos por encima. No están en la escala de respuesta de los ítems, y su media es 0 por construcción.",
                "r con el promedio: correlación entre la puntuación de red y el promedio sin ponderar de los mismos ítems (el promedio mantiene en la misma escala dimensiones con distinto número de ítems). Valores cercanos a 1 indican que la ponderación cambia poco; valores menores indican que los ítems aportan de forma muy desigual a la dimensión.",
                "Guardar puntuaciones de red (en la caja Network scores) añade una columna por dimensión al conjunto de datos, para usar las puntuaciones en otros análisis. Quien tenga una respuesta perdida en algún ítem de una dimensión queda sin puntuación en ella.",
                "Guardar promedios de los ítems añade una columna por dimensión con el promedio de los ítems que cada persona respondió, en la escala original de respuesta (por ejemplo, de 1 a 5). Úselos cuando necesite puntuaciones fáciles de leer en las unidades del cuestionario."
            ),
            failed = "EGAnetLab no pudo calcular las puntuaciones de red: %s.",
            saved_title = "Puntuación de red %s",
            saved_desc = "Puntuación de red de la dimensión %s (EGAnetLab)",
            mean_title = "Promedio de ítems %s",
            mean_desc = "Promedio de los ítems respondidos de la dimensión %s (EGAnetLab)"
        ),

        cfa = list(
            intro = c(
                "El análisis factorial confirmatorio (AFC/CFA) pone a prueba la estructura hallada por EGA como un modelo factorial: cada dimensión es un factor y cada ítem carga solo en su propio factor (lavaan; Rosseel, 2012; ver referencias).",
                "Ajustar el CFA con los mismos datos que produjeron la estructura da un ajuste optimista. Dividir la muestra al azar da una prueba honesta: EGA encuentra la estructura en la SubMuestra A (exploración) y el CFA la prueba en la SubMuestra B (confirmación). La tabla muestra la muestra total y ambas submuestras lado a lado."
            ),
            estimator_auto_ordinal = "Estimador: WLSMV con los ítems tratados como ordinales (algunos ítems tienen menos de 6 categorías), como hace CFA() de EGAnetLab.",
            estimator_auto_cont = "Estimador: MLR (máxima verosimilitud robusta) con manejo de información completa de los valores perdidos, como hace CFA() de EGAnetLab con ítems de 6 o más categorías.",
            estimator_fixed = "Estimador: %s, según lo elegido en las opciones.",
            estimator_rule = "Por qué la regla ordinal difiere de la de EGA: las correlaciones automáticas de EGA tratan como ordinales (policóricas) los ítems con 7 categorías o menos, mientras que el CFA usa WLSMV solo por debajo de 6 categorías, como hace CFA() de EGAnetLab. Con 6 o 7 categorías la red usa entonces correlaciones policóricas y el CFA usa máxima verosimilitud robusta, que funciona bien con esa cantidad de categorías (Rhemtulla, Brosseau-Liard y Savalei, 2012; ver referencias). Para usar el mismo tratamiento en ambos, elija el estimador del CFA en las opciones.",
            no_split_note = "El CFA usa la misma muestra que EGA, así que su ajuste es optimista. Marque Split the sample at random para una prueba en una submuestra independiente.",
            row_n = "Casos",
            row_dims = "Dimensiones halladas por EGA",
            row_tefi = "TEFI",
            row_structure = "Estructura probada por el CFA",
            row_structure_total = "EGA en la muestra total",
            row_structure_A = "EGA en la SubMuestra A",
            row_chisq = "χ² (gl), p",
            row_cfi = "CFI",
            row_tli = "TLI",
            row_rmsea = "RMSEA [IC 90%]",
            row_srmr = "SRMR",
            row_chisq_df = "χ²/gl",
            row_converged = "Convergió",
            row_admissible = "Solución admisible",
            yes = "Sí",
            no = "No",
            changed = "Cambia",
            new_dim = "nueva",
            dropped_factor = "Las dimensiones con un solo ítem no pueden formar un factor y quedaron fuera del CFA: %s.",
            failed = "lavaan no pudo ajustar el CFA%s: %s.",
            fit_guide = "Guías convencionales (Hu y Bentler, 1999; ver referencias): CFI y TLI de .95 o más, RMSEA de .06 o menos y SRMR de .08 o menos sugieren buen ajuste; CFI/TLI de .90 y RMSEA de .08 suelen tomarse como aceptables. Con WLSMV estos puntos de corte son solo aproximados.",
            fit_guide_more = "Otros índices (Schermelleh-Engel, Moosbrugger y Müller, 2003; ver referencias): χ²/gl de 2 o menos es bueno y de 3 o menos aceptable; GFI y NFI de .95 o más son buenos y de .90 aceptables; AGFI de .90 o más es bueno y de .85 aceptable; IFI se lee como el CFI. GFI y AGFI dependen del tamaño de la muestra y se informan sobre todo por tradición; CFI, TLI, RMSEA y SRMR son los más recomendados. AIC y BIC solo comparan modelos ajustados a los mismos datos (más bajo es mejor) y no están disponibles con WLSMV.",
            interp_fit = "En %s, el CFA de la estructura de EGA da CFI = %s, TLI = %s, RMSEA = %s y SRMR = %s, lo que sugiere un ajuste %s.",
            fit_good = "bueno",
            fit_acceptable = "aceptable",
            fit_poor = "pobre",
            sample_total = "la muestra total",
            sample_B = "la SubMuestra B (confirmación)",
            interp_dims_same = "EGA encuentra %s dimensiones en la muestra total, %s en la SubMuestra A y %s en la SubMuestra B: el número de dimensiones se replica entre submuestras aleatorias.",
            interp_dims_diff = "EGA encuentra %s dimensiones en la muestra total, %s en la SubMuestra A y %s en la SubMuestra B: el número de dimensiones no se replica del todo entre submuestras aleatorias, así que interprete la estructura con cautela.",
            interp_agree = "El %s de los ítems queda en la misma dimensión en las SubMuestras A y B.",
            interp_changes = "Ítems que cambian de dimensión entre las SubMuestras A y B: %s. Compárelos con la estabilidad bootstrap de los ítems y con los resultados de redundancia.",
            interp_seed = "División: %d casos en la SubMuestra A y %d en la SubMuestra B (semilla %d). Informe la semilla para poder reproducir la división; otra semilla da otra división.",
            interp_next = "Siguiente paso: informe el ajuste de confirmación (SubMuestra B) como evidencia principal de la estructura, y el de la muestra total como referencia. Si el ajuste es pobre, revise los ítems con cargas bajas o que cambian de dimensión."
        ),

        compare = list(
            intro = c(
                "Esta sección compara la estructura hallada por EGA con estructuras alternativas para los mismos ítems, mediante el Índice de Ajuste de Entropía Total (TEFI; Golino et al., 2021; ver referencias). Todas las estructuras se evalúan sobre la misma matriz de correlaciones del EGA de arriba, así que sus valores de TEFI se pueden comparar directamente.",
                "Un TEFI más bajo indica mejor ajuste: los ítems de cada dimensión comparten más información entre sí que con el resto de los ítems."
            ),
            guide = c(
                "Otros algoritmos de comunidades: EGA se ejecuta de nuevo con la misma red y cada uno de los otros algoritmos (Walktrap, Louvain, Leiden). Louvain y Leiden parten de valores aleatorios, así que usan la semilla fija 2026 y siempre dan el mismo resultado con los mismos datos.",
                "Estructura teórica: se arma como en el Análisis Factorial Confirmatorio de jamovi. Arrastre los ítems de cada dimensión a un factor, use Add New Factor para el siguiente y haga clic en el nombre de un factor para cambiarlo. Los ítems que no estén en ningún factor quedan fuera de la estructura teórica.",
                "Ítems ubicados como en EGA: cuántos ítems quedan en la misma dimensión que en la solución de EGA, tras emparejar cada dimensión con la dimensión de EGA con la que comparte más ítems.",
                "Diferencia con el más bajo: cuánto se aleja cada estructura del TEFI más bajo entre las estructuras que usan los mismos ítems. No hay un punto de corte establecido para una diferencia importante.",
                "Una dimensión: el TEFI vale siempre 0 con una sola dimensión, así que no sirve para comparar una estructura unidimensional con otras multidimensionales. EGA evalúa la unidimensionalidad con su propia verificación (ver las elecciones de arriba)."
            ),
            cfa_guide = "Ajuste CFA de cada estructura: análisis factorial confirmatorio de cada estructura con lavaan (estimador automático: WLSMV con ítems de menos de 6 categorías, si no MLR), con CFI, RMSEA y SRMR. Se estima con los mismos datos que produjeron la solución de EGA, lo que favorece a esa solución; para una prueba independiente use la división aleatoria de la caja Confirmatory factor analysis.",
            ega_label = "Solución de EGA (%s)",
            alt_label = "EGA con %s",
            theory_label = "Teórica",
            agree = "%d de %d (%s%%)",
            alt_failed = "EGAnetLab no pudo estimar esta estructura: %s.",
            single = "Una dimensión: el TEFI vale siempre 0, así que no se compara.",
            unassigned = "Sin dimensión: %s. Quedan fuera del TEFI, así que este valor no se compara con los demás.",
            cfa_failed = "No se pudo estimar el CFA: %s.",
            theory_unknown = "La estructura teórica incluye variables que no están entre los Items del análisis: %s. Agréguelas a Items o quítelas de los factores.",
            theory_duplicated = "Estos ítems están en más de un factor de la estructura teórica: %s. Cada ítem puede pertenecer a un solo factor.",
            theory_dup_dims = "Estos nombres de factor se usan más de una vez: %s.",
            theory_none = "La estructura teórica no tiene ningún ítem del análisis en sus factores.",
            interp_best_ega = "La solución de EGA tiene el TEFI más bajo (%s) entre las estructuras comparadas, así que según el ajuste de entropía es la que mejor separa los ítems en dimensiones.",
            interp_best_other = "%s tiene el TEFI más bajo (%s), %s por debajo de la solución de EGA (%s). Según el ajuste de entropía separa los ítems en dimensiones mejor que la solución de EGA.",
            interp_same = "%s agrupa los ítems exactamente como la solución de EGA, así que tiene el mismo TEFI. Que algoritmos distintos lleguen a las mismas dimensiones respalda la solución.",
            interp_differs = "%s ubica %d de %d ítems como EGA (TEFI %s; %s por encima del más bajo). Ítems que cambian de dimensión: %s.",
            interp_theory_vs_ega = "La estructura teórica ubica %d de %d ítems como EGA. Los ítems que EGA ubica en otra dimensión (%s) son los que hay que examinar: lea su contenido y revise si también son inestables en el bootstrap o redundantes en UVA.",
            interp_theory_match = "La estructura teórica y la solución de EGA agrupan los ítems de la misma manera, lo que respalda la estructura prevista.",
            interp_no_theory = "Para comparar también la estructura teórica, arrastre sus ítems a los factores de Theoretical structure, en la caja Compare structures (TEFI).",
            interp_single = "%s tiene una sola dimensión. El TEFI vale siempre 0 con una dimensión, así que no se compara con las estructuras multidimensionales; para esa pregunta use la verificación de unidimensionalidad de EGA.",
            interp_cfa = "Los índices del CFA salen de los mismos datos que produjeron la solución de EGA, así que la favorecen. Úselos como una segunda mirada y confirme con la división aleatoria de la caja Confirmatory factor analysis.",
            interp_no_cutoff = "No hay un punto de corte establecido para una diferencia de TEFI importante. Lea las diferencias junto con la estabilidad bootstrap, el ajuste CFA y el contenido de los ítems que cambian, e informe el TEFI de cada estructura comparada."
        ),

        cfa_hier = list(
            unavailable = "No se pudo estimar el EGA jerárquico, así que no se ajustaron los modelos jerárquicos.",
            m_one = "Un factor",
            m_ega = "Factores correlacionados (EGA)",
            m_ega_same = "Factores correlacionados (EGA = orden inferior de hierEGA)",
            m_lower = "Factores correlacionados (orden inferior de hierEGA)",
            m_higher = "Orden superior (%s factor(es) de orden superior)",
            m_bifactor = "Bifactor (general + factores específicos de orden inferior)",
            failed = "lavaan no pudo ajustar este modelo: %s.",
            not_converged = "lavaan no alcanzó la convergencia; no interprete esta fila.",
            warning_note = "lavaan advirtió sobre este modelo: %s. La solución parece admisible, pero revise sus estimaciones antes de preferirlo.",
            interp_excluded = "%s queda fuera de la elección del mejor ajuste: %s. Sus índices de ajuste se muestran, pero no pueden leerse hasta resolver ese problema.",
            inadmissible_note = "lavaan señaló un problema en esta solución: %s. No interprete ni prefiera este modelo hasta revisar sus estimaciones.",
            intro = "Todos los modelos se ajustan en la muestra total y con los mismos ítems, así que las filas se pueden comparar directamente. Los modelos de factores correlacionados no tienen jerarquía; el modelo de orden superior coloca las dimensiones de orden superior de hierEGA por encima de los factores de orden inferior, y el modelo bifactor agrega un factor general en todos los ítems junto a los factores de orden inferior (todos sin correlación; Reise, 2012; ver referencias).",
            interp_none = "Ningún modelo alcanzó una solución convergente y admisible, así que no hay comparación que leer.",
            interp_best_cfi = "El CFI más alto es el de %s (%s).",
            interp_best_bic = "El BIC más bajo, que equilibra el ajuste y el número de parámetros, es el de %s (%s).",
            interp_bic_gap_strong = "Está %s puntos por debajo del siguiente modelo: evidencia fuerte a su favor.",
            interp_bic_gap_weak = "Está solo %s puntos por debajo del siguiente modelo (menos de 10), así que el BIC no los separa con claridad; elija según la teoría y las cargas.",
            interp_no_ic = "AIC y BIC no están disponibles con este estimador (WLSMV para ítems ordinales), así que la comparación se apoya en CFI, TLI, RMSEA y SRMR.",
            interp_equivalent = "El modelo de orden superior ajusta exactamente igual que los factores de orden inferior correlacionados: con dos o tres factores de orden inferior bajo un factor de orden superior, el nivel superior solo vuelve a expresar sus correlaciones. Los datos no pueden distinguirlos; la elección depende de la teoría y del uso que tendrán las puntuaciones.",
            interp_higher_close = "El modelo de orden superior alcanza un CFI de %s frente a %s de los factores de orden inferior correlacionados. La pérdida de ajuste es limitada (.01 o menos) bajo este criterio descriptivo, y el modelo es más restrictivo; la interpretación jerárquica requiere evaluación adicional (teoría, cargas de los factores de orden superior y replicación en otra muestra).",
            interp_higher_worse = "El modelo de orden superior alcanza un CFI de %s frente a %s de los factores de orden inferior correlacionados. La pérdida es mayor que .01: bajo este criterio descriptivo los factores de orden superior no reproducen bien las correlaciones entre los factores de orden inferior, así que es preferible el modelo sin jerarquía.",
            interp_no_higher = "El EGA jerárquico no encontró un nivel de orden superior, así que no se ajusta el modelo de orden superior.",
            interp_bifactor = "El modelo bifactor suele ajustar mejor porque es muy flexible y también absorbe ruido y estilos de respuesta. Prefiéralo solo cuando el factor general concentre la mayor parte de la varianza común y los factores específicos conserven cargas claras; si no, su mejor ajuste no es evidencia de un factor general.",
            interp_optimistic = "Estos modelos se ajustan con los mismos datos que produjeron las soluciones de EGA y hierEGA, así que su ajuste es optimista. Infórmelos como comparación y confirme el modelo elegido en una muestra nueva."
        ),

        bifactor = list(
            intro = "Esta tabla abre el modelo bifactor de la comparación de arriba: para cada ítem, su carga en el factor general (todos los ítems) y en su factor específico (la dimensión de orden inferior de hierEGA), y su varianza residual. Muestra si los factores específicos conservan varianza propia o colapsan en el factor general, que es la causa habitual de las soluciones bifactor inadmisibles (Rodriguez, Reise y Haviland, 2016; ver referencias).",
            guide = c(
                "General y Específica: cargas estandarizadas. En un modelo bifactor sólido, los ítems cargan claramente en el factor general y conservan cargas visibles (.20 o más) en su factor específico.",
                "Varianza residual: la parte del ítem que no explica ninguno de los dos factores. Un valor negativo es un caso Heywood: la solución no es admisible.",
                "Revisar: caso Heywood, carga mayor que 1, carga específica menor que .20 (el ítem casi no aporta a su factor específico) o carga general menor que .20."
            ),
            flag_heywood = "Caso Heywood",
            flag_above = "Carga mayor que 1",
            flag_weak = "Carga específica débil",
            interp_ecv_high = "El factor general explica el %s de la varianza común (varianza común explicada, ECV = %s). Desde .70, los ítems están cerca de la unidimensionalidad: los factores específicos aportan poco y una sola puntuación suele ser defendible.",
            interp_ecv_low = "El factor general explica el %s de la varianza común (varianza común explicada, ECV = %s). Por debajo de .70, los factores específicos conservan una parte importante de la varianza común, así que la escala no es esencialmente unidimensional.",
            interp_collapse = "El factor específico %s colapsa en el factor general: sus cargas son en su mayoría menores que .20 (carga absoluta media %s). Probablemente el modelo tiene un factor específico de más; considere un modelo bifactor sin él (bifactor S-1) o el modelo de factores correlacionados.",
            interp_few_items = "Factores específicos con tres ítems o menos (número de ítems entre paréntesis): %s. Un factor específico con tan pocos ítems está débilmente identificado junto a un factor general y es una causa frecuente de casos Heywood.",
            interp_weak_general = "Ítems con una carga general menor que .20: %s. No comparten el factor general; revise su redacción (por ejemplo, ítems en negativo sin invertir) o si pertenecen a la escala.",
            flag_weak_general = "Carga general débil",
            interp_heywood = "Ítems con varianza residual negativa (caso Heywood): %s. Sus cargas quedan forzadas más allá de lo que permiten los datos, por lo general porque su factor específico está casi vacío o tiene muy pocos ítems. No interprete el modelo bifactor mientras esto ocurra.",
            interp_above = "Ítems con una carga estandarizada mayor que 1: %s. Esto no es posible en una solución admisible; léalo junto con los casos Heywood.",
            interp_admissible = "No aparece ningún caso Heywood ni cargas mayores que 1, así que la solución bifactor es admisible; júzguela por la ECV y por si cada factor específico conserva sus propias cargas.",
            interp_next = "Siguiente paso: si un factor específico colapsa o tiene muy pocos ítems, ajuste el modelo sin él o conserve el modelo de factores correlacionados. No agregue parámetros sugeridos por índices de modificación para rescatar un bifactor inadmisible: eso tiende a ajustar el ruido de esta muestra."
        ),

        hier = list(
            intro = c(
                "El EGA jerárquico (hierEGA; Jiménez et al., 2023; ver referencias) pregunta si las dimensiones se agrupan a su vez bajo dimensiones más amplias, de orden superior, como un factor general.",
                "Trabaja en dos pasos: encuentra las dimensiones de orden inferior con el nivel inferior del algoritmo Louvain, calcula la puntuación de red de cada persona en ellas y luego aplica EGA a esas puntuaciones para hallar las dimensiones de orden superior. Louvain parte de valores aleatorios, así que usa la semilla fija 2026."
            ),
            guide = c(
                "Orden inferior y superior: cuántas dimensiones hay en cada nivel. Las dimensiones de orden superior agrupan dimensiones de orden inferior, no ítems.",
                "Pertenencia de los ítems por nivel: la columna EGA es la solución de arriba; la de orden inferior usa los mismos números donde las dimensiones coinciden; la de orden superior muestra la dimensión amplia en la que queda cada ítem.",
                "TEFI por nivel: EGAnetLab compara el ajuste de entropía del nivel inferior con el del nivel superior. Un TEFI más bajo en el nivel inferior favorece dimensiones correlacionadas sin jerarquía; un TEFI más bajo en el nivel superior favorece la estructura jerárquica (EGAnetLab la llama bifactor)."
            ),
            cosine_note = "hierEGA no acepta la similitud coseno, así que aquí usa la correlación automática.",
            failed = "EGAnetLab no pudo estimar el EGA jerárquico: %s. Los resultados de arriba no se ven afectados.",
            row_lower = "Dimensiones de orden inferior",
            row_higher = "Dimensiones de orden superior",
            row_tefi_lower = "TEFI, orden inferior",
            row_tefi_higher = "TEFI, orden superior",
            row_tefi_general = "TEFI generalizado",
            row_better = "Mejor ajuste según TEFI",
            better_lower = "Dimensiones de orden inferior correlacionadas",
            better_higher = "Estructura jerárquica",
            interp_one_lower = "hierEGA encuentra una sola dimensión de orden inferior, así que no hay jerarquía que estimar.",
            interp_dims = "hierEGA encuentra %s dimensiones de orden inferior agrupadas en %s dimensión(es) de orden superior.",
            interp_lower_same = "Las dimensiones de orden inferior son las mismas de la solución de EGA de arriba.",
            interp_lower_diff = "El nivel inferior tiene %s dimensiones frente a %s en la solución de EGA de arriba, y ubica %d de %d ítems como EGA. Ítems en otra dimensión: %s. El nivel inferior de Louvain tiende a dividir las dimensiones amplias, así que es esperable.",
            interp_no_higher = "Cada dimensión de orden inferior queda sola en el nivel superior, así que no hay evidencia de dimensiones más amplias que las agrupen.",
            interp_general = "Todas las dimensiones de orden inferior se agrupan en una sola dimensión de orden superior, lo que es coherente con un factor general detrás de las dimensiones específicas.",
            interp_several = "Las dimensiones de orden inferior se agrupan en %s dimensiones de orden superior, lo que sugiere dominios más amplios por encima de las dimensiones específicas.",
            interp_tefi_lower = "El TEFI es más bajo en el nivel inferior (%s) que en el superior (%s), así que según el ajuste de entropía las dimensiones de orden inferior correlacionadas describen mejor los datos que la estructura jerárquica.",
            interp_tefi_higher = "El TEFI es más bajo en el nivel superior (%s frente a %s en el inferior), así que según el ajuste de entropía la estructura jerárquica describe mejor los datos que las dimensiones de orden inferior correlacionadas.",
            interp_few = "Con solo %s dimensiones de orden inferior, el nivel superior se apoya en muy pocas puntuaciones; tómelo como un indicio y confírmelo con un CFA de orden superior o bifactor.",
            plot_lower = "Orden inferior",
            plot_higher = "Orden superior",
            interp_cfa_hint = "Para probar la jerarquía como modelo factorial, marque Confirmar con CFA: su sección compara entonces los modelos de orden superior y bifactor con los modelos sin jerarquía.",
            interp_cfa_below = "La sección Análisis factorial confirmatorio, más abajo, compara los modelos de orden superior y bifactor con los modelos sin jerarquía.",
            interp_experimental = "EGAnetLab marca hierEGA como experimental. Infórmelo como evidencia exploratoria junto con el contenido de las dimensiones."
        ),

        ri = list(
            intro = c(
                "El EGA con intercepto aleatorio (riEGA, de EGAnetLab; ver referencias) revisa si algunas dimensiones provienen de cómo están redactados los ítems y no de su contenido. Las escalas que mezclan ítems redactados en positivo y en negativo suelen producir una dimensión extra formada por los ítems negativos, causada por la aquiescencia (la tendencia a estar de acuerdo sin importar el contenido).",
                "riEGA primero ajusta un factor de intercepto aleatorio con la misma carga para todos los ítems, que capta ese efecto de redacción, lo quita y luego aplica EGA a lo que queda."
            ),
            warning = "Antes de leer esta sección: riEGA solo tiene sentido si la escala mezcla ítems redactados en positivo y en negativo, y los ítems negativos están en su dirección original, sin recodificar. Con ítems recodificados, o con una escala cuyos ítems están todos redactados en la misma dirección, el intercepto aleatorio absorbe varianza compartida que es parte del contenido y el resultado no indica un efecto de redacción.",
            guide = c(
                "Modelo de intercepto aleatorio: si se pudo estimar el componente de intercepto aleatorio. Si no converge, el resultado no es interpretable: no es evidencia ni a favor ni en contra de un efecto de redacción.",
                "Dimensiones con y sin control de la redacción: si el número de dimensiones baja tras el control, algunas de las dimensiones originales probablemente reflejaban la redacción y no el contenido."
            ),
            bggm = "riEGA no funciona con el modelo de red BGGM; elija GLASSO o TMFG en Estimation",
            failed = "EGAnetLab no pudo estimar el EGA con intercepto aleatorio: %s. Los resultados de arriba no se ven afectados.",
            row_model = "Modelo de intercepto aleatorio",
            converged = "Convergió",
            not_converged = "No convergió",
            row_dims_ega = "Dimensiones sin control de la redacción (EGA)",
            row_dims_ri = "Dimensiones tras controlar la redacción (riEGA)",
            row_loadings = "Cargas estandarizadas del intercepto aleatorio",
            row_tefi = "TEFI (correlaciones residuales)",
            interp_not_converged = "El modelo de intercepto aleatorio no convergió, así que este resultado no es interpretable: la falta de convergencia no es evidencia de que no haya un efecto de redacción, ni de que lo haya. riEGA ejecuta entonces EGA sobre las correlaciones habituales, así que la columna riEGA repite un EGA ordinario sin control de la redacción. Revise la dirección de los ítems y el tamaño de la muestra antes de sacar conclusiones sobre la redacción.",
            interp_converged = "Se estimó un componente de intercepto aleatorio (cargas estandarizadas %s). Su interpretación como aquiescencia o efecto de redacción requiere justificar la dirección y el contenido de los ítems: el componente recoge lo que todos los ítems comparten en el mismo grado, y eso puede incluir contenido.",
            interp_same = "Tras quitarlo, EGA sigue encontrando %s dimensiones con los mismos ítems, así que las dimensiones no son un artefacto de la redacción.",
            interp_fewer = "Tras quitarlo, EGA encuentra %s dimensiones en lugar de %s. Esto es compatible con que algunas dimensiones originales reflejen la redacción y no el contenido, pero también con que el intercepto aleatorio absorba contenido que los ítems comparten. Revise qué ítems cambian de dimensión y su redacción antes de elegir una explicación.",
            interp_more = "Tras quitarlo, EGA encuentra %s dimensiones en lugar de %s. Puede que el componente de intercepto aleatorio ocultara algunas distinciones de contenido, o que el control esté dividiendo dimensiones; lea las nuevas dimensiones con cuidado y contrástelas con el contenido de los ítems.",
            interp_moved = "Ítems que cambian de dimensión tras controlar la redacción: %s.",
            interp_no_neg = "Ningún ítem está marcado en Negatively worded items, así que nada en este análisis respalda leer el intercepto aleatorio como un efecto de redacción. Marque los ítems redactados en negativo, o lea riEGA solo como una prueba de sensibilidad.",
            labels_note = "Las dimensiones de riEGA llevan el número de la dimensión de EGA con la que comparten más ítems, así que los números son etiquetas, no un conteo.",
            neg_none = "No hay ítems marcados en Ítems redactados en negativo, así que los ítems se usan tal como están en los datos. Márquelos allí para que riEGA los use en su dirección original aunque ya estén invertidos en los datos.",
            neg_raw = "Ítems redactados en negativo: %s. Están tal como se respondieron en los datos, así que riEGA los usa así (los demás análisis los usan invertidos).",
            neg_recoded = "Ítems redactados en negativo: %s. Ya están invertidos en los datos, así que riEGA los devuelve a su dirección original (mínimo más máximo observados, menos el puntaje).",
            interp_neg_dim = "La dimensión %s de EGA está formada solo por ítems redactados en negativo (%s): la señal clásica de un factor de redacción y no de una dimensión de contenido.",
            interp_neg_moved = "%s de los %s ítems que cambian de dimensión con el control de la redacción están redactados en negativo, lo que apunta a la redacción y no al contenido.",
            interp_validity = "Este resultado solo es válido si los ítems redactados en negativo están en su dirección original, sin recodificar, y la escala mezcla ambas direcciones. Si todos los ítems están redactados en la misma dirección, no lo interprete como un efecto de redacción.",
            interp_tefi = "El TEFI de riEGA se calcula sobre las correlaciones residuales, así que no es comparable con el TEFI de la solución de EGA de arriba."
        ),

        uva = list(
            intro = c(
                "El Análisis de Variables Únicas (UVA) busca ítems redundantes: pares que comparten tantas de sus conexiones en la red que se comportan casi como el mismo ítem (Christensen, Garrido y Golino, 2023; ver referencias).",
                "Usa el solapamiento topológico ponderado (wTO) de la red estimada arriba: cuanto más se conectan dos ítems con los mismos otros ítems y con fuerza similar, mayor es su wTO. Los ítems redundantes inflan una dimensión y pueden crear dimensiones pequeñas y artificiales formadas solo por casi duplicados."
            ),
            guide = c(
                "Pares: todo par con wTO de .20 o más, de mayor a menor. Por encima de .30 es redundancia grande a muy grande, de .25 a .30 moderada a grande, de .20 a .25 pequeña a moderada.",
                "Misma dimensión: los ítems redundantes suelen caer en la misma dimensión; un par redundante repartido entre dimensiones merece una revisión cuidadosa de su redacción.",
                "Conjuntos redundantes: ítems unidos por un wTO igual o mayor que el punto de corte. La sugerencia sigue la regla automática de EGAnetLab: con dos ítems conserva el menos redundante con el resto de la escala; con tres o más conserva el más central del conjunto."
            ),
            mag_large = "Grande a muy grande",
            mag_moderate = "Moderada a grande",
            mag_small = "Pequeña a moderada",
            yes = "Sí",
            no = "No",
            no_pairs = "Ningún par alcanza wTO .20",
            failed = "EGAnetLab no pudo completar el análisis de redundancia: %s. Los resultados de EGA de arriba no se ven afectados.",
            interp_none = "Ningún par de ítems alcanza un wTO de %s, así que no hay evidencia de redundancia (dependencia local) con el punto de corte recomendado. Cada ítem aporta su propia información a la red.",
            interp_borderline = "%d par(es) quedan entre .20 y el punto de corte (%s). No son redundantes según la regla recomendada, pero revise su redacción si además destacan en otros resultados (baja estabilidad o cargas bajas).",
            interp_sets = "%d conjunto(s) redundante(s) con wTO de %s o más: %s. Los ítems de un conjunto comparten la mayoría de sus conexiones, así que juntos aportan menos información de la que sugiere su número y pueden atraer la estructura dimensional hacia sí.",
            interp_suggest = "La regla automática de EGAnetLab conservaría %s y eliminaría %s. Tómelo como punto de partida: decida por el contenido (qué ítem cubre mejor el constructo, tiene la redacción más clara o es necesario para una escala equilibrada), y considere combinar ítems en lugar de eliminarlos cuando ambos cubren contenido esencial.",
            interp_split = "Par(es) redundante(s) ubicados en dimensiones distintas: %s. Suele indicar un ítem que hace de puente entre dos dimensiones; revise su contenido antes de conservarlo.",
            interp_unstable = "Ítem(s) que son a la vez redundantes e inestables en el bootstrap: %s. Son los candidatos más claros a revisión.",
            interp_unstable_borderline = "Par(es) limítrofe(s) que incluyen un ítem inestable en el bootstrap: %s. El solapamiento está por debajo del punto de corte de redundancia, pero puede explicar por qué el ítem cambia de dimensión entre muestras; revise la redacción de ambos ítems.",
            interp_next = "Siguiente paso: si elimina o combina ítems, vuelva a ejecutar el análisis con el conjunto revisado y compare el número de dimensiones y la estabilidad con la solución original. No compare valores de TEFI entre el conjunto original y el revisado: el TEFI solo es comparable entre estructuras de los mismos ítems. Informe el punto de corte y los ítems que cambió."
        ),

        bootega = list(
            intro = c(
                "El bootstrap verifica si las dimensiones halladas arriba son una propiedad estable de los ítems o un accidente de esta muestra en particular (Christensen y Golino, 2021; ver referencias).",
                "Extrae muchas muestras nuevas de sus datos, ejecuta EGA con las mismas opciones de estimación en cada una y registra cuántas dimensiones aparecen y dónde queda cada ítem. Una estructura sólida aparece una y otra vez; una inestable cambia de una muestra a otra.",
                "Lea los resultados en este orden: la distribución del número de dimensiones, la estabilidad de cada dimensión, la estabilidad de cada ítem y la interpretación de la estabilidad."
            ),
            done = "Bootstrap completado: %d muestras (%s), semilla %d. Si cambia solo el idioma del informe, el punto de corte de estabilidad o las opciones de gráfico, se reutilizan estos resultados sin volver a ejecutar el bootstrap.",
            failed = "EGAnetLab no pudo completar el bootstrap: %s. El EGA de arriba sí se estimó, así que el problema está en algunas muestras bootstrap: pruebe el bootstrap por remuestreo, o menos ítems con muy pocas categorías.",
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
        ),
        groups = list(
            intro = "Esta sección compara la red de los ítems entre grupos de personas. Con una variable de agrupación compara grupos independientes (por ejemplo, mujeres y hombres, o dos países). Con una segunda medición de los mismos ítems compara a las mismas personas en dos momentos (por ejemplo, antes y después de una intervención).",
            small_dropped = "Se dejaron fuera de la comparación los grupos con menos de 10 casos: %s. Con tan pocas personas no es posible estimar redes de forma fiable.",
            missing_group = "%d caso(s) no tienen valor en la variable de agrupación y se dejaron fuera de la comparación entre grupos.",
            need_two = "La comparación entre grupos independientes necesita al menos dos grupos con 10 casos o más cada uno, así que no se ejecutó.",
            pairwise = "La variable de agrupación tiene %d grupos, así que cada par de grupos se compara por separado. Con muchos pares, algunas diferencias aparecerán por azar: céntrese en las diferencias que se repiten entre pares o que se mantienen tras la corrección por pruebas múltiples.",
            paired_count = "La segunda medición tiene %d variable(s), pero el análisis usa %d ítems. Agregue una variable por cada ítem, en el mismo orden de los ítems, para comparar las dos mediciones.",
            nothing = "Para comparar grupos, agregue una variable de agrupación (grupos independientes) o los ítems de una segunda medición de las mismas personas (grupos pareados)."
        ),

        inv = list(
            intro = c(
                "La invarianza métrica examina si cada ítem se relaciona con su dimensión con la misma fuerza en todos los grupos (Jamison, Christensen y Golino, 2024; ver referencias).",
                "EGAnetLab estima la red en cada grupo con la misma estructura dimensional y compara las cargas de red ítem por ítem. Luego reparte a las personas entre los grupos al azar muchas veces para ver qué tan grandes serían las diferencias si pertenecer a un grupo no importara. Un ítem cuya carga difiere más de lo esperable por azar no es invariante: no mide su dimensión de la misma forma en los dos grupos."
            ),
            no_groups = "Para evaluar la invarianza, agregue una variable de agrupación con al menos dos grupos de 10 casos o más. La invarianza compara grupos independientes; no usa la segunda medición.",
            structure_configural = "Estructura evaluada: la estructura estable entre grupos (invarianza configural). EGAnetLab primero ejecuta un EGA con bootstrap sobre todos los casos, conserva solo los ítems que se mantienen en su dimensión en suficientes muestras y vuelve a estimar la estructura sin los ítems inestables.",
            structure_ega = "Estructura evaluada: las dimensiones encontradas por el EGA de arriba, aplicadas a cada grupo.",
            iter_seed = "Permutaciones: %d, semilla %d.",
            isolated = "Ítems sin aristas en la red, excluidos de la prueba de invarianza: %s.",
            failed = "EGAnetLab no pudo completar la prueba de invarianza: %s. Los resultados del EGA de arriba no se ven afectados. Revise que cada grupo tenga suficientes casos y que ningún ítem sea constante dentro de un grupo.",
            configural_failed = "No se alcanzó la invarianza configural: tras quitar los ítems inestables, menos de dos ítems conservan una estabilidad de %.2f o más, así que no hay una estructura común que comparar. Los grupos no comparten las mismas dimensiones; compare sus redes con el Network Comparison Test o ejecute el EGA dentro de cada grupo.",
            configural_ok = "Invarianza configural: todos los ítems se mantienen en su dimensión en suficientes muestras bootstrap, así que se evaluaron todos.",
            configural_partial = "Invarianza configural: %d ítem(s) fueron inestables y se excluyeron antes de la prueba métrica: %s.",
            guide = c(
                "Cargas: la carga de red del ítem en su propia dimensión en cada grupo.",
                "Diferencia: carga en el primer grupo menos carga en el segundo grupo.",
                "p: proporción de permutaciones con una diferencia al menos tan grande como la observada. p (BH): el mismo valor p corregido por el número de ítems con el método de Benjamini-Hochberg.",
                "Dirección: el grupo con la carga mayor, que se muestra solo cuando p es .05 o menor."
            ),
            interp_invariant = "Ningún ítem muestra una diferencia de carga entre grupos mayor que la esperable por azar (todos los valores p son mayores que .05). La evidencia apoya la invarianza métrica: los ítems se relacionan con sus dimensiones con una fuerza similar en los grupos, así que las puntuaciones de estas dimensiones pueden compararse entre grupos con más seguridad.",
            interp_noninvariant = "Ítems cuyas cargas difieren entre grupos (p de .05 o menor), %d de %d: %s. Estos ítems se relacionan con su dimensión con distinta fuerza en cada grupo, así que la puntuación de la dimensión no es del todo comparable: parte de una diferencia entre grupos en la puntuación podría deberse a estos ítems y no al constructo.",
            interp_fdr_none = "Ninguna de estas diferencias sigue siendo significativa tras la corrección de Benjamini-Hochberg por el número de ítems evaluados. Considérelas tentativas: pueden ser hallazgos por azar y necesitan replicarse en otra muestra.",
            interp_fdr_some = "Ítem(s) que siguen siendo diferentes tras la corrección de Benjamini-Hochberg: %s. Son los casos más claros de falta de invarianza.",
            interp_partial = "Como algunos ítems se excluyeron en el paso configural, la prueba métrica solo se aplica a los ítems restantes. Informe qué ítems se excluyeron y por qué.",
            interp_next = "Siguiente paso: revise el contenido de los ítems no invariantes (redacción, significado cultural, pertinencia en cada grupo). Si no pueden corregirse, compare los grupos con puntuaciones que los excluyan, o informe la comparación con y sin ellos. Informe la estructura evaluada, el número de permutaciones, la semilla y ambos valores p."
        ),

        nct = list(
            intro = c(
                "El Network Comparison Test (NCT) compara dos redes completas: si sus conexiones difieren y si la fuerza total de sus conexiones difiere (van Borkulo et al., 2023; ver referencias).",
                "Estima la red de cada grupo, registra las diferencias y luego reparte a las personas entre los grupos al azar muchas veces (con las mismas personas medidas dos veces, intercambia las dos mediciones dentro de cada persona) para ver qué tan grandes serían las diferencias por azar."
            ),
            estimator_ordinal = "Cada red se estima con el lasso gráfico (EBIC, gamma .50) sobre correlaciones policóricas, porque los ítems tienen pocas categorías y se eligió Same as EGA en Correlations (NCT). Se recalculan en cada permutación, así que la prueba es lenta.",
            estimator_pearson = "Cada red se estima con el lasso gráfico (EBIC, gamma .50) sobre correlaciones de Pearson.",
            estimator_pearson_ordinal = "Cada red se estima con el lasso gráfico (EBIC, gamma .50) sobre correlaciones de Pearson, el valor por defecto del NCT. Con ítems ordinales, Pearson subestima un poco las asociaciones, pero ambas redes se estiman de la misma forma, así que la comparación sigue siendo justa. Elija Same as EGA en Correlations (NCT) para usar correlaciones policóricas; se recalculan en cada permutación, así que la prueba tarda varias veces más.",
            iter_seed = "Permutaciones: %d, semilla %d.",
            model_note = "La red de arriba se estimó con el modelo %s, pero el NCT siempre usa el lasso gráfico. Por eso las redes comparadas aquí pueden diferir un poco de la de arriba.",
            complete_cases = "El NCT necesita datos completos, así que cada comparación usa solo los casos con todos los ítems respondidos.",
            nothing = "Para ejecutar el NCT, agregue una variable de agrupación con al menos dos grupos de 10 casos o más, o los ítems de una segunda medición de las mismas personas.",
            guide = c(
                "Estructura de la red (M): la mayor diferencia en una sola arista entre las dos redes. Un p pequeño indica que al menos una conexión difiere.",
                "Fuerza global (S): la diferencia en la suma de los pesos absolutos de las aristas de cada red. Un p pequeño indica que una red está, en conjunto, más fuertemente conectada.",
                "Aristas: cada conexión cuyo peso difiere entre las redes (p de .05 o menor tras la corrección elegida).",
                "Centralidad: la diferencia en fuerza e influencia esperada de cada ítem entre las redes, con la corrección elegida."
            ),
            failed = "EGAnetLab no pudo ejecutar el NCT para %s: %s. Revise que ambos grupos tengan suficientes casos completos y que ningún ítem sea constante dentro de un grupo.",
            row_M = "Estructura de la red (M)",
            row_S = "Fuerza global (S)",
            no_edges_note = "Ninguna arista difiere entre las redes con p de .05 o menor tras la corrección.",
            note_table = "M = mayor diferencia en una sola arista; S = diferencia en la fuerza global (suma de los pesos absolutos de las aristas). Los valores p provienen de las permutaciones.",
            interp_n = "%s: %s (n = %d) y %s (n = %d)%s.",
            paired_word = ", las mismas personas medidas dos veces",
            interp_M_sig = "La estructura de la red difiere: la mayor diferencia en una sola conexión (M = %s) es mayor que la esperable por azar (%s). Al menos una relación entre ítems no es la misma en las dos redes. La prueba de aristas (Evaluar cada arista) busca cuáles; tras su corrección por muchas pruebas, puede que ninguna arista aislada alcance significación aunque M sí la alcance, así que lea M como evidencia de que las redes difieren en algún punto.",
            interp_M_ns = "No hay evidencia de que la estructura de la red difiera: la mayor diferencia en una sola conexión (M = %s) está dentro de lo esperable por azar (%s). Esto no demuestra que las redes sean iguales; con grupos pequeños la prueba tiene poca potencia.",
            interp_S_sig = "La fuerza global difiere: %s en %s y %s en %s (%s). En una de las redes los ítems están, en conjunto, más fuertemente conectados, lo que suele acompañar una presentación más homogénea o más intensa del constructo.",
            interp_S_ns = "La fuerza global es similar: %s en %s y %s en %s (%s). El nivel general de conexión entre los ítems no difiere más allá del azar.",
            interp_edges_none = "Ninguna conexión individual difiere tras la corrección por pruebas múltiples.",
            interp_edges_some = "%d conexión(es) difieren entre las redes tras la corrección por pruebas múltiples (ver la tabla de aristas).",
            interp_cen_none = "Ningún ítem difiere en centralidad entre las redes tras la corrección por pruebas múltiples.",
            interp_cen_some = "%d valor(es) de centralidad difieren entre las redes tras la corrección por pruebas múltiples (ver la tabla de centralidad).",
            interp_next = "Siguiente paso: interprete las diferencias en las conexiones junto con la prueba de invarianza, porque una red distinta puede cambiar el significado de la puntuación de una dimensión entre grupos. Informe el estimador, el número de permutaciones, la semilla, la corrección y el tamaño de cada grupo."
        ),

        cen = list(
            intro = c(
                "La centralidad describe la posición de cada ítem en la red estimada. La fuerza es la suma de los pesos absolutos de las conexiones de un ítem; la influencia esperada es la misma suma conservando el signo, así que las conexiones negativas restan (Opsahl et al., 2010; Robinaugh et al., 2016; ver referencias).",
                "En una red de ítems, un ítem central comparte mucha varianza única con el resto del conjunto. Eso describe al ítem dentro de este conjunto de ítems; no muestra que el ítem cause o defina el constructo."
            ),
            guide = c(
                "Fuerza: qué tan conectado está el ítem en conjunto, sobre la misma red de EGA.",
                "Influencia esperada: como la fuerza, pero las conexiones negativas restan. Solo difiere de la fuerza cuando el ítem tiene conexiones negativas.",
                "Cercanía e intermediación (opcionales): se basan en los caminos más cortos entre ítems. Son menos estables y más difíciles de interpretar en redes psicológicas (Bringmann et al., 2019; ver referencias)."
            ),
            guide_z = "Los valores están estandarizados entre ítems (media 0, DE 1). Un valor mayor que 1 señala un ítem claramente más central que el ítem promedio; menor que -1, claramente menos central.",
            guide_raw = "Los valores están sin estandarizar: la fuerza y la influencia esperada son sumas de correlaciones parciales; la cercanía y la intermediación conservan sus propias escalas.",
            empty = "La red estimada no tiene aristas, así que la centralidad no está definida.",
            failed = "EGAnetLab no pudo calcular la centralidad: %s.",
            interp_top = "Por fuerza, el o los ítems más centrales: %s. Son los que comparten más varianza única con el resto del conjunto. Si además son redundantes (ver Redundancia, UVA), su centralidad puede reflejar contenido solapado más que importancia.",
            interp_low = "El o los ítems menos centrales: %s. Los ítems débilmente conectados aportan poco a la red; revise sus cargas de red y su estabilidad.",
            interp_ei_same = "No hay conexiones negativas, así que la influencia esperada ordena los ítems exactamente igual que la fuerza.",
            interp_ei_diff = "%d ítem(s) tienen conexiones negativas, por lo que su influencia esperada es menor que su fuerza: %s. Revise si están redactados en negativo o describen el polo opuesto del constructo.",
            interp_dims = "La centralidad se calcula sobre toda la red, a través de las dimensiones. Un ítem puede ser central porque conecta dimensiones, no solo porque sea central dentro de la suya.",
            interp_closbetw = "La cercanía y la intermediación se muestran porque se pidieron. En redes psicológicas suelen ser inestables y no tienen un significado claro (Bringmann et al., 2019); deles menos peso que a la fuerza.",
            interp_next = "Siguiente paso: marque Stability of edges and centrality (bootnet) para comprobar si el orden de los ítems por centralidad se mantiene antes de interpretar diferencias entre ítems.",
            interp_with_bn = "Lea el orden de los ítems junto con el coeficiente CS de Estabilidad de la red: por debajo de .25, las diferencias de centralidad entre ítems no deben interpretarse."
        ),

        bn = list(
            intro = c(
                "Esta sección comprueba qué tan precisa es la red estimada, con los procedimientos de bootnet (Epskamp et al., 2018; ver referencias). Vuelve a estimar la misma red de EGA (misma correlación, modelo y manejo de valores perdidos) en muchas muestras bootstrap.",
                "Se usan dos procedimientos: remuestrear casos con reemplazo, que da un intervalo para el peso de cada arista, y eliminar proporciones crecientes de casos, que muestra si el orden de los ítems por centralidad se mantiene con menos personas."
            ),
            done = "Listo: %d muestras remuestreando casos y %d muestras eliminando casos, semilla %d. Los resultados se conservan mientras no cambien las opciones de estimación.",
            failed = "EGAnetLab no pudo ejecutar el análisis de estabilidad de la red: %s.",
            empty = "La red estimada no tiene aristas, así que no se puede evaluar su estabilidad.",
            guide = c(
                "Coeficiente CS: la mayor proporción de casos que puede eliminarse manteniendo una correlación de .70 o más entre el orden de centralidad y el original en el 95% de las muestras. Por debajo de .25 el orden no debe interpretarse; se prefiere .50 o más (Epskamp et al., 2018).",
                "Intervalos de las aristas: el rango que cubre el 95% de los pesos bootstrap de cada arista. Un intervalo amplio indica un peso impreciso; un intervalo que incluye el 0 indica que la arista podría no aparecer en otras muestras.",
                "Muestras con la arista: el porcentaje de muestras bootstrap en que la arista se estimó distinta de cero."
            ),
            cs_good = "Estable (.50 o más)",
            cs_mid = "Interpretar con cautela (.25 a .50)",
            cs_bad = "No interpretable (menos de .25)",
            cs_note = "CS = mayor proporción de casos que puede eliminarse manteniendo una correlación de .70 o más con el orden original en el 95% de las muestras. El valor más alto evaluado es .75.",
            edges_note = "Solo se listan las aristas de la red estimada, de la más fuerte a la más débil. Los intervalos son percentiles del remuestreo de casos. En redes regularizadas los pesos se acercan a cero, así que los intervalos describen la precisión y no son pruebas de significación (Epskamp et al., 2018).",
            interp_cs_good = "El orden de los ítems por %s es estable (CS = %s): se mantiene al eliminar hasta el %s de los casos, así que las diferencias entre ítems pueden interpretarse.",
            interp_cs_mid = "El orden de los ítems por %s es moderadamente estable (CS = %s): interprete solo las diferencias grandes entre ítems, y con cautela.",
            interp_cs_bad = "El orden de los ítems por %s no es estable (CS = %s): cambia al eliminar pocos casos, así que las diferencias entre ítems no deben interpretarse.",
            interp_edges = "%d de las %d aristas de la red se estimaron en al menos el 90%% de las muestras; %d tienen un intervalo que incluye el cero, así que podrían no aparecer en otras muestras.",
            interp_width = "La anchura media de los intervalos de las aristas es %s. No puede afirmarse que dos aristas cuyos intervalos se solapan ampliamente difieran en fuerza.",
            interp_next = "Siguiente paso: informe el número de muestras, la semilla y el coeficiente CS junto con los resultados de centralidad. Si la estabilidad es baja, el principal remedio es una muestra mayor; eliminar ítems para aumentarla cambia el constructo que se mide."
        ),

        dyn = list(
            intro = c(
                "El Análisis Exploratorio de Grafos dinámico (dynEGA) estima la estructura dimensional de datos longitudinales intensivos: los mismos ítems respondidos muchas veces por cada persona, por ejemplo en diarios o en evaluación ecológica momentánea (Golino et al., 2022; ver referencias).",
                "Para cada persona estima primero cómo cambia cada ítem de un momento al siguiente (sus derivadas, con aproximación lineal local generalizada; Boker et al., 2010). Luego aplica EGA a esas derivadas, así que las dimensiones agrupan ítems que cambian juntos en el tiempo, no ítems que simplemente son altos o bajos a la vez.",
                "La estructura puede estimarse para toda la muestra (población), para cada grupo y para cada persona. Compararlas muestra si una sola estructura describe a todos o si las personas difieren."
            ),
            embed_text = "Dimensión de inmersión %d: cada derivada se estima con una ventana de %d momentos consecutivos. Ventanas más grandes suavizan el error de medida, pero necesitan más momentos por persona y ocultan los cambios rápidos; 5 es el valor habitual. Retardo tau = %d: con tau = 1 la ventana usa momentos consecutivos; valores mayores saltan momentos y suavizan más la serie. Delta = %s es el tiempo entre mediciones; solo cambia la escala de las derivadas.",
            choose_id = "Seleccione los ítems y la variable que identifica a cada persona para ejecutar el EGA dinámico. Los datos deben estar en formato largo: una fila por persona y momento.",
            constant_item = "Los siguientes ítems no varían en los datos y no pueden entrar en el análisis: %s. Retírelos.",
            too_few_persons = "Menos de dos personas tienen suficientes momentos (al menos %d, la dimensión de inmersión más 2). El EGA dinámico necesita muchos momentos por persona; reduzca la dimensión de inmersión o revise la variable Person ID.",
            group_varies = "La variable de agrupación cambia dentro de %d persona(s); a cada una se le asignó el grupo de su primer momento.",
            dropped = "%d persona(s) tienen menos de %d momentos y quedaron fuera: %s.",
            failed = "EGAnetLab no pudo estimar el EGA dinámico: %s. Esto suele indicar muy pocos momentos por persona para el número de ítems, o ítems que casi no cambian en el tiempo. Pruebe una dimensión de inmersión menor, menos ítems o solo el nivel de población.",
            done = "Estimado: población%s%s, derivada %s, dimensión de inmersión %d, semilla %d. Los resultados se conservan mientras no cambien las opciones de estimación.",
            done_groups = ", grupos",
            done_individual = ", cada persona",
            deriv_0 = "nivel",
            deriv_1 = "velocidad de cambio",
            deriv_2 = "aceleración",
            interp_dims_one = "En la población, los ítems forman una sola dimensión (derivada analizada: %s): tienden a cambiar juntos en el tiempo.",
            interp_dims_many = "En la población, los ítems forman %d dimensiones (derivada analizada: %s): dentro de cada dimensión los ítems cambian juntos en el tiempo, y en parte de forma independiente de las otras dimensiones.",
            interp_isolated = "%d ítem(s) quedaron sin dimensión en la población: %s. Sus cambios en el tiempo no se conectan con los de los demás ítems.",
            interp_deriv_1 = "Como se analizó la primera derivada, esta es una estructura de cambio: describe qué ítems suben y bajan juntos de un momento a otro. Puede diferir de la estructura de un EGA transversal de los mismos ítems, que describe qué personas puntúan alto o bajo a la vez.",
            interp_deriv_0 = "Como se analizó el nivel (derivada 0), la estructura refleja los valores suavizados de los ítems dentro de la ventana de cada persona, más cercana a una estructura de estados que de cambio.",
            interp_deriv_2 = "Como se analizó la segunda derivada, la estructura describe cómo se acelera conjuntamente el cambio; es más ruidosa y necesita muchos momentos por persona.",
            interp_groups_detail = "Por grupos, %s.",
            interp_pooled = "Ningún grupo reproduce la estructura de la población. Las %s dimensiones de la población combinan estructuras que difieren entre grupos, así que no describen bien a ninguno. Informe la estructura de cada grupo en lugar de solo el resultado de la población.",
            dims_word_1 = "1 dimensión",
            dims_word_n = "%s dimensiones",
            group_word = "el grupo %s tiene %s",
            agree_group_identical = "Misma pertenencia de ítems que su propio grupo (ARI = 1)",
            agree_group_median = "Acuerdo mediano con su propio grupo (ARI)",
            interp_ind_group_high = "Comparadas con su propio grupo, el %s de las personas muestra exactamente la pertenencia de ítems de su grupo (ARI mediano = %s). Las diferencias entre personas se explican por el grupo al que pertenecen, no por estructuras idiosincrásicas: describa la estructura de cada grupo.",
            interp_ind_group_low = "Incluso dentro de su propio grupo las personas difieren (ARI mediano con su grupo = %s): las estructuras individuales varían más allá del grupo.",
            interp_ind_pop_group = "El acuerdo con la población (ARI mediano = %s) es menor porque la población mezcla los grupos.",
            interp_groups_same = "Todos los grupos muestran el mismo número de dimensiones que la población.",
            interp_groups_diff = "No todos los grupos muestran el número de dimensiones de la población (ver Estructura de cada grupo). La estructura del cambio puede diferir entre grupos; revise el tamaño de los grupos antes de interpretarlo.",
            interp_next = "Siguiente paso: marque Structure of each person para ver si la estructura de la población describe a los individuos. En datos longitudinales intensivos, la estructura de la población a menudo no se cumple en cada persona.",
            ind_intro = "La red propia de cada persona se estima a partir de sus derivadas. Las estructuras individuales se basan en menos datos que la de la población, así que son más ruidosas; lea su distribución, no cada una por separado.",
            ind_few_points = "%d persona(s) tienen menos estimaciones de derivadas (momentos menos la dimensión de inmersión más 1) que ítems (%d), así que sus redes individuales se basan en muy poca información y no son fiables. Las estructuras individuales necesitan muchos más momentos que ítems.",
            ind_failed = "No se pudo estimar la estructura de %d persona(s) (muy pocos momentos o ítems sin cambio): %s.",
            agree_persons = "Personas con estructura estimada",
            agree_same_n = "Mismo número de dimensiones que la población",
            agree_identical = "Misma pertenencia de ítems que la población (ARI = 1)",
            agree_median = "Acuerdo mediano con la población (ARI)",
            agree_note = "ARI = índice de Rand ajustado entre la pertenencia de los ítems de cada persona y la de la población (Hubert y Arabie, 1985): 1 = idéntica, cerca de 0 = no más acuerdo que el azar. Los ítems sin dimensión cuentan como un grupo propio.",
            interp_ind_modal = "Número de dimensiones entre personas: %s. El %s de las personas muestra el número de dimensiones de la población (%s).",
            interp_ind_high = "El acuerdo mediano con la pertenencia de la población es alto (ARI = %s) y la mayoría de las personas muestra el número de dimensiones de la población, así que la estructura de la población es un resumen razonable de los individuos.",
            interp_ind_mid = "El acuerdo mediano con la pertenencia de la población es moderado (ARI = %s): la estructura de la población describe a los individuos solo en parte. Informe la heterogeneidad individual junto con el resultado de la población.",
            interp_ind_low = "El acuerdo mediano con la pertenencia de la población es bajo (ARI = %s): las estructuras individuales difieren mucho de la de la población, que no debe leerse como la estructura de cada persona (un proceso no ergódico).",
            interp_ind_next = "Siguiente paso: informe la estructura de la población junto con la distribución de las estructuras individuales, el número de momentos por persona y la derivada analizada. Revise si las personas que difieren de la población comparten características (grupo, adherencia, número de momentos).",
            summary_persons = "Personas",
            summary_points = "Momentos por persona (mín. / mediana / máx.)",
            summary_rows = "Filas usadas",
            summary_glla = "Derivadas (GLLA)",
            summary_glla_value = "inmersión %d, tau %d, delta %s; derivada analizada: %s",
            summary_ndim = "Dimensiones (población)",
            plot_x = "Número de dimensiones",
            plot_y = "Proporción de personas",
            plot_population = "Número de la población (%s)",
            plot_other = "Otra"
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
