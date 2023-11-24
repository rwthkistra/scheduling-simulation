using BenchmarkTools
include("simulation.jl")
q1 = [
    Post(id = 1, created_at = 1, is_hate = true, kistra_classification = true, reports = 0),
    Post(id = 2, created_at = 2, is_hate = false, kistra_classification = false, reports = 0),
    Post(id = 3, created_at = 3, is_hate = false, kistra_classification = true, reports = 0),
    Post(id = 4, created_at = 4, is_hate = true, kistra_classification = false, reports = 0),
    Post(id = 5, created_at = 5, is_hate = true, kistra_classification = true, reports = 0),
]

q2 = [
    Post(id = 5, created_at = 5, is_hate = true, kistra_classification = true, reports = 0),
    Post(id = 1, created_at = 1, is_hate = true, kistra_classification = true, reports = 0),
    Post(id = 3, created_at = 3, is_hate = false, kistra_classification = true, reports = 0),
    Post(id = 2, created_at = 2, is_hate = false, kistra_classification = false, reports = 0),
    Post(id = 4, created_at = 4, is_hate = true, kistra_classification = false, reports = 0),
]

q3 = [
    Post(id = 1, created_at = 1, is_hate = true, kistra_classification = true, reports = 0),
    Post(id = 5, created_at = 5, is_hate = true, kistra_classification = true, reports = 0),
    Post(id = 2, created_at = 2, is_hate = false, kistra_classification = false, reports = 0),
    Post(id = 3, created_at = 3, is_hate = false, kistra_classification = true, reports = 0),
    Post(id = 4, created_at = 4, is_hate = true, kistra_classification = false, reports = 0),
]

@btime q4 = merge_n_queues!([q1, q2, q3])


@benchmark sort([4,3,2,1])

@benchmark a=false 
@code_llvm 1+1.0
@benchmark 1+1.0