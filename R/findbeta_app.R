library(shiny)
library(ggplot2)
library(bslib)
library(tidyverse)
library(readxl)

testdaten <- read_excel("../data/Testdaten.xlsx")
mdf <- testdaten %>% mutate(score = as.numeric(score)) %>% 
  mutate(gold_label = as.bool(gold_label),
         label = as.bool(label)) %>% 
  mutate(hate_score = ifelse(label == FALSE, 1 - score, score))

ui <- page_sidebar(
  title = "Beta Distribution Sampler",
  sidebar = sidebar(
    title = "Parameters",
    
    sliderInput("n", 
                "Number of samples (N):", 
                min = 10, 
                max = 1000, 
                value = 100,
                step = 10),
    
    sliderInput("alpha", 
                "Alpha value:", 
                min = 0.01,  # Avoiding exactly 0 as it's problematic for beta distribution
                max = 1, 
                value = 0.5, 
                step = 0.01),
    
    sliderInput("beta", 
                "Beta value:", 
                min = 0.01,  # Avoiding exactly 0 as it's problematic for beta distribution
                max = 1, 
                value = 0.5, 
                step = 0.01)
  ),
  
  card(
    card_header("Beta Distribution Histogram"),
    card_body(
      plotOutput("histogram")
    ),
    card_footer(
      "The histogram shows the frequency distribution of samples drawn from the Beta distribution."
    )
  ),
  
  card(
    card_header("Value Distribution"),
    card_body(
      textOutput("count_below"),
      textOutput("count_above"),
      textOutput("percentage_below"),
      textOutput("percentage_above"),
      textOutput("test_result")
    ),
    card_footer(
      "Counts and percentages of values above and below 0.5."
    )
  ),
  
  card(
    card_header("About the Beta Distribution"),
    card_body(
      p("The Beta distribution is a continuous probability distribution defined on the interval [0, 1]."),
      p("It is parameterized by two positive shape parameters, alpha (α) and beta (β), that control the shape of the distribution."),
      p("When both α and β are less than 1, the distribution is U-shaped or has high density at 0 and 1.")
    )
  )
)

server <- function(input, output, session) {
  
  # Generate samples reactively based on inputs
  samples <- reactive({
    # Set seed for reproducibility within each parameter setting
    set.seed(123)
    rbeta(input$n, shape1 = input$alpha, shape2 = input$beta)
  })
  
  # Calculate counts above and below 0.5
  counts <- reactive({
    current_samples <- samples()
    below_count <- sum(current_samples < 0.5)
    above_count <- sum(current_samples >= 0.5)
    below_percent <- below_count / input$n * 100
    above_percent <- above_count / input$n * 100
    
    list(
      below_count = below_count,
      above_count = above_count,
      below_percent = below_percent,
      above_percent = above_percent
    )
  })
  
  # Display counts
  output$count_below <- renderText({
    paste("Number of values below 0.5:", counts()$below_count)
  })
  
  output$count_above <- renderText({
    paste("Number of values above or equal to 0.5:", counts()$above_count)
  })
  
  output$percentage_below <- renderText({
    paste("Percentage below 0.5:", round(counts()$below_percent, 2), "%")
  })
  
  output$percentage_above <- renderText({
    paste("Percentage above or equal to 0.5:", round(counts()$above_percent, 2), "%")
  })
  
  # Render the histogram
  output$histogram <- renderPlot({
    # Get the current samples
    current_samples <- samples()
    
    # Calculate binwidth based on sample size and range
    binwidth <- 0.05
    
    ggplot(data.frame(x = current_samples), aes(x = x)) +
      geom_histogram(binwidth = binwidth, fill = "steelblue", color = "white", alpha = 0.7) +
      # Add a vertical line at x = 0.5
      geom_vline(xintercept = 0.5, linetype = "dashed", color = "red", size = 1) +
      labs(
        title = paste0("Histogram of Beta(", input$alpha, ", ", input$beta, ") Distribution"),
        subtitle = paste("N =", input$n, "samples"),
        x = "Value",
        y = "Frequency"
      ) +
      theme_minimal() +
      theme(
        plot.title = element_text(face = "bold"),
        axis.title = element_text(face = "bold")
      )
  })
  
  output$test_result <- renderText({
    current_samples <- samples()
    res <- ks.test(mdf$hate_score %>% unique(), "pbeta", input$alpha, input$beta)
    paste("D", res$statistic, "p", res$p.value)
  })
  
}

shinyApp(ui, server)
