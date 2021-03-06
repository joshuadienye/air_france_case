######################################
#Created by Team 16 on 12/12/2020
#Business Case Assignment
#Cohort: MSBA 4
#Members: Haoxuan Chang
#         Garun Chaudhary
#         Joshua Dienye
#         Bhawesh Parmar
######################################

# calling necessary libraries
library(dplyr)
library(readxl)
library(ggplot2)
library(plotly)
library(tidyr)
library(scales)
library(flexdashboard)

# reading the dataset and calling it air_france
air_france <- read_excel("Air France Case Spreadsheet Supplement.xlsx", 
                                                     sheet = "DoubleClick")
kayak <- read_excel("Air France Case Spreadsheet Supplement.xlsx", 
                    sheet = "Kayak")

# checking which columns have missing values
colSums(is.na(air_france))
# bid strategy has 1224 missing values so we decided to remove that column entirely

# selecting only the  columns we deemed useful and changing the percentages to decimals
air_france <- air_france %>%
  select(`Publisher Name`, `Match Type`, Campaign, `Search Engine Bid`, 
         Clicks, `Click Charges`, `Avg. Cost per Click`, 
         Impressions, `Engine Click Thru %`, `Avg. Pos.`, `Trans. Conv. %`, 
         `Total Cost/ Trans.`, Amount, `Total Cost`, 
         `Total Volume of Bookings`) %>%
  mutate(`Engine Click Thru %` = `Engine Click Thru %`/100, 
         `Trans. Conv. %` = `Trans. Conv. %`/100)

# renaming the columns 
colnames(air_france) <- c("publisher_name", "match_type", "campaign", 
                              "search_ebid", "clicks", "click_charges", 
                              "avg_cost_p_click", "impressions", 
                              "eng_click_thru_rate", "avg_pos", "trans_conv_rate", 
                              "total_cost_per_trans", "amount", "total_cost", 
                              "total_v_bookings")

#create the new variables that we will use as KPIs
air_france$probability_of_action <- round(air_france$eng_click_thru_rate * 
                                            air_france$trans_conv_rate,
                                          digits = 4)
air_france$net_revenue <- air_france$amount - air_france$total_cost
air_france$ROA <- air_france$amount / air_france$total_cost

# deleting row with infinite value
air_france <- air_france[-338, ]

# making publisher names factors and saving it to new table called publishers
# we decided to collapse global and US for each publisher into one publisher
# since the difference is not required for this analysis
air_france$publishers <- factor(x = air_france$publisher_name, 
                                levels = c("Google - Global", "Google - US",
                                           "MSN - Global", "MSN - US",
                                           "Overture - Global", "Overture - US",
                                           "Yahoo - US"), 
                                labels = c("Google","Google", "MSN", "MSN", 
                                           "Overture", "Overture", "Yahoo"))

##########################################################
##########################################################
#CONSTRUCTING CHARTS
##########################################################
##########################################################

# constructing chart of cost per click
avg_clicks <- ggplot(data = air_france, aes(x = publishers, y = avg_cost_p_click)) +
  geom_jitter(alpha = 0.2, color = "grey55") + geom_boxplot(color = "black", 
                                                            outlier.shape = NA) +
  labs(title = "Average Cost Per Click of Each Publisher" , x = "Publisher Name",
       y = "Average Cost Per Click") +
  theme_bw() + theme(plot.title = element_text(hjust = 0.5))

# constructing chart of bookings
volume_impressions <- ggplot(data = air_france, aes(x = publishers, 
                                                 y = impressions)) +
  geom_col() + labs(title = "Impressions for each Publisher" , 
                    x = "Publisher Name", y = "Impressions") + theme_bw() + 
  theme(plot.title = element_text(hjust = 0.5)) +
  scale_y_continuous(labels = comma)

# creating a summary dataframe for impressions, clicks and bookings
impressions_bar <- air_france %>%
  select(publishers, clicks, total_v_bookings, impressions) %>%
  group_by(publishers) %>%
  summarise(sum(impressions), sum(clicks), sum(total_v_bookings)) %>%
  gather("Type", "Value", -publishers)

# making the observation names a factor that is ordered 
impressions_bar$Type <- factor(impressions_bar$Type,
                               levels = c("sum(impressions)", "sum(clicks)",
                                          "sum(total_v_bookings)"),
                               labels = c("Impressions", "Clicks", "Bookings"),
                               ordered = T)

