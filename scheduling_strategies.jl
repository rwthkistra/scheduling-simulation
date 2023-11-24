function fifo(posts, rng)
    return sort(posts, by = post -> post.created_at)
end

function kistra(posts, rng)
    return sort(posts, by = post -> !post.kistra_is_hate)
end

function deterministic_shuffle(posts, rng)
    return shuffle(rng, posts)
end

function merge_n_queues!(queues)
    # Implementation to merge n queues
    queue = Vector{Post}()
    # The items in the different queues are duplicated but sorted
    # based on differnt properties
    # We want to merge the queues based on the id of the post
    # We can use a hash set to keep track of the posts we have already added
    # to the merged queue
    
    added_ids = Set{Int}()
    count_queues = length(queues)
    index_array = [1 for _ in 1:count_queues]
    cur_queue_id = 1
    while true
        if length(added_ids) == length(queues[1])
            break
        end

        # Find the next post to add to the merged queue
        next_post = nothing
        if index_array[cur_queue_id] <= length(queues[cur_queue_id])
            next_post = queues[cur_queue_id][index_array[cur_queue_id]]
            # println("Next post: $(next_post.id)")
        end

        # Check if we have already added the post to the merged queue
        if next_post.id in added_ids
            # If we have already added the post to the merged queue
            # we just increase the index of the queue we took the post from
            index_array[cur_queue_id] += 1
            continue
        end

        # Add the post to the merged queue
        push!(queue, next_post)
        push!(added_ids, next_post.id)
        index_array[cur_queue_id] += 1
        cur_queue_id = (cur_queue_id % count_queues) + 1
    end
    return queue
end
