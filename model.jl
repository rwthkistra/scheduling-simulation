using Pkg
Pkg.activate(".")
using Agents
using Random
using Distributions


# Klassifikator mit Konfusionsmatrix
# Scheduling Strategien
# - Chronologisch
# - 30% Chronologisch 30% Random 30% Kistra
# - 50% Kistra 50% Chronologisch
# - 100% Kistra
# - Mehrfachmeldungen

Base.@kwdef mutable struct Post
    id::Int = 0
    timestamp::Int = 1
    opinion::Float64 = 0 # -1 bis 1
    is_hate::Bool = false
    reports::Int = 0
end

Post(timestamp = 2)

ts = 123
liste = Vector{Post}()



opinion_dist = Uniform(-1,1)
hate_dist = Bernoulli(0.1)

rng = MersenneTwister(99)
value = Random.rand(rng, d)


@time for i in 1:100000
    tmp = Post(id = i, 
                timestamp = ts, 
                opinion = rand(rng, opinion_dist), 
                is_hate = rand(rng, hate_dist),
                reports = 0)
    push!(liste, tmp)
end

liste

