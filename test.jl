using Random
using Distributions
using Plots
using ProgressMeter

include("src/scheduling_strategies.jl")
include("settings.jl")
include("model.jl")

# simulate signature
# simulate(number_of_employees = 1, num_posts_per_day = 400, reviews_per_day = 400, number_of_days = 31, 
# confusion_matrix = kistra_conf_matrix, scheduling_strategy_functions = [kistra], seed = 99)
# returns: [ltr_ih], [reviewed_hate], [reviewed_fn_delay], [ltr_ifn], [ltr_ifp]
#res = simulate(1, 200, 100, 10, confusionmatrix(0,0), [fifo]) 
#
#simulate(1, 100, 100, 10, confusionmatrix(0,0), [kistra], 1)
#
#simulate()



include("runsim.jl")

runsim(;replications=1,
    number_of_days=100,
    confusion_matrix=confusionmatrix(0.3, 0.1),
    workers=1,
    post_count=6000,
    posts_per_day=100,
    run_id="001")