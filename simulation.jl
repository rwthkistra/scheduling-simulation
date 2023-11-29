using Agents
using Random
using Distributions
using Plots
using ProgressMeter

include("scheduling_strategies.jl")
include("settings.jl")

# Structure dataype for out posts
Base.@kwdef mutable struct Post
    id::Int
    created_at::Int
    reviewed_at::Int
    is_hate::Bool
    kistra_is_hate::Bool
    kistra_confidence::Float64
    kistra_fp::Bool
    kistra_fn::Bool
    reports::Int
end


mutable struct Employee
    capacity::Int
end

#global id_count = 0
function generate_posts(num_posts, max_id, day, rng)
    local_id_count = max_id
    posts = Vector{Post}()
    for i in 1:rand(rng, 1:num_posts)
        local_id_count = local_id_count + 1
        is_hate = rand(rng, hate_dist)
        new_post = Post(
            id=local_id_count,
            created_at=day,
            is_hate=is_hate,
            kistra_is_hate=false,
            kistra_confidence=0.0,
            reports=0,
            kistra_fp=false,
            kistra_fn=false,
            reviewed_at=-1
        )
        push!(posts, new_post)
    end
    return posts
end

function flag_posts_as_reported!(posts, rng)
    for post in posts
        if rand(rng, reporting_dist_overall) 
            post.reports = 1
            @debug "Post reported" post.id
        end
    end
end

function classify_posts_by_kistra!(posts, conf_matrix, rng)
    for post in posts
        # temp initialize
        probability = 0.0
        if post.is_hate
            probability = conf_matrix[1, 1]
        else
            probability = conf_matrix[2, 2]
        end

        guess = rand(rng, Bernoulli(probability)) # = liegt der Klassifikator richtig?

        if guess
            post.kistra_is_hate = post.is_hate
            #@debug "Kistra is right" post.id
        else
            post.kistra_is_hate = !post.is_hate
            post.kistra_fp = !post.is_hate
            post.kistra_fn = post.is_hate
        end
    end
end

function sort_posts_by_scheduling_strategy!(posts, strategy_functions, rng)
    queues = Vector{Vector{Post}}()
    #debug
    #fifo(posts,rng)
    for strategy_function in strategy_functions
        queue = strategy_function(posts, rng)
        push!(queues, queue)
    end
    return merge_n_queues!(queues)
end


function assign_posts_to_employees(posts, post_capacity, all_posts, day)
    # length or post_capacity, whichever is smaller
    num_posts_to_assign = min(length(posts), post_capacity)
    # List of post ids that have been assigned to employees
    post_ids = [post.id for post in posts[1:num_posts_to_assign]]
    review_delay = Vector{Int}()
    is_hate = Vector{Int}()
    fp_delay = Vector{Int}()
    fn_delay = Vector{Int}()
    # Flag posts as reviewed in all_posts
    for post in all_posts
        if post.id in post_ids
            post.reviewed_at = day
            if post.is_hate
                push!(is_hate, post.id)
            end
            if post.kistra_fn
                push!(fn_delay, post.reviewed_at - post.created_at)
            end
            if post.kistra_fp
                push!(fp_delay, post.reviewed_at - post.created_at)
            end
            push!(review_delay, post.reviewed_at - post.created_at)
        end
    end
    return (posts[post_capacity+1:end], is_hate, fn_delay, fp_delay)
end


#=
1. Post wird erstellt
2. Post wird mit 2% Wahrscheinlichkeit reported
3. Post wird klassifiziert durch Kistra
4. Post landet in Queue (FIFO, Kistra, FIFO + Kistra, FIFO + Kistra +Random)
5. Post wird von Mitarbeiter bearbeitet
=#


#  -> Post wird ggf. reported (10% Chance)

function simulate(
    number_of_employees=1,
    num_posts_per_day=400,
    reviews_per_day = 400,
    number_of_days=31,
    confusion_matrix=kistra_conf_matrix,
    scheduling_strategy_functions=[kistra],
    seed=99
)
    rng = Xoshiro(seed)
    # Initialize simulation parameters
    all_posts = Vector{Post}()
    left_to_review = Vector{Post}()

    @debug "Simulating $number_of_days days with $number_of_employees employees"
    post_capacity = number_of_employees * reviews_per_day

    ltr_ih = Vector{Int}()
    ltr_ifn = Vector{Int}()
    ltr_ifp = Vector{Int}()
    reviewed_hate = Vector{Int}()
    reviewed_fp_delay = Vector{Int}()
    reviewed_fn_delay = Vector{Int}()
    max_id = 0

    for day in 1:number_of_days
        @debug "Day: $day"
        #day = 1

        # Generate posts for the day based on the scheduling strategy
        posts = generate_posts(num_posts_per_day, max_id, day, rng)
        max_id = posts[end].id
        @debug "Number of posts generated: $(length(posts))"
        # Add posts to the list of all posts
        push!(all_posts, posts...)

        # Flag posts as reported based on the reporting probability
        flag_posts_as_reported!(posts, rng)
        @debug filter(post -> post.reports > 0, posts)

        # Classify posts using the AI
        classify_posts_by_kistra!(posts, confusion_matrix, rng)

        # Add posts to the list of posts left to review from previous days
        push!(posts, left_to_review...)
        @debug "Number of posts to review: $(length(posts))"

        # Sort posts based on the scheduling strategy
        posts = sort_posts_by_scheduling_strategy!(posts, scheduling_strategy_functions, rng)
        @debug "Which post ids are there in which order" [post.id for post in posts]
        @debug "How much hate in posts:" sum([post.is_hate for post in posts])
        # Assign posts to employees for review
        left_to_review, is_hate, fn_delay, fp_delay = assign_posts_to_employees(
            posts,
            post_capacity,
            all_posts,
            day
        )
        @debug is_hate
        @debug left_to_review
        @debug fn_delay
        @debug fp_delay
        # How many posts are left to review and is_hate
        left_to_review_and_is_hate = [post.is_hate for post in left_to_review]
        left_to_review_and_is_fn = [post.kistra_fn for post in left_to_review]
        left_to_review_and_is_fp = [post.kistra_fp for post in left_to_review]
        push!(ltr_ih, sum(left_to_review_and_is_hate))
        push!(ltr_ifn, sum(left_to_review_and_is_fn))
        push!(ltr_ifp, sum(left_to_review_and_is_fp))

        push!(reviewed_hate, length(is_hate))
        push!(reviewed_fn_delay, sum(fn_delay))
        push!(reviewed_fp_delay, sum(fp_delay))
        @debug "Number of posts left to review: $(length(left_to_review))"
    end

    # Plot the number of posts left to review that are hate
    return (ltr_ih, reviewed_hate, reviewed_fn_delay, ltr_ifn, ltr_ifp)
end
