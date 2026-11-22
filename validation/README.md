# Validation

Scripts that check EGAnetLab against EGAnet itself. Unlike `tests/` (which
checks graceful behavior on pathological input), these scripts check that the
numbers are identical to a direct EGAnet call.

| Script | Checks |
| --- | --- |
| `ega_equivalence.R` | Number of dimensions, memberships and TEFI of `ega()` vs. `EGAnet::EGA()` on the WMT-2 items, for 2 network models × 3 algorithms |
| `procedure_equivalence.R` | The 20 quantities of Table A1 of the tutorial: bootstrap, UVA, network loadings, riEGA, hierEGA, metric invariance, NCT, bootnet CS coefficient and dynamic EGA, from `ega()` and `dynega()` vs. direct calls to EGAnet, NetworkComparisonTest and bootnet with the same seed |

Run from the repository root after installing the module as an R package:

```sh
R CMD INSTALL .
Rscript validation/ega_equivalence.R
Rscript validation/procedure_equivalence.R
```

Both scripts also run in the `Validate jamovi module` workflow on every push and pull request to `main`, and stop it on any mismatch.

Results are written next to each script (`*_results.csv`).
