using Random
using Distributions
using Plots
using ProgressMeter

include("scheduling_strategies.jl")
include("settings.jl")
include("simulation.jl")

simulate(1, 100, 100, 10, confusionmatrix(0,0), [fifo], 1) 
simulate(1, 100, 100, 10, confusionmatrix(0,0), [kistra], 1) 

simulate()