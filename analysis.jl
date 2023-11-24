using OnlineStats

include("simulation.jl")

n = 4
number_of_days = 365
confusion_matrix = [[0.7, 0.3] [0.1, 0.9]]
params = (2, 1600, number_of_days, confusion_matrix)

ltr_mean = [
    [Series(Mean()) for _ in 1:number_of_days],
    [Series(Mean()) for _ in 1:number_of_days],
    [Series(Mean()) for _ in 1:number_of_days],
    [Series(Mean()) for _ in 1:number_of_days],
    [Series(Mean()) for _ in 1:number_of_days],
]
r_mean = [
    [Series(Mean()) for _ in 1:number_of_days],
    [Series(Mean()) for _ in 1:number_of_days],
    [Series(Mean()) for _ in 1:number_of_days],
    [Series(Mean()) for _ in 1:number_of_days],
    [Series(Mean()) for _ in 1:number_of_days],
]

ltr_is_fn_mean = [
    [Series(Mean()) for _ in 1:number_of_days],
    [Series(Mean()) for _ in 1:number_of_days],
    [Series(Mean()) for _ in 1:number_of_days],
    [Series(Mean()) for _ in 1:number_of_days],
    [Series(Mean()) for _ in 1:number_of_days],
]



@time Threads.@threads for i in 1:n
    ltr = []
    r = []
    ltr_fn = []

    ltr_1, r_1, _, ltr_fn_1 = simulate(params..., [
            fifo,
        ], i)
    push!(ltr, ltr_1)
    push!(r, r_1)
    push!(ltr_fn, ltr_fn_1)

    ltr_2, r_2, _, ltr_fn_2 = simulate(params..., [
            fifo,
            kistra,
        ], i)
    push!(ltr, ltr_2)
    push!(r, r_2)
    push!(ltr_fn, ltr_fn_2)

    ltr_3, r_3, _, ltr_fn_3 = simulate(params..., [
            fifo,
            kistra,
            deterministic_shuffle,
        ], i)
    push!(ltr, ltr_3)
    push!(r, r_3)
    push!(ltr_fn, ltr_fn_3)


    ltr_4, r_4, _, ltr_fn_4 = simulate(params..., [
            fifo,
            deterministic_shuffle,
        ], i)
    push!(ltr, ltr_4)
    push!(r, r_4)
    push!(ltr_fn, ltr_fn_4)

    ltr_5, r_5, _, ltr_fn_5 = simulate(params..., [
            kistra,
        ], i)
    push!(ltr, ltr_5)
    push!(r, r_5)
    push!(ltr_fn, ltr_fn_5)


    for j in 1:5
        for k in 1:number_of_days
            fit!(ltr_mean[j][k], ltr[j][k])
            fit!(r_mean[j][k], r[j][k])
            fit!(ltr_is_fn_mean[j][k], ltr_fn[j][k])
        end
    end
end

s1_ltr = [
    value(ltr_mean[1][i]) for i in 1:number_of_days
]
s2_ltr = [
    value(ltr_mean[2][i]) for i in 1:number_of_days
]
s3_ltr = [
    value(ltr_mean[3][i]) for i in 1:number_of_days
]

s4_ltr = [
    value(ltr_mean[4][i]) for i in 1:number_of_days
]

s5_ltr = [
    value(ltr_mean[5][i]) for i in 1:number_of_days
]

p1 = plot(s1_ltr, label="F", title="# posts LTR and H")
plot!(s2_ltr, label="F + K")
plot!(s3_ltr, label="F + K + R")
plot!(s4_ltr, label="F + R")
plot!(s5_ltr, label="K")

#=
s1_r = [
    value(r_mean[1][i]) for i in 1:number_of_days
]
s2_r = [
    value(r_mean[2][i]) for i in 1:number_of_days
]
s3_r = [
    value(r_mean[3][i]) for i in 1:number_of_days
]

s4_r = [
    value(r_mean[4][i]) for i in 1:number_of_days
]

s5_r = [
    value(r_mean[5][i]) for i in 1:number_of_days
]

p2 = plot(s1_r, label="F", title="# posts R and H")
plot!(s2_r, label="F + K",)
plot!(s3_r, label="F + K + R")
plot!(s4_r, label="F + R")
plot!(s5_r, label="K")
=#

s1_fn = [
    value(ltr_is_fn_mean[1][i]) for i in 1:number_of_days
]
s2_fn = [
    value(ltr_is_fn_mean[2][i]) for i in 1:number_of_days
]
s3_fn = [
    value(ltr_is_fn_mean[3][i]) for i in 1:number_of_days
]
s4_fn = [
    value(ltr_is_fn_mean[4][i]) for i in 1:number_of_days
]
s5_fn = [
    value(ltr_is_fn_mean[5][i]) for i in 1:number_of_days
]

p3 = plot(s1_fn, label="F", title="# posts LTR and FN")
plot!(s2_fn, label="F + K")
plot!(s3_fn, label="F + K + R")
plot!(s4_fn, label="F + R")
plot!(s5_fn, label="K")

plot(p1, p3, layout=(2, 1))
