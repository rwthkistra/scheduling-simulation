using BenchmarkTools
include("../src/scheduling_strategies.jl")


## this test using the Post struct from simulation.jl
include("../model.jl")

q1 = [
    Post(id=1, created_at=1, reviewed_at=1, is_hate=true, kistra_is_hate=false, kistra_confidence=0.0, kistra_fp=false, kistra_fn=false, reports=0),
    Post(id=2, created_at=2, reviewed_at=2, is_hate=true, kistra_is_hate=false, kistra_confidence=0.0, kistra_fp=false, kistra_fn=false, reports=0),
    Post(id=3, created_at=3, reviewed_at=3, is_hate=true, kistra_is_hate=false, kistra_confidence=0.0, kistra_fp=false, kistra_fn=false, reports=0),
    Post(id=4, created_at=4, reviewed_at=4, is_hate=true, kistra_is_hate=false, kistra_confidence=0.0, kistra_fp=false, kistra_fn=false, reports=0),
    Post(id=5, created_at=5, reviewed_at=5, is_hate=true, kistra_is_hate=false, kistra_confidence=0.0, kistra_fp=false, kistra_fn=false, reports=0)
]
q2 = [
    Post(id=10, created_at=1, reviewed_at=1, is_hate=true, kistra_is_hate=true, kistra_confidence=0.0, kistra_fp=false, kistra_fn=false, reports=0),
    Post(id=20, created_at=2, reviewed_at=2, is_hate=true, kistra_is_hate=true, kistra_confidence=0.0, kistra_fp=false, kistra_fn=false, reports=0),
    Post(id=30, created_at=3, reviewed_at=3, is_hate=true, kistra_is_hate=true, kistra_confidence=0.0, kistra_fp=false, kistra_fn=false, reports=0),
    Post(id=40, created_at=4, reviewed_at=4, is_hate=true, kistra_is_hate=true, kistra_confidence=0.0, kistra_fp=false, kistra_fn=false, reports=0),
    Post(id=50, created_at=5, reviewed_at=5, is_hate=true, kistra_is_hate=true, kistra_confidence=0.0, kistra_fp=false, kistra_fn=false, reports=0)
]

rng=Xoshiro(1234)



q12 = merge_n_queues!([q1, q2]) # should be 1, 10, 2, 20, 3

fifo(q12,rng) # should be 1, 2, 3, 10, 20
kistra(q12,rng) # should be 10, 20, 1, 2, 3
merge_n_queues!([fifo(q12,rng), kistra(q12,rng)]) # should be 1, 10, 2, 20, 3