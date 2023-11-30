using OnlineStats
using Logging

debuglogger = ConsoleLogger(stderr, Logging.Debug)
#global_logger(debuglogger)

include("simulation.jl")
include("scheduling_strategies.jl")


function runsim(;replications=1,
    number_of_days=365,
    confusion_matrix=confusionmatrix(0.3, 0.1),
    workers=1,
    posts_per_day=100,
    post_count=200,
    run_id="001")


    # generate params object
    params = (workers, post_count, posts_per_day, number_of_days, confusion_matrix)

    mkpath("output")
    plotconfusionmatrix(confusion_matrix, "output/kistra_conf_matrix_$(run_id).png")



    @debug "Preparing simulation" params
 
    strategies = Vector{Vector{Function}}()
    push!(strategies, [fifo])
    push!(strategies, [kistra])
    push!(strategies, [fifo, kistra])
    push!(strategies, [fifo, kistra, deterministic_shuffle])
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
end

#runsim()