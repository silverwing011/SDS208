# IMDb Top 250 Video Games - Simple R Scraping and Analysis

# Load packages
library(rvest)
library(jsonlite)
library(tidyverse)

# Read saved IMDb page
html <- read_html("D:/IMDb Top 250 Rated Video Games.html")

# Scrape game cards
games_html <- html_elements(html, "li.ipc-metadata-list-summary-item")

# Get release year from the first metadata item
get_year <- function(game) {
  x <- html_element(game, "li.ipc-inline-list__item")
  if (length(x) == 0) return(NA)
  as.numeric(gsub("[^0-9]", "", html_text(x)))
}

year <- sapply(games_html, get_year)

# Get game names
name <- games_html |>
  html_element(".ipc-title__text") |>
  html_text()

# Read ratings, votes and genres from JSON-LD
json <- html |>
  html_elements("script[type='application/ld+json']") |>
  html_text()

json <- json[str_detect(json, "itemListElement")][1]

# Convert JSON-LD to game information
json_to_df <- function(x) {
  x <- jsonlite::fromJSON(x, simplifyVector = FALSE)
  
  map_dfr(seq_along(x$itemListElement), function(i) {
    g <- x$itemListElement[[i]]$item
    
    data.frame(
      rating = as.numeric(g$aggregateRating$ratingValue),
      votes = as.numeric(g$aggregateRating$ratingCount),
      genre = if (is.null(g$genre)) NA else paste(g$genre, collapse = ", "),
      stringsAsFactors = FALSE
    )
  })
}

info <- json_to_df(json)

# Create final dataset
games <- data.frame(
  rank = seq_along(name),
  name = name,
  rating = info$rating,
  votes = info$votes,
  genre = info$genre,
  year = year
) |>
  mutate(decade = floor(year / 10) * 10)

# Check data
head(games)
nrow(games)
sum(!is.na(games$year))

# Rating statistics
mean(games$rating, na.rm = TRUE)
median(games$rating, na.rm = TRUE)
var(games$rating, na.rm = TRUE)
sd(games$rating, na.rm = TRUE)

# Rating distribution
ggplot(games, aes(rating)) +
  geom_histogram(binwidth = 0.2, color = "black") +
  labs(
    title = "Distribution of IMDb Ratings",
    x = "IMDb Rating",
    y = "Number of Games"
  ) +
  theme_minimal()

# Top 20 most-voted games
top20 <- games |> slice_max(votes, n = 20)

ggplot(top20, aes(reorder(name, votes), votes)) +
  geom_col() +
  coord_flip() +
  scale_y_continuous(labels = scales::comma) +
  labs(
    title = "Top 20 Games by Number of IMDb Votes",
    x = "Game",
    y = "Number of Votes"
  ) +
  theme_minimal()

# Rank vs rating
ggplot(games, aes(rank, rating)) +
  geom_point(alpha = 0.6) +
  labs(
    title = "IMDb Rank vs Rating",
    x = "IMDb Rank",
    y = "IMDb Rating"
  ) +
  theme_minimal()

# Rating-vote correlation
cor_data <- games |>
  filter(!is.na(rating), !is.na(votes))

if (nrow(cor_data) >= 2) {
  cor(cor_data$rating, cor_data$votes)
}

# Clean genres
games_genre <- games |>
  separate_rows(genre, sep = ",\\s*") |>
  mutate(genre = str_trim(genre)) |>
  filter(!is.na(genre), genre != "")

genre_count <- games_genre |>
  count(genre, sort = TRUE)

genre_count_filtered <- games_genre |>
  filter(!genre %in% c("Action", "Adventure")) |>
  count(genre, sort = TRUE)

# Genre counts - all
ggplot(genre_count, aes(reorder(genre, n), n)) +
  geom_col() +
  coord_flip() +
  labs(
    title = "Most Common Genres - All Genres",
    x = "Genre",
    y = "Number of Games"
  ) +
  theme_minimal()

# Genre counts - without Action and Adventure
ggplot(genre_count_filtered, aes(reorder(genre, n), n)) +
  geom_col() +
  coord_flip() +
  labs(
    title = "Most Common Genres - Excluding Action & Adventure",
    x = "Genre",
    y = "Number of Games"
  ) +
  theme_minimal()

