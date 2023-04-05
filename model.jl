using Pkg
Pkg.activate(".")
using Agents
using Random
using Distributions
using Statistics
using Plots
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



rng = Xoshiro(99)

# Unsere Verteilungen
opinion_dist = Uniform(-1,1)
hate_dist = Bernoulli(0.01) # 10 Prozent ist hate
reporting_dist_non_hate = Exponential(0.8) # wenige Meldungen 
reporting_dist_hate = Exponential(1.5)

# Test für unsere reporting distribution
using Plots
test = [floor(rand(rng,reporting_dist_hate)) for x in 1:100000]
histogram(test)

liste = Vector{Post}()
id_count = 0
for day in 1:100
    for i in 1:100
        global id_count = id_count + 1
        is_h = rand(rng, hate_dist)
        tmp = Post( id = id_count, 
                    timestamp = day, 
                    opinion = rand(rng, opinion_dist), 
                    is_hate = is_h,
                    reports = is_h ? 
                            convert(Int, floor(rand(rng, reporting_dist_hate))) : 
                            convert(Int, floor(rand(rng, reporting_dist_non_hate))))
        push!(liste, tmp)
    end 
end



function isTPreport(p::Post)
    p.is_hate && p.reports > 0
end

function isTNreport(p::Post)
    !p.is_hate && p.reports == 0
end

function isFPreport(p::Post)
    !p.is_hate && p.reports > 0
end

function isFNreport(p::Post)
    p.is_hate && p.reports == 0
end

liste

report_conf_matrix = zeros(Int, 2, 2)

for i in 1:length(liste)
    if isTPreport(liste[i])
        report_conf_matrix[1,1] += 1
    end
    if isTNreport(liste[i])
        report_conf_matrix[2,2] += 1
    end
    if isFPreport(liste[i])
        report_conf_matrix[1,2] += 1
    end
    if isFNreport(liste[i])
        report_conf_matrix[2,1] += 1
    end
end

report_conf_matrix

