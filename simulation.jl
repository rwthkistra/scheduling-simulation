using Agents
using Random
using Distributions
using Plots

include("scheduling_strategies.jl")

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



# Constant distributions and values
opinion_dist = Uniform(-1, 1)
hate_dist = Bernoulli(0.05) # 10 Prozent ist hate
reporting_dist_non_hate = Exponential(0.5) # wenige Meldungen 
reporting_dist_hate = Exponential(1.5)
prob_to_report = 0.2
kistra_conf_matrix = [[0.7, 0.3] [1, 0]]
REVIEWS_PER_DAY = 400

mutable struct Employee
    capacity::Int
end

global id_count = 0
function generate_posts(num_posts, day, rng)
    posts = Vector{Post}()
    for i in 1:rand(rng, 1:num_posts)
        global id_count = id_count + 1
        is_hate = rand(rng, hate_dist)
        new_post = Post(
            id=id_count,
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
        if rand(rng) < prob_to_report
            post.reports = 1
        end
    end
end

function classify_posts_by_kistra!(posts, conf_matrix, rng)
    for post in posts
        probability = 0.0
        if post.is_hate
            probability = conf_matrix[1, 1]
        else
            probability = conf_matrix[2, 2]
        end

        guess = rand(rng, Bernoulli(probability)) # = liegt der Klassifikator richtig?

        if guess
            post.kistra_is_hate = post.is_hate
        else
            post.kistra_is_hate = !post.is_hate
            post.kistra_fp = !post.is_hate
            post.kistra_fn = post.is_hate
        end
    end
end

function sort_posts_by_scheduling_strategy!(posts, strategy_functions, rng)
    queues = Vector{Vector{Post}}()
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
    number_of_employees,
    num_posts_per_day,
    number_of_days=31,
    confusion_matrix=kistra_conf_matrix,
    scheduling_strategy_functions=[fifo],
    seed=99
)
    rng = Xoshiro(seed)
    # Initialize simulation parameters
    all_posts = Vector{Post}()
    left_to_review = Vector{Post}()

    post_capacity = number_of_employees * REVIEWS_PER_DAY

    ltr_ih = Vector{Int}()
    ltr_ifn = Vector{Int}()
    ltr_ifp = Vector{Int}()
    reviewed_hate = Vector{Int}()
    reviewed_fp_delay = Vector{Int}()
    reviewed_fn_delay = Vector{Int}()

    for day in 1:number_of_days
        # println("Day: $day")
        # Generate posts for the day based on the scheduling strategy
        posts = generate_posts(num_posts_per_day, day, rng)
        # Add posts to the list of all posts
        push!(all_posts, posts...)

        # Flag posts as reported based on the reporting probability
        flag_posts_as_reported!(posts, rng)

        # Classify posts using the AI
        classify_posts_by_kistra!(posts, confusion_matrix, rng)

        # Add posts to the list of posts left to review from previous days
        push!(posts, left_to_review...)

        # Sort posts based on the scheduling strategy
        posts = sort_posts_by_scheduling_strategy!(posts, scheduling_strategy_functions, rng)
        # Assign posts to employees for review
        left_to_review, is_hate, fn_delay, fp_delay = assign_posts_to_employees(
            posts,
            post_capacity,
            all_posts,
            day
        )
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
        # println("Number of posts left to review: $(length(left_to_review))")
    end

    # Plot the number of posts left to review that are hate
    return (ltr_ih, reviewed_hate, reviewed_fn_delay, ltr_ifn, ltr_ifp)
end
