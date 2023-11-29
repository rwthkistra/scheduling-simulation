using StatsPlots
include("utils.jl")

# Constant distributions and values
hate_dist = Bernoulli(0.05) # 5 Prozent ist hate
reporting_dist_non_hate = Exponential(0.5) # wenige Meldungen 
reporting_dist_hate = Exponential(1.5) # more reports
reporting_dist_overall = Bernoulli(0.2) # overall reporting probability
kistra_conf_matrix = confusionmatrix(0.3, 0.1) # default confusion matrix



# delete png outputs
dir = "output"
filelist = filter(x -> endswith(x, ".png"), readdir(dir))
# delete files in output folder using julia
map(rm, joinpath.(dir, filelist))


plot(hate_dist, label="Hate Distribution", xlabel="Hate", ylabel="Probability", title="Likellihood of hate in posts")
savefig("output/hate_dist.png")


plot(reporting_dist_non_hate, label="Reporting non-hate distribution", xlabel="Reporting", ylabel="Probability", title="Reporting Distributions")
plot!(reporting_dist_hate, label="Reporting hate distribution")
savefig("output/reporting_dist.png")




