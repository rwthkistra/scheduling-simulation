using Distributions
using CSV
using DataFrames
using Random
bootstrap_data = CSV.read("data/bootstrap_dataframe.csv", DataFrame)

function get_confidence(case, rng)
    # Sample a confidence value from the Beta distribution
    return shuffle(rng, bootstrap_data |> filter(row -> row.cm_val == case)).hate_score[1]
end

rng = Xoshiro(1234) # Random number generator for reproducibility
get_confidence("tn", rng) # Example usage, returns a random confidence value