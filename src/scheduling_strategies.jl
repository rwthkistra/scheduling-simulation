using Logging

# naive scheduling strategies

function fifo(posts, rng)
    return sort(posts, by = post -> post.created_at)
end

function kistra(posts, rng)

    #return sort(posts, by = post -> !post.kistra_is_hate)
    return sort(posts, by = post -> post.kistra_confidence, rev = true)
end

function deterministic_shuffle(posts, rng)
    return shuffle(rng, posts)
end




#TODO: Generalize the method below to any type of queue

"""
    merge_n_queues!(queues)

    This method merges queues into one queue using zipper method.
    Items in queues may be duplicated but are used only once in the final queue.

    Items must have an id property of type Int.
    All queues must have the same length.
"""
function merge_n_queues!(queues)
    # Implementation to merge n queues
    queue = Vector{Post}()
    # The items in the different queues are duplicated but sorted
    # based on differnt properties
    # We want to merge the queues based on the id of the post
    # We can use a hash set to keep track of the posts we have already added
    # to the merged queue
    
    # keeps track of ids
    added_ids = Set{Int}()

    # how many queues
    count_queues = length(queues)
    @debug "Merging $count_queues queues"

    if count_queues == 0
        return queue
    end

    # keeps track of the index of the current post in each queue
    index_array = [1 for _ in 1:count_queues]

    # The current queue we are taking posts from
    cur_queue_id = 1
    while true
        # Check if we have added all posts to the merged queue
        # TODO: we could change this to test if queues are empty
        if length(added_ids) == length(queues[1])
            break
        end

        # Find the next post to add to the merged queue
        next_post = nothing

        # Check if we have reached the end of the current queue
        if index_array[cur_queue_id] <= length(queues[cur_queue_id])
            # get the next post from the current queue at current index
            next_post = queues[cur_queue_id][index_array[cur_queue_id]]
            # println("Next post: $(next_post.id)")
        end

        # Check if we have already added the post to the merged queue
        if next_post.id in added_ids
            # println("Post already in queue -id method")
            if next_post in queue
                # this could help generalize the method
                # currently it does nothing
                # println("Post already in queue -generic method")
            end
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
