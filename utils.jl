
"""
    confusionmatrix(alpha_error, beta_error)

Compute the confusion matrix given the alpha error and beta error.

# Arguments
- `alpha_error::Float64`: The alpha error rate.
- `beta_error::Float64`: The beta error rate.

# Returns
- `Matrix{Float64}`: The confusion matrix.

"""
function confusionmatrix(alpha_error, beta_error)
    [[1-alpha_error, alpha_error] [beta_error, 1-beta_error]]
end

"""
    plotconfusionmatrix(m, filename="output/kistra_conf_matrix.png")

Plot the confusion matrix `m` and save it as an image file.

Arguments:
- `m`: The confusion matrix to plot.
- `filename`: (optional) The filename to save the image as. Default is "output/kistra_conf_matrix.png".
"""
function plotconfusionmatrix(m, filename="output/kistra_conf_matrix.png")
    
    z = [["TP ", "FP "] ["FN ", "TN "]] .* string.(m)
    heatmap(m, title="Kistra Confusion Matrix", 
        xlabel="Kistra Classification", ylabel="Ground Truth", 
        xticks=([1, 2], ["Hate", "Non-Hate"]), 
        yticks=([1, 2], ["Hate", "Non-Hate"]),
        xflip=false, 
        yflip=true,
        clim=(0,1)
        )
    annotate!(vec(tuple.((1:2)' .- 0.01, (1:2) .- 0.01, string.(z), :green)))
    savefig(filename)
end

#plotconfusionmatrix(confusionmatrix(0.3, 0.1), "output/kistra_conf_matrix_3_1.png")


