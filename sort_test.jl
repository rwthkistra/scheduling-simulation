q1 = [
    Post(id = 1, timestamp = 1, is_hate = true, kistra_classification = true, reports = 0),
    Post(id = 2, timestamp = 2, is_hate = false, kistra_classification = false, reports = 0),
    Post(id = 3, timestamp = 3, is_hate = false, kistra_classification = true, reports = 0),
    Post(id = 4, timestamp = 4, is_hate = true, kistra_classification = false, reports = 0),
    Post(id = 5, timestamp = 5, is_hate = true, kistra_classification = true, reports = 0),
]

q2 = [
    Post(id = 5, timestamp = 5, is_hate = true, kistra_classification = true, reports = 0),
    Post(id = 1, timestamp = 1, is_hate = true, kistra_classification = true, reports = 0),
    Post(id = 3, timestamp = 3, is_hate = false, kistra_classification = true, reports = 0),
    Post(id = 2, timestamp = 2, is_hate = false, kistra_classification = false, reports = 0),
    Post(id = 4, timestamp = 4, is_hate = true, kistra_classification = false, reports = 0),
]

q3 = [
    Post(id = 1, timestamp = 1, is_hate = true, kistra_classification = true, reports = 0),
    Post(id = 5, timestamp = 5, is_hate = true, kistra_classification = true, reports = 0),
    Post(id = 2, timestamp = 2, is_hate = false, kistra_classification = false, reports = 0),
    Post(id = 3, timestamp = 3, is_hate = false, kistra_classification = true, reports = 0),
    Post(id = 4, timestamp = 4, is_hate = true, kistra_classification = false, reports = 0),
]

q4 = merge_n_queues!([q1, q2, q3])

