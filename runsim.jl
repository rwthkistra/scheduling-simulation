using OnlineStats
using Logging

# debuglogger = ConsoleLogger(stderr, Logging.Debug)
# global_logger(debuglogger)

include("model.jl")
include("src/scheduling_strategies.jl")

"""
Runs the simulation with the given parameters.
- `replications`: Number of times to run the simulation (default: 1).
- `number_of_days`: Total number of days to simulate (default: 365).
- `confusion_matrix`: The confusion matrix to use for the simulation (default: confusionmatrix(0.3, 0.1)).
- `workers`: Number of workers to simulate (default: 1).
- `post_count`: Total number of posts a worker can review (default: 100).
- `posts_per_day`: Number of posts to generate per day (default: 100).
- `run_id`: Identifier for the run (default: "001").
"""
function runsim(;replications=1,
    number_of_days=365,
    confusion_matrix=confusionmatrix(0.3, 0.1),
    workers=1,
    post_count=150,
    posts_per_day=100,
    run_id="001")


    # generate params object
    params = (workers, post_count, posts_per_day, number_of_days, confusion_matrix)
    
    # print a summary of the parameters
    @info "Running simulation with parameters: "
    @info "Workers: $workers"
    @info "Post generated per day: $post_count"
    @info "Posts reviewed per worker: $posts_per_day"
    @info "Number of Days: $number_of_days"
    @info "Confusion Matrix: $confusion_matrix"
    @info "Run ID: $run_id"

    mkpath("output")
    plotconfusionmatrix(confusion_matrix, "output/kistra_conf_matrix_$(run_id).png")



    @debug "Preparing simulation" params
 
    strategies = Vector{Vector{Function}}()
    push!(strategies, [fifo])
    push!(strategies, [kistra])
    push!(strategies, [fifo, kistra])
    #push!(strategies, [fifo, kistra, deterministic_shuffle])
    #push!(strategies,[fifo,deterministic_shuffle])


    # initialize online stats
    ltr_mean = [[Series(Mean()) for _ in 1:number_of_days] for _ in 1:length(strategies)]
    r_mean = [[Series(Mean()) for _ in 1:number_of_days] for _ in 1:length(strategies)]
    ltr_is_fn_mean = [[Series(Mean()) for _ in 1:number_of_days] for _ in 1:length(strategies)]


    # debug stuff

    #ltr_i, r_i, _, ltr_fn_i = simulate(params..., [deterministic_shuffle], 1)
    #ltr_i

    Threads.@threads for i in 1:replications
        #i = 1
        @debug "- Iteration: $i"

        # temporary storage
        ltr = []
        r = []
        ltr_fn = []

        for strats in strategies
            @debug "-- Strategies: $strats"
            #global id_count = 0
            #strats = strategies[1]
            # print the strategy name
            @info "--- Running simulation for strategy: $(strats)"

            ltr_i, r_i, _, ltr_fn_i = simulate(params..., strats, i)
            push!(ltr, ltr_i)
            push!(r, r_i)
            push!(ltr_fn, ltr_fn_i)
            @debug "LTR: " ltr
            @debug "R: " r
            @debug "LTR_FN: " ltr_fn
        end

        for j in 1:length(strategies)
            for k in 1:number_of_days
                fit!(ltr_mean[j][k], ltr[j][k])
                fit!(r_mean[j][k], r[j][k])
                fit!(ltr_is_fn_mean[j][k], ltr_fn[j][k])
            end
        end
    end


    function short_name_strategies(f::Vector{Function})
        function plusreduce(x, y)
            return x * " + " * y
        end

        res = map(x -> string(String(Symbol(x))[1]), f)

        res = reduce(plusreduce, res)
        return res
    end


    # new adaptive plot
    ltr_dict = Dict()
    for j in 1:length(strategies)
        ltr_dict[short_name_strategies(strategies[j])] = [value(ltr_mean[j][i]) for i in 1:number_of_days]
    end

    p1 = plot(title="Total # hate posts left to review")
    for (key, value) in ltr_dict
        @debug "Key: $key"
        @debug "Value: $value"
         p1 = plot!(value, label=key)
    end
    #display(p1)

    fn_dict = Dict()
    for j in 1:length(strategies)
        fn_dict[short_name_strategies(strategies[j])] = [value(ltr_is_fn_mean[j][i]) for i in 1:number_of_days]
    end

    p2 = plot(title="Total # hate posts left to review (FN)")
    for (key, value) in fn_dict
         p2 = plot!(value, label=key)
    end
    #    display(p2)
    p = plot(p1, p2, layout=(2, 1))
    savefig("output/plot_$(run_id).png")
    p

    # print the status of the image generation 
    @info "Simulation completed. Results saved to output/plot_$(run_id).png"
end

