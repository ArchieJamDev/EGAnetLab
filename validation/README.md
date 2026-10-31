# Validation

Scripts that check EGAnetLab against EGAnet itself. Unlike `tests/` (which
checks graceful behavior on pathological input), these scripts check that the
numbers are identical to a direct EGAnet call.

| Script | Checks |
| --- | --- |
| `ega_equivalence.R` | Number of dimensions, memberships and TEFI of `ega()` vs. `EGAnet::EGA()` on the WMT-2 items, for 2 network models × 3 algorithms |

Run from the repository root after installing the module as an R package:

```sh
R CMD INSTALL .
Rscript validation/ega_equivalence.R
```

Results are written next to each script (`*_results.csv`).
