# Load necessary libraries
library(dplyr)
library(tidyr)
library(stringr)
library(caret)
library(data.table)
library(Amelia)
library(ggplot2)
library(dplyr)
library(summarytools)
library(DataExplorer)
library(corrplot)
library(leaflet)


# Load the dataset
data <-read.csv("C:/Users/kaish/Downloads/region_01.csv")
print(data)
head(data)
str(data)
dim(data)


# Select the specific columns using dplyr
df_selected <- data %>%
  select(iyear, imonth, iday, country, latitude, longitude, city, , weaptype1, attacktype1, propextent, suicide, dbsource)

# View the selected columns
print(df_selected)


str(df_selected)
dim(df_selected)
summary(df_selected)


# Remove duplicate rows from the entire data frame
data_unique <- df_selected[!duplicated(df_selected), ]
dim(data_unique)
sum(is.na(data_unique))

# Check for missing values in each column
colSums(is.na(data_unique))

# Visualize missing data
missmap(data)

# Remove rows with any NA values
data_no_na <- na.omit(data_unique)
missmap(data_no_na)
dim(data_no_na)

# Loop through all columns to create histograms for numeric columns
for(col in names(data_no_na)) {
  if(is.numeric(data_no_na[[col]])) {
    p <- ggplot(data_no_na, aes_string(x = col)) +
      geom_histogram(bins = 30, fill = "lightblue", color = "black", alpha = 0.7) +
      labs(title = paste("Histogram of", col), x = col, y = "Frequency") +
      theme_minimal()
    
    print(p)  # Print the plot
  }
}

# Loop through all columns to create bar plots for categorical columns
for(col in names(data_no_na)) {
  if(is.factor(data_no_na[[col]]) || is.character(data[[col]])) {
    p <- ggplot(data_no_na, aes_string(x = col)) +
      geom_bar(fill = "lightblue", color = "black") +
      labs(title = paste("Bar Plot of", col), x = col, y = "Count") +
      theme_minimal()
    
    print(p)  # Print the plot
  }
}



# Apply label encoding to multiple columns
data <- data_no_na %>%
  mutate(across(where(is.character), ~ as.numeric(factor(.))))
str(data)
dim(data)

# Correlation matrix for numeric columns
correlation_matrix <- cor(data %>% select(where(is.numeric)))

# Visualize the correlation matrix
corrplot(correlation_matrix, method = "circle")


# Pairwise plot for numeric columns
pairs(data %>% select(where(is.numeric)))


# Select numeric columns
numeric_columns <- data[, sapply(data, is.numeric)]

# Create a boxplot for all numeric features in the dataset
boxplot(numeric_columns, 
        main = "Boxplot for Numeric Features",
        col = c("skyblue", "lightgreen"),
        border = "darkblue",
        horizontal = TRUE,
        las = 1)  # Rotate axis labels



# Generate a report with DataExplorer
create_report(data)


# Create an interactive map
leaflet(data) %>%
  addTiles() %>%
  addMarkers(~longitude, ~latitude, popup = ~name)


df_geo <- data %>%
  select(city, latitude, longitude)

# Create a leaflet map
map <- leaflet(df_geo) %>%
  addTiles() %>%  # Add default OpenStreetMap tiles
  addMarkers(
    ~longitude, ~latitude, popup = ~city
  )

# Display the map
map

# Load necessary libraries
library(ggplot2)
library(dplyr)
library(tidyr)

# Assuming df is the dataframe, replacing it with actual data

# Group by year and calculate the sum of suicides for each year
suicide_by_year <- data %>%
  group_by(iyear) %>%
  summarise(suicides = sum(suicide, na.rm = TRUE))

# Count occurrences of attack types over time (by year)
attack_type_by_year <- data %>%
  group_by(iyear, attacktype1) %>%
  summarise(count = n()) %>%
  spread(key = attacktype1, value = count, fill = 0)

# Count occurrences of weapon types over time (by year)
weapon_type_by_year <- data %>%
  group_by(iyear, weaptype1) %>%
  summarise(count = n()) %>%
  spread(key = weaptype1, value = count, fill = 0)

# Reshape the data for plotting
suicide_long <- suicide_by_year %>%
  rename(year = iyear, value = suicides) %>%
  mutate(variable = "Suicides")

attack_long <- attack_type_by_year %>%
  gather(key = "variable", value = "value", -iyear) %>%
  rename(year = iyear) %>%
  mutate(variable = paste("Attack Type:", variable))

weapon_long <- weapon_type_by_year %>%
  gather(key = "variable", value = "value", -iyear) %>%
  rename(year = iyear) %>%
  mutate(variable = paste("Weapon Type:", variable))

# Combine all data for plotting
df_long <- bind_rows(suicide_long, attack_long, weapon_long)

# Plotting
ggplot(df_long, aes(x = year, y = value, color = variable, group = variable)) +
  geom_line() +   # Create line plot
  geom_point() +  # Add points to the line plot
  labs(
    title = "Suicides, Attack Types, and Weapon Types Over Time",
    x = "Year",
    y = "Count",
    color = "Categories"
  ) +
  theme_minimal() +
  theme(axis.text.x = element_text(angle = 45, hjust = 1))  # Rotate x-axis labels for readability


# Calculate the frequency of each db_source
db_source_counts <- data %>%
  count(dbsource) %>%
  arrange(desc(n))  # Arrange in descending order

# Plot the frequency of the most common db_source
ggplot(db_source_counts, aes(x = reorder(dbsource, -n), y = n, fill = dbsource)) +
  geom_bar(stat = "identity", palette = "viridis") +
  labs(
    title = "Frequency of Most Common DB Sources",
    x = "DB Source",
    y = "Frequency"
  ) +
  theme_minimal() +
  theme(axis.text.x = element_text(angle = 45, hjust = 1))  # Rotate x-axis labels for readability



# Calculate the number of occurrences of each attack type and property extension combination
attack_property_counts <- data %>%
  group_by(attacktype1, propextent) %>%
  summarise(count = n()) %>%
  spread(key = propextent, value = count, fill = 0)  # Reshape the data into wide format

# Plot the frequency of attack types and property extensions
attack_property_counts_long <- attack_property_counts %>%
  gather(key = "property_extension", value = "frequency", -attacktype1)

ggplot(attack_property_counts_long, aes(x = attacktype1, y = frequency, fill = property_extension)) +
  geom_bar(stat = "identity", position = "dodge") +  # Create grouped bar plot
  labs(
    title = "Number of Property Extensions by Attack Type",
    x = "Attack Type",
    y = "Frequency",
    fill = "Property Extension"
  ) +
  theme_minimal() +
  theme(axis.text.x = element_text(angle = 45, hjust = 1))  # Rotate x-axis labels for readability


# Filter the data to include only suicides (suicide == 1) and group by country
suicides_by_country <- data %>%
  filter(suicide == 1) %>%
  count(country) %>%
  arrange(desc(n))  # Arrange by descending number of suicides

# Plot the number of suicides in each country
ggplot(suicides_by_country, aes(x = reorder(country, -n), y = n, fill = country)) +
  geom_bar(stat = "identity") +  # Create bar plot
  labs(
    title = "Number of Suicides in Each Country",
    x = "Country",
    y = "Number of Suicides"
  ) +
  theme_minimal() +
  theme(axis.text.x = element_text(angle = 45, hjust = 1))  # Rotate x-axis labels for readability



