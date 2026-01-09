# Merge subgroup data (special populations)

The Subgroup sheet has multiple rows per entity (one per subgroup type).
We need to pivot it wider to get columns for EL, SPED, and FRL.

## Usage

``` r
merge_subgroup_data(base, subgroup_data, entity_col)
```

## Arguments

- base:

  Base dataframe

- subgroup_data:

  Subgroup dataframe

- entity_col:

  Name of entity ID column

## Value

Merged dataframe with special population columns
