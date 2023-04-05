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

# Konstanten für unsere Simulation
const max_days = 100
const post_per_day = 100

rng = Xoshiro(99)

# Unsere Verteilungen
opinion_dist = Uniform(-1,1)
hate_dist = Bernoulli(0.01) # 10 Prozent ist hate
reporting_dist_non_hate = Exponential(0.8) # wenige Meldungen 
reporting_dist_hate = Exponential(1.5)

# Test für unsere reporting distribution
using Plots
test = [floor(rand(rng,reporting_dist_hate)) for x in 1:1000]
histogram(test)

# Generiere die Posts
liste = Vector{Post}()
id_count = 0
for day in 1:max_days
    for i in 1:post_per_day
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

# Helferfunktionen zum erkennen

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


# Reporting Matrix berechnen
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

report_conf_matrix#

# Klassifier

perfect_conf_matrix = [[1,0.0]  [0.0,1.0] ]
kistra_conf_matrix = [[0.7,0.3]  [0.1,0.9] ]



function classify(conf_matrix::Matrix{Float64}, p::Post, rng::AbstractRNG)
    probability = 0.0
    if p.is_hate 
        #println("Ishate")
        probability = conf_matrix[1,1]
    else
        #println("Is non hate")
        probability = conf_matrix[2,2]
    end

    guess = rand(rng, Bernoulli(probability))

    if guess 
        p.is_hate
    else
        !p.is_hate
    end
end



#classify(perfect_conf_matrix,Post(is_hate = true),rng)


ki_conf_matrix = zeros(Int, 2, 2)
for i in 1:length(liste)
    if liste[i].reports > 0
        cls_result = classify(kistra_conf_matrix, liste[i], rng)
        # hass korrekt gefunden
        if liste[i].is_hate && cls_result
            ki_conf_matrix[1,1] += 1
        end
        # hass inkorrekt gefunden
        if (!liste[i].is_hate) && cls_result
            ki_conf_matrix[1,2] += 1
        end
        # keinhass korrekt gefunden
        if (!liste[i].is_hate) && !cls_result
            ki_conf_matrix[2,2] += 1
        end
        # keinhass inkorrekt gefunden
        if (liste[i].is_hate) && !cls_result
            ki_conf_matrix[2,1] += 1
        end
    end
end

ki_conf_matrix


