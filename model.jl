using Pkg
Pkg.activate(".")
using Agents



# Klassifikator mit Konfusionsmatrix
# Scheduling Strategien
# - Chronologisch
# - 30% Chronologisch 30% Random 30% Kistra
# - 50% Kistra 50% Chronologisch
# - 100% Kistra
# - Mehrfachmeldungen

Base.@kwdef struct Post
    timestamp::Int = 1
    opinion::Float64 = 0 # -1 bis 1
    reports::Int = 0
end

Post(timestamp = 2)

