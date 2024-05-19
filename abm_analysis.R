library(tidyverse)
library(scales)
library(gridExtra)

setwd(r"{D:\My Studies\Strathclyde\Semester 2\MS986 Stochastic Modelling for Analytics\ABM Assignment\My Assignment}")

data <- read.csv("increased-friend-lending-prob-experiment-table.csv",
                 skip = 6)

colnames(data)

data <- data %>%
  rename(run = `X.run.number.`, month = `X.step.`, 
         annual_interest_rate = `annual.interest.rate`,
         number_of_borrowers = `number.of.borrowers`,
         friend_lending_probability = `friend.lending.probability`,
         max_loan_amount = `max.loan.amount`,
         default_rate = `get.default.rate`,
         number_of_defaulters = `get.defaulters`,
         mean_balance = `mean..balance..of.borrowers`,
         mean_credit_score = `mean..credit.score..of.borrowers`,
         mean_debt = `mean..debt..of.borrowers`,
         mean_income = `mean..income..of.borrowers`)

data_avg <- data %>% group_by(annual_interest_rate , month) %>%
  summarise(default_rate = mean(default_rate),
            number_of_defaulters = mean(number_of_defaulters),
            mean_balance = mean(mean_balance),
            mean_credit_score = mean(mean_credit_score),
            mean_debt = mean(mean_debt),
            mean_income = mean(mean_income))

fig1 <- ggplot(data = data_avg %>%
                 gather(key = "variable", value = "value", default_rate:mean_income)) +
  facet_grid(variable~., scales = "free") +
  geom_line(aes(x = month, y = value, color = month), size = 1.5) +
  scale_y_continuous(name = "", limits = c(0, NA), expand = c(0,0)) +
  scale_x_continuous(name = "Month", expand = c(0,0)) +
  theme_gray() +
  theme(legend.position = "bottom", legend.title = element_blank(),
        text = element_text(size = 26))