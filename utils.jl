"""
    confusionmatrix(alpha_error, beta_error)

    generates a confusion matrix with the given error rates
"""
function confusionmatrix(alpha_error, beta_error)
    [[1-alpha_error, alpha_error] [beta_error, 1-beta_error]]
end

function plotconfusionmatrix(m, filename="output/kistra_conf_matrix.png")
    
    z = [["TP ", "FP "] ["FN ", "TN "]] .* string.(m)
    heatmap(kistra_conf_matrix, title="Kistra Confusion Matrix", 
        xlabel="Kistra Classification", ylabel="Ground Truth", 
        xticks=([1, 2], ["Hate", "Non-Hate"]), 
        yticks=([1, 2], ["Hate", "Non-Hate"]),
        xflip=false, 
        yflip=true
        )
    annotate!(vec(tuple.((1:2)' .- 0.01, (1:2) .- 0.01, string.(z), :green)))
    savefig(filename)
end