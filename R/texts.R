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
