using Pkg
Pkg.activate(".")
using ProgressMeter

include("run.jl")
@info "Active Threads: $(Threads.nthreads())"

#for i in 1:10
p = Progress(100; dt=1.0, desc="Running simulations", showspeed=true)
for alpha in 0.05:0.05:0.5
    #alpha = round(0.05 * i, digits=2)
    for beta in 0.05:0.05:0.5
    @debug "Running simulation for alpha=$alpha, beta = $beta"
    local_run_id = "a$(alpha)_b$(beta)"
    runsim(replications = 100, confusion_matrix=confusionmatrix(alpha, beta), run_id=local_run_id)
    next!(p)
    end
end
finish!(p)


runsim(replications = 100, confusion_matrix=confusionmatrix(alpha, beta), run_id=local_run_id)