# Genre pie chart - all
ggplot(genre_count, aes("", n, fill = genre)) +
  geom_bar(stat = "identity", width = 1, color = "white") +
  coord_polar("y") +
  labs(title = "Genre Distribution - All Genres") +
  theme_void() +
  theme(legend.position = "right")

# Genre pie chart - without Action and Adventure
ggplot(genre_count_filtered, aes("", n, fill = genre)) +
  geom_bar(stat = "identity", width = 1, color = "white") +
  coord_polar("y") +
  labs(title = "Genre Distribution - Excluding Action & Adventure") +
  theme_void() +
  theme(legend.position = "right")

# Improved genre-wise rating plot
genre_rating <- games_genre |>
  filter(!is.na(rating)) |>
  group_by(genre) |>
  summarise(
    number_of_games = n(),
    mean_rating = mean(rating),
    .groups = "drop"
  )

ggplot(
  genre_rating,
  aes(mean_rating, reorder(genre, mean_rating))
) +
  geom_point(
    aes(size = number_of_games),
    alpha = 0.8
  ) +
  coord_cartesian(xlim = c(8.5, 10)) +
  labs(
    title = "Average IMDb Rating by Genre",
    subtitle = "Point size represents the number of games in each genre",
    x = "Average IMDb Rating",
    y = "Genre",
    size = "Number of Games"
  ) +
  theme_minimal()

# Year-wise mean rating
year_rating <- games |>
  filter(!is.na(year), !is.na(rating)) |>
  group_by(year) |>
  summarise(
    mean_rating = mean(rating),
    number_of_games = n(),
    .groups = "drop"
  ) |>
  arrange(year)

ggplot(year_rating, aes(year, mean_rating)) +
  geom_line(linewidth = 1) +
  geom_point(aes(size = number_of_games)) +
  scale_x_continuous(
    breaks = scales::pretty_breaks(n = 12)
  ) +
  labs(
    title = "Year-Wise Mean IMDb Rating",
    x = "Release Year",
    y = "Mean IMDb Rating",
    size = "Number of Games"
  ) +
  theme_minimal()

# Decade-wise genre pie charts - including Action and Adventure
games_genre_time <- games_genre |>
  filter(!is.na(decade))

decade_genre_count <- games_genre_time |>
  count(decade, genre, sort = TRUE)

ggplot(games_genre_time, aes("", fill = genre)) +
  geom_bar(
    width = 1,
    position = "fill",
    color = "white"
  ) +
  coord_polar("y") +
  facet_wrap(~ decade) +
  labs(
    title = "Genre Distribution by Decade - All Genres",
    subtitle = "Includes Action and Adventure"
  ) +
  theme_void() +
  theme(legend.position = "right")

# Decade-wise genre pie charts - excluding Action and Adventure
games_genre_filtered_time <- games_genre |>
  filter(
    !genre %in% c("Action", "Adventure"),
    !is.na(decade)
  )

decade_genre_count_filtered <- games_genre_filtered_time |>
  count(decade, genre, sort = TRUE)

ggplot(games_genre_filtered_time, aes("", fill = genre)) +
  geom_bar(
    width = 1,
    position = "fill",
    color = "white"
  ) +
  coord_polar("y") +
  facet_wrap(~ decade) +
  labs(
    title = "Genre Distribution by Decade - Excluding Action & Adventure"
  ) +
  theme_void() +
  theme(legend.position = "right")

# Save data
write.csv(
  games,
  "IMDb_Video_Game_Cleaned_Data.csv",
  row.names = FALSE
)

write.csv(
  year_rating,
  "IMDb_Year_Wise_Mean_Rating.csv",
  row.names = FALSE
)

write.csv(
  genre_count,
  "IMDb_Genre_Count_All.csv",
  row.names = FALSE
)

write.csv(
  genre_count_filtered,
  "IMDb_Genre_Count_Without_Action_Adventure.csv",
  row.names = FALSE
)

write.csv(
  decade_genre_count,
  "IMDb_Decade_Wise_Genre_Count_All_Genres.csv",
  row.names = FALSE
)

write.csv(
  decade_genre_count_filtered,
  "IMDb_Decade_Wise_Genre_Count_Without_Action_Adventure.csv",
  row.names = FALSE
)