# constructing a chart showing impressions, clicks and bookings
impressions_clicks_bookings <- ggplot(data = impressions_bar, aes(x = publishers,
                                                                  y = Value, 
                                                                  fill = Type)) +
  geom_bar(position = "dodge", stat = "identity") +
  labs(title = "Impressions, Clicks and Bookings of Each Publisher") +
  xlab("Publisher Name") + ylab("Count in Log Scale") +
  theme_bw() + scale_y_log10(labels = comma)


# constructing a graph of net revenue
net_revenue_graph <- ggplot(data = air_france, aes(net_revenue)) + 
  geom_histogram(breaks=seq(-9000, 600000, by = 100), 
                 col="black", 
                 fill="grey") +
  labs(x = "Net Revenue", y = "Count", title = "Net Revenue of Keywords") +
  theme_bw() +
  theme(plot.title = element_text(hjust = 0.5)) + 
  geom_vline(xintercept = 1000, color = "red") + 
  scale_x_continuous(labels = comma)

# turning the graph into an interactive plotly graph
net_revenue_graph <- ggplotly(net_revenue_graph)

# constructing a graph of ROA
roa_graph <-  ggplot(data = air_france, aes(ROA)) + 
  geom_histogram(breaks=seq(0, 4000, by = 2), 
                 col="black", 
                 fill="grey") +
  labs(x = "ROA", y = "Count", title = "ROA of Keywords") +
  theme_bw() +
  theme(plot.title = element_text(hjust = 0.5)) +
  geom_vline(xintercept = 2, color = "red") +
  scale_x_continuous(labels = comma)

# turning the graph into an interactive plotly graph
roa_graph <- ggplotly(roa_graph)

##########################################################
##########################################################
#Comparisons between good keywords and all keywords
##########################################################
##########################################################

# For net revenue, we make a threshold of 100
# For ROA, we make a threshold of 2

# creating a new dataframe with only observations that satisfy our thresholds
new_air_france <- subset(air_france, air_france$net_revenue >= 100 &
                           air_france$ROA > 1)

# summary of total cost, net revenue and sum for total keywords
air_france_summary <- air_france %>%
  select(total_cost, net_revenue, ROA) %>%
  summarise(sum(total_cost), sum(net_revenue), sum(ROA))

# summary of total cost, net revenue and sum for good keywords
new_air_france_summary <- new_air_france %>%
  select(total_cost, net_revenue, ROA) %>%
  summarise(sum(total_cost), sum(net_revenue), sum(ROA))

# finding count of all keywords
number_good_keywords <- length(which(air_france$net_revenue >= 100 &
         air_france$ROA > 1))

# finding count of good keywords 
number_total_keywords <- nrow(air_france)

# determining the difference between dataframe with only good and 
# dataframe with good and bad keywords
number_total_keywords - number_good_keywords
# 4191 keywords were determined to be bad

# finding percentage of bad keywords
4191/4510*100
# the percentage of bad keywords is 92.92%

# combining the two summaries into one
difference_dataframe <- rbind(air_france_summary, new_air_france_summary)

# renaming the columns
colnames(difference_dataframe) <- c("total_cost", "net_revenue", "ROA")

# adding a column for names
difference_dataframe$title <- c("All Keywords", "Good Keywords Only")

# plotting graph of difference in net revenue 
revenue_difference <-  ggplot(difference_dataframe, aes(x = title, y = net_revenue)) +
  geom_col() + scale_y_continuous(labels = comma) +
  labs(x = "", y = "Total Net Revenue", 
       title = "Change in Total Net Revenue") + theme_bw() +
  theme(plot.title = element_text(hjust = 0.5))

# turning the graph into an interactive plotly graph
revenue_difference <- ggplotly(revenue_difference)

((4156675 - 3906597) / 3906597) * 100
# total revenue increases by 6.4% when bad keywords are removed

# plotting graph of difference in cost 
cost_difference <-  ggplot(difference_dataframe, aes(x = title, y = total_cost)) +
  geom_col() + scale_y_continuous(labels = comma) +
  labs(x = "", y = "Total Cost", 
       title = "Change in Total Cost") + theme_bw() +
  theme(plot.title = element_text(hjust = 0.5))

# turning the graph into an interactive plotly graph
cost_difference <- ggplotly(cost_difference)

