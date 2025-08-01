library(tidyverse)
library(readxl)


testdaten <- read_excel("data/Testdaten.xlsx")

bootstrap_dataframe <- testdaten %>% 
  mutate(label = ifelse(label == "True", TRUE, FALSE)) %>%
  mutate(confidence = as.numeric(score)) %>% 
  mutate(ground_truth = ifelse(gold_label == "True", TRUE, FALSE)) %>% 
  mutate(hate_score = ifelse(label == FALSE, 1 - confidence, confidence)) %>%
  select(-c("ID", "gold_label", "score"))


write_csv(bootstrap_dataframe, "data/bootstrap_dataframe.csv")

bootstrap_dataframe %>% sample_n(10000, replace = TRUE) %>% 
  ggplot(aes(x = hate_score, fill = label)) + geom_histogram()

conf_true  <- testdaten %>% filter(gold_label == "True") %>% pull(score) %>% as.numeric()
conf_false <- testdaten %>% filter(gold_label == "False") %>% pull(score) %>% as.numeric()

conf_fp <- testdaten %>% filter(gold_label == "False") %>% filter(cm_val == "fp") %>% pull(score) %>% as.numeric() 
conf_tp <- testdaten %>% filter(gold_label == "True") %>% filter(cm_val == "tp") %>% pull(score) %>% as.numeric() 

conf_tn <- testdaten %>% filter(gold_label == "False") %>% filter(cm_val == "tn") %>% pull(score) %>% as.numeric() 
conf_fn <- testdaten %>% filter(gold_label == "True") %>% filter(cm_val == "fn") %>% pull(score) %>% as.numeric() 


testdaten %>% 
  filter(label == "True") %>% nrow()

# The following code is used to infer the value of the confidence threshold using Bayes' theorem.
# infer the value of the confidence threshold using bayes theorem
t.test(conf_fp, conf_tp)
t.test(conf_fn, conf_tn)



hist(conf_true, breaks = 50)
hist(conf_false, breaks = 50)



library(pROC)
library(ggplot2)

# Assuming you have two vectors:
# y_true: a binary vector of ground truth labels (0/1 or FALSE/TRUE)
# y_score: a numeric vector of predicted scores from your classifier

# Example dummy data
# y_true <- c(TRUE, FALSE, TRUE, TRUE, FALSE)
# y_score <- c(0.9, 0.4, 0.8, 0.7, 0.1)


as.bool <- function(x) {
  ifelse(x == "True", TRUE, FALSE)
}
# Compute ROC
roc_obj <- roc(as.bool(testdaten$gold_label), as.numeric(testdaten$score))

# Print AUC
auc_value <- auc(roc_obj)
print(paste("AUC:", auc_value))

# Plot ROC curve
ggroc(roc_obj, color = "blue", size = 1.2) +
  geom_abline(slope = 1, intercept = 0, linetype = "dashed", color = "gray") +
  ggtitle(paste("ROC Curve (AUC =", round(auc_value, 2), ")")) +
  theme_minimal()

mdf <- testdaten %>% mutate(score = as.numeric(score)) %>% 
  mutate(gold_label = as.bool(gold_label),
         label = as.bool(label)) %>% 
  mutate(hate_score = ifelse(label == FALSE, 1 - score, score))

roc_obj <- roc(mdf$gold_label, mdf$hate_score)
# Print AUC
auc_value <- auc(roc_obj)
print(paste("AUC:", auc_value))

# Plot ROC curve
ggroc(roc_obj, color = "blue", size = 1.2) +
  geom_abline(slope = 1, intercept = 0, linetype = "dashed", color = "gray") +
  ggtitle(paste("ROC Curve (AUC =", round(auc_value, 2), ")")) +
  theme_minimal()

mdf %>% ggplot() +
  aes(x = hate_score, fill = label) +
  facet_wrap(~ gold_label, ncol = 1, scale = "free_y") +
  geom_histogram()

# what does this code do?
#
plot(pbeta(conf_fp, conf_tp, conf_fn, conf_tn, lower.tail = TRUE))


# BETA Version ----

alpha = 0.035
beta = 0.19
sim_data <- rbeta(100000, alpha, beta) %>% tibble(value = .) %>% mutate(label = ifelse(value < 0.5, FALSE, TRUE))
sim_data %>% filter(value > 0.5) %>% nrow()
sim_data %>% ggplot() + aes(value, fill = label) + geom_histogram()
mdf %>% ggplot() + aes(hate_score, fill = label) + geom_histogram()

combined_data <- bind_rows(
  sim_data %>% mutate(source = "simulated"),
  mdf %>% select(value = hate_score, label) %>% mutate(source = "mdf")
)

combined_data %>% 
  ggplot() + 
  aes(value, fill = label) + 
  geom_histogram(position = "identity", alpha = 0.5, bins = 50) +
  facet_wrap(~ source, scales = "free_y") +
  labs(title = "Histogram of Scores from Simulated and MDF Data",
       x = "Score",
       y = "Count") +
  theme_minimal()

ks.test(sim_data$value %>% unique(), "pbeta", alpha, beta)
ks.test(mdf$hate_score %>% unique(), "pbeta", alpha, beta)

# EXPONTENTIAL ----
# test parameters using mle to find distribution parameters
library(EnvStats)

ebeta(mdf$hate_score, method = "mle")


# two exponentials aligned

mdf %>% filter(hate_score < 0.5) %>% pull(hate_score) %>% 
  eexp(method = "mle")

mdf %>% filter(hate_score > 0.5) %>% 
  mutate(hate_score = 1 - hate_score) %>% 
  pull(hate_score) %>% 
  eexp(method = "mle")


non_hate <- rexp(n = 877, rate = 49.72)
hate <- 1 - rexp(n = 123, rate = 14.95)

new_sim <- data.frame(
  hate_score = c(non_hate, hate),
  label = c(rep(FALSE, length(non_hate)), rep(TRUE, length(hate)))
)

new_sim %>% ggplot() + aes(x = hate_score, fill = label) + 
  geom_histogram(position = "identity", alpha = 0.5, bins = 50) +
  labs(title = "Histogram of Simulated Hate Scores",
       x = "Hate Score",
       y = "Count") +
  theme_minimal()

ks.test(mdf$hate_score, new_sim$hate_score, alternative = "two.sided")

eexp(mdf$hate_score, method = "mle")




# bootstrapped sampling ----

mdf$hate_score
boots <- sample(mdf$hate_score, size = 100000, replace = TRUE)

boots_df <- data.frame(hate_score = boots) %>% 
  mutate(label = ifelse(hate_score < 0.5, FALSE, TRUE))

boots_df %>% ggplot() + aes(x = hate_score, fill = label) + 
  geom_histogram(position = "identity", alpha = 0.5, bins = 50) +
  labs(title = "Histogram of Bootstrapped Hate Scores",
       x = "Hate Score",
       y = "Count") +
  theme_minimal()

ks.test(boots_df$hate_score, mdf$hate_score, alternative = "two.sided")


sim_data %>% ggplot() + aes(x = value, fill = label) + 
  geom_histogram(position = "identity", alpha = 0.5, bins = 50) +
  labs(title = "Histogram of beta simulated Hate Scores",
       x = "Hate Score",
       y = "Count") +
  theme_minimal()