((416524 - 755316) / 755316) * 100
# total cost increases by 44.85% when bad keywords are removed

# plotting graph of difference in ROA 
roa_difference <- ggplot(difference_dataframe, aes(x = title, y = ROA)) +
  geom_col() + scale_y_continuous(labels = comma) +
  labs(x = "", y = "Return on Ads", 
       title = "Change in Return on Ads") + theme_bw() +
  theme(plot.title = element_text(hjust = 0.5))

# turning the graph into an interactive plotly graph
roa_difference <- ggplotly(roa_difference)

((19906.77 - 19875.01) / 19906.77) * 100
# total ROA reduces by 0.15% when bad keywords are removed

# creating dataset of only variables needed
air_france_one <- air_france %>%
  select(clicks, total_v_bookings, net_revenue, publishers) %>%
  group_by(publishers) %>%
  summarise(clicks = sum(clicks), bookings = sum(total_v_bookings), 
            net_revenue = sum(net_revenue)) %>%
  mutate(clicks = round(clicks/52, digits = 0), bookings = round(bookings/52,
                                                                 digits = 0), 
         net_revenue = round(net_revenue/52, digits = 0))

#selecting only third row
kayak <- kayak[ 3, ]

# renaming the column names
colnames(kayak) <- c("search_engine", "clicks", "media_cost", "total_bookings",
                     "avg_ticket", "total_revenue", "net_revenue")

# selecting only variables needed 
kayak <- kayak %>%
  select(publishers = search_engine, clicks, bookings = total_bookings, 
         net_revenue)

# combining the two datasets into one
air_france_one <- rbind(air_france_one, kayak)

# changing the dataset again
air_france_one <- as.data.frame(air_france_one)

# turning the columns into numeric
air_france_one[,2] <- as.numeric(air_france_one[,2])
air_france_one[,3] <- as.numeric(air_france_one[,3])
air_france_one[,4] <- as.numeric(air_france_one[,4])

# creating graph for clicks from all publishers including kayak
publisher_vs_clicks <- ggplot(data = air_france_one, aes(x = publishers, 
                                                         y = clicks)) +
  geom_col() + scale_y_continuous(labels = comma) +
  labs(title = 'Clicks Per Publisher') + 
  xlab('Publisher Name') + 
  ylab('Total Clicks') + 
  theme_bw() + 
  theme(plot.title = element_text(hjust = 0.5))

publisher_vs_clicks <- ggplotly(publisher_vs_clicks)
#kayak has a total clicks of 2839 putting it with big 3 

# creating graph for bookings from all publishers including kayak
publisher_vs_total_volume <- ggplot(data = air_france_one, aes(x = publishers, 
                                                               y = bookings)) +
  geom_col() + scale_y_continuous(labels = comma) +
  labs(title = 'Total Bookings Per Publisher') + 
  xlab('Publisher Name') + 
  ylab('Total Volume of Bookings') + theme_bw() + 
  theme(plot.title = element_text(hjust = 0.5))

publisher_vs_total_volume <- ggplotly(publisher_vs_total_volume)
#kayak is outstanding in this department even better than the big 3

# creating graph for revenue from all publishers including kayak
publisher_vs_total_revenue <- ggplot(data = air_france_one, aes(x = publishers, 
                                                                y = net_revenue)) +
  geom_col() + scale_y_continuous(labels = comma) +
  labs(title = 'Total Revenue Per publisher') + 
  xlab('Publisher Name') + 
  ylab('Total Revenue') + theme_bw() + 
  theme(plot.title = element_text(hjust = 0.5))

publisher_vs_total_revenue <- ggplotly(publisher_vs_total_revenue)
#kayak is better than the big three in this regard

##########################################################
##########################################################
#ALL GRAPHS
##########################################################
##########################################################

# average clicks from each publisher
avg_clicks

# impressions generated by each publisher
volume_impressions

# impressions, clicks, bookings by each publisher
impressions_clicks_bookings

# graph of net revenue by keywords
net_revenue_graph

# graph of ROA by keywords
roa_graph

# interactive graph of difference between net revenue
revenue_difference

# interactive graph of difference between cost
cost_difference

# interactive graph of difference between ROA
roa_difference

# clicks for all publishers including kayak
publisher_vs_clicks

# revenue for all publishers including kayak
publisher_vs_total_revenue

# bookings for all publishers including kayak
publisher_vs_total_volume


######################################################




