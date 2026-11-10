# IMDb Top 250 Video Games - Shiny App with extended graphs + presentation-ready analysis
# Required packages: shiny, bslib, rvest, jsonlite, tidyverse, scales, DT

library(shiny)
library(bslib)
library(rvest)
library(jsonlite)
library(tidyverse)
library(DT)

# ------------------------------------------------------------------
# DATA LOADING
# ------------------------------------------------------------------
# Uses the cleaned CSV if found next to app.R, otherwise scrapes the saved HTML.
CSV_PATH  <- "IMDb_Video_Game_Cleaned_Data.csv"
HTML_PATH <- "D:/IMDb Top 250 Rated Video Games.html"

scrape_games <- function(path) {
  html <- read_html(path)
  games_html <- html_elements(html, "li.ipc-metadata-list-summary-item")
  
  get_year <- function(game) {
    x <- html_element(game, "li.ipc-inline-list__item")
    if (length(x) == 0) return(NA)
    as.numeric(gsub("[^0-9]", "", html_text(x)))
  }
  
  year <- sapply(games_html, get_year)
  name <- games_html |> html_element(".ipc-title__text") |> html_text()
  
  json <- html |>
    html_elements("script[type='application/ld+json']") |>
    html_text()
  json <- json[str_detect(json, "itemListElement")][1]
  
  x <- jsonlite::fromJSON(json, simplifyVector = FALSE)
  info <- map_dfr(seq_along(x$itemListElement), function(i) {
    g <- x$itemListElement[[i]]$item
    data.frame(
      rating = as.numeric(g$aggregateRating$ratingValue),
      votes  = as.numeric(g$aggregateRating$ratingCount),
      genre  = if (is.null(g$genre)) NA else paste(g$genre, collapse = ", "),
      stringsAsFactors = FALSE
    )
  })
  
  data.frame(
    rank = seq_along(name), name = name,
    rating = info$rating, votes = info$votes,
    genre = info$genre, year = year
  )
}

load_games <- function() {
  if (file.exists(CSV_PATH)) {
    read.csv(CSV_PATH, stringsAsFactors = FALSE)
  } else if (file.exists(HTML_PATH)) {
    scrape_games(HTML_PATH)
  } else {
    stop("Data not found. Put '", CSV_PATH,
         "' next to app.R, or set HTML_PATH to your saved IMDb page.")
  }
}

games <- load_games() |>
  mutate(
    decade   = floor(year / 10) * 10,
    n_genres = ifelse(is.na(genre) | genre == "", NA, str_count(genre, ",") + 1)
  )

games_genre <- games |>
  separate_rows(genre, sep = ",\\s*") |>
  mutate(genre = str_trim(genre)) |>
  filter(!is.na(genre), genre != "")

# ------------------------------------------------------------------
# SMALL HELPERS
# ------------------------------------------------------------------
pal <- "steelblue"
fmt <- function(x, d = 2) formatC(x, format = "f", digits = d, big.mark = ",")
pct <- function(x, d = 1) paste0(fmt(100 * x, d), "%")
spear <- function(a, b) suppressWarnings(cor(a, b, method = "spearman", use = "complete.obs"))
strength <- function(r) {
  a <- abs(r)
  if (is.na(a)) "undefined" else if (a < 0.1) "negligible" else if (a < 0.3) "weak"
  else if (a < 0.5) "moderate" else if (a < 0.7) "strong" else "very strong"
}
direction <- function(r) if (is.na(r)) "" else if (r < 0) "negative" else "positive"

# Genre pairs that appear together in the same game
cooc_pairs <- function(gd, top = 12) {
  top_g <- gd |> count(genre, sort = TRUE) |> slice_head(n = top) |> pull(genre)
  g <- gd |> filter(genre %in% top_g) |> distinct(rank, genre)
  multi <- g |> group_by(rank) |> filter(n() >= 2) |> ungroup()
  if (nrow(multi) == 0) return(tibble(g1 = character(), g2 = character(), n = integer()))
  multi |>
    group_by(rank) |>
    summarise(p = list(as.data.frame(t(combn(sort(genre), 2)))), .groups = "drop") |>
    unnest(p) |>
    count(g1 = V1, g2 = V2, sort = TRUE)
}

# ------------------------------------------------------------------
# PLOT CATALOGUE (grouped dropdown)
# ------------------------------------------------------------------
plot_groups <- list(
  "Distributions" = c(
    "Rating distribution (histogram)"        = "rating_hist",
    "Votes distribution (log scale)"         = "votes_hist"
  ),
  "Popularity & ranking" = c(
    "Top 20 most-voted games"                = "top20",
    "Top 15 highest-rated games"             = "top15_rated",
    "IMDb rank vs rating"                    = "rank_rating",
    "IMDb rank vs votes (log scale)"         = "rank_votes",
    "Votes vs rating (with trend line)"      = "votes_rating"
  ),
  "Genres" = c(
    "Genre counts (bar chart)"               = "genre_bar",
    "Genre distribution (pie chart)"         = "genre_pie",
    "Average rating by genre"                = "genre_rating",
    "Rating spread by genre (box plot)"      = "genre_box",
    "Median votes by genre"                  = "genre_votes",
    "Number of genres vs rating"             = "ngenres_rating"
  ),
  "Time" = c(
    "Year-wise mean rating"                  = "year_rating",
    "Games released per year"                = "year_count",
    "Rating by decade (box plot)"            = "decade_box",
    "Genre distribution by decade (pies)"    = "decade_pie",
    "Genre share by decade (stacked bars)"   = "decade_prop"
  )
)
all_choices <- unlist(unname(plot_groups))

# ------------------------------------------------------------------
# PLOTS
# ------------------------------------------------------------------
make_plot <- function(id, games, gd, aa) {
  sfx <- if (aa) " - All Genres" else " - Excluding Action & Adventure"
  th <- theme_minimal(base_size = 14)
  
  switch(id,
         
         rating_hist = ggplot(games, aes(rating)) +
           geom_histogram(binwidth = 0.2, color = "black", fill = pal) +
           geom_vline(xintercept = mean(games$rating, na.rm = TRUE),
                      linetype = "dashed", color = "red", linewidth = 1) +
           labs(title = "Distribution of IMDb Ratings",
                subtitle = "Dashed red line = mean rating",
                x = "IMDb Rating", y = "Number of Games") + th,
         
         votes_hist = ggplot(games, aes(votes)) +
           geom_histogram(bins = 30, color = "black", fill = pal) +
           scale_x_log10(labels = scales::comma) +
           labs(title = "Distribution of IMDb Votes (log scale)",
                x = "Number of Votes (log10 scale)", y = "Number of Games") + th,
         
         top20 = {
           t <- games |> slice_max(votes, n = 20, with_ties = FALSE)
           ggplot(t, aes(reorder(name, votes), votes)) +
             geom_col(fill = pal) + coord_flip() +
             scale_y_continuous(labels = scales::comma) +
             labs(title = "Top 20 Games by Number of IMDb Votes",
                  x = "Game", y = "Number of Votes") + th
         },
         
         top15_rated = {
           t <- games |> arrange(desc(rating), desc(votes)) |> slice_head(n = 15)
           t$name <- factor(t$name, levels = rev(unique(t$name)))
           x0 <- floor(min(t$rating, na.rm = TRUE) * 10) / 10 - 0.1
           ggplot(t, aes(rating, name)) +
             geom_segment(aes(x = x0, xend = rating, yend = name), color = "grey60") +
             geom_point(aes(size = votes), color = pal) +
             scale_size_continuous(labels = scales::comma) +
             labs(title = "Top 15 Highest-Rated Games",
                  subtitle = "Point size = number of votes",
                  x = "IMDb Rating", y = "Game", size = "Votes") + th
         },
         
         rank_rating = ggplot(games, aes(rank, rating)) +
           geom_point(alpha = 0.6, color = pal) +
           geom_smooth(method = "loess", formula = y ~ x, se = FALSE, color = "red") +
           labs(title = "IMDb Rank vs Rating", x = "IMDb Rank", y = "IMDb Rating") + th,
         
         rank_votes = ggplot(games, aes(rank, votes)) +
           geom_point(alpha = 0.6, color = pal) +
           geom_smooth(method = "loess", formula = y ~ x, se = FALSE, color = "red") +
           scale_y_log10(labels = scales::comma) +
           labs(title = "IMDb Rank vs Number of Votes",
                x = "IMDb Rank", y = "Votes (log10 scale)") + th,
         
         votes_rating = ggplot(games, aes(votes, rating)) +
           geom_point(alpha = 0.6, color = pal) +
           geom_smooth(method = "lm", formula = y ~ x, color = "red") +
           scale_x_log10(labels = scales::comma) +
           labs(title = "Votes vs Rating",
                subtitle = "Linear trend fitted on log10(votes)",
                x = "Number of Votes (log10 scale)", y = "IMDb Rating") + th,
         
         genre_bar = {
           gc <- gd |> count(genre, sort = TRUE)
           ggplot(gc, aes(reorder(genre, n), n)) +
             geom_col(fill = pal) + coord_flip() +
             labs(title = paste0("Most Common Genres", sfx),
                  x = "Genre", y = "Number of Games") + th
         },
         
         genre_pie = {
           gc <- gd |> count(genre, sort = TRUE)
           ggplot(gc, aes("", n, fill = genre)) +
             geom_bar(stat = "identity", width = 1, color = "white") +
             coord_polar("y") +
             labs(title = paste0("Genre Distribution", sfx), fill = "Genre") +
             theme_void(base_size = 14) + theme(legend.position = "right")
         },
         
         genre_rating = {
           gr <- gd |> filter(!is.na(rating)) |> group_by(genre) |>
             summarise(number_of_games = n(), mean_rating = mean(rating), .groups = "drop")
           ggplot(gr, aes(mean_rating, reorder(genre, mean_rating))) +
             geom_point(aes(size = number_of_games), alpha = 0.8, color = pal) +
             labs(title = paste0("Average IMDb Rating by Genre", sfx),
                  subtitle = "Point size represents the number of games in each genre",
                  x = "Average IMDb Rating", y = "Genre", size = "Number of Games") + th
         },
         
         genre_box = {
           keep <- gd |> count(genre) |> filter(n >= 5) |> pull(genre)
           validate(need(length(keep) > 0, "No genre has at least 5 games."))
           d <- gd |> filter(genre %in% keep, !is.na(rating))
           ggplot(d, aes(reorder(genre, rating, median), rating)) +
             geom_boxplot(fill = pal, alpha = 0.6) + coord_flip() +
             labs(title = paste0("Rating Spread by Genre", sfx),
                  subtitle = "Genres with at least 5 games, ordered by median rating",
                  x = "Genre", y = "IMDb Rating") + th
         },
         
         genre_votes = {
           gv <- gd |> filter(!is.na(votes)) |> group_by(genre) |>
             summarise(n = n(), median_votes = median(votes), .groups = "drop") |>
             filter(n >= 5)
           validate(need(nrow(gv) > 0, "No genre has at least 5 games."))
           ggplot(gv, aes(reorder(genre, median_votes), median_votes)) +
             geom_col(fill = pal) + coord_flip() +
             scale_y_continuous(labels = scales::comma) +
             labs(title = paste0("Median Votes by Genre", sfx),
                  subtitle = "Genres with at least 5 games",
                  x = "Genre", y = "Median Number of Votes") + th
         },
         
         genre_cooc = {
           pr <- cooc_pairs(gd)
           validate(need(nrow(pr) > 0, "No games with two or more genres in this selection."))
           sym <- bind_rows(pr, rename(pr, g1 = g2, g2 = g1))
           ggplot(sym, aes(g1, g2, fill = n)) +
             geom_tile(color = "white") +
             geom_text(aes(label = n), size = 3.5) +
             scale_fill_gradient(low = "#deebf7", high = "#08519c") +
             labs(title = paste0("Genre Co-occurrence (top 12 genres)", sfx),
                  subtitle = "Number of games carrying both genres",
                  x = NULL, y = NULL, fill = "Games") +
             th + theme(axis.text.x = element_text(angle = 40, hjust = 1))
         },
         
         ngenres_rating = {
           d <- games |> filter(!is.na(n_genres), !is.na(rating))
           ggplot(d, aes(factor(n_genres), rating)) +
             geom_boxplot(fill = pal, alpha = 0.5, outlier.shape = NA) +
             geom_jitter(width = 0.15, alpha = 0.35) +
             labs(title = "Number of Genres vs Rating",
                  x = "Number of genres listed for the game", y = "IMDb Rating") + th
         },
         
         year_rating = {
           yr <- games |> filter(!is.na(year), !is.na(rating)) |> group_by(year) |>
             summarise(mean_rating = mean(rating), number_of_games = n(), .groups = "drop") |>
             arrange(year)
           ggplot(yr, aes(year, mean_rating)) +
             geom_line(linewidth = 1, color = pal) +
             geom_point(aes(size = number_of_games), color = pal) +
             scale_x_continuous(breaks = scales::pretty_breaks(n = 12)) +
             labs(title = "Year-Wise Mean IMDb Rating",
                  x = "Release Year", y = "Mean IMDb Rating", size = "Number of Games") + th
         },
         
         year_count = {
           yc <- games |> filter(!is.na(year)) |> count(year)
           ggplot(yc, aes(year, n)) +
             geom_col(fill = pal) +
             scale_x_continuous(breaks = scales::pretty_breaks(n = 12)) +
             labs(title = "Number of Top-250 Games by Release Year",
                  x = "Release Year", y = "Number of Games") + th
         },
         
         decade_box = {
           d <- games |> filter(!is.na(decade), !is.na(rating))
           ggplot(d, aes(factor(decade), rating)) +
             geom_boxplot(fill = pal, alpha = 0.5, outlier.shape = NA) +
             geom_jitter(width = 0.15, alpha = 0.35) +
             labs(title = "IMDb Rating by Decade of Release",
                  x = "Decade", y = "IMDb Rating") + th
         },
         
         decade_pie = {
           d <- gd |> filter(!is.na(decade))
           ggplot(d, aes("", fill = genre)) +
             geom_bar(width = 1, position = "fill", color = "white") +
             coord_polar("y") + facet_wrap(~ decade) +
             labs(title = paste0("Genre Distribution by Decade", sfx), fill = "Genre") +
             theme_void(base_size = 14) + theme(legend.position = "right")
         },
         
         decade_prop = {
           d <- gd |> filter(!is.na(decade))
           ggplot(d, aes(factor(decade), fill = genre)) +
             geom_bar(position = "fill", color = "white") +
             scale_y_continuous(labels = scales::percent) +
             labs(title = paste0("Genre Share by Decade", sfx),
                  x = "Decade", y = "Share of genre tags", fill = "Genre") + th
         },
         
         corr_heat = {
           m <- games |> transmute(Rank = rank, Rating = rating,
                                   `Votes (log10)` = log10(votes),
                                   Year = year, `# Genres` = n_genres)
           cm <- cor(m, use = "pairwise.complete.obs", method = "spearman")
           cd <- as.data.frame(as.table(cm))
           ggplot(cd, aes(Var1, Var2, fill = Freq)) +
             geom_tile(color = "white") +
             geom_text(aes(label = round(Freq, 2)), size = 5) +
             scale_fill_gradient2(low = "firebrick", mid = "white", high = pal,
                                  limits = c(-1, 1)) +
             labs(title = "Spearman Correlation Matrix", x = NULL, y = NULL, fill = "r") + th
         }
  )
}

# ------------------------------------------------------------------
# ANALYSES (numbers are computed live from the current data / toggle)
# ------------------------------------------------------------------
make_analysis <- function(id, games, gd, aa) {
  n_games <- nrow(games)
  A <- function(shows, findings, talk, caveat)
    list(shows = shows, findings = Filter(Negate(is.null), findings),
         talk = talk, caveat = caveat)
  sel_note <- if (aa) NULL else
    "We have switched off Action and Adventure, so every genre figure below describes only the remaining genre tags."
  
  switch(id,
         
         rating_hist = {
           r <- games$rating[!is.na(games$rating)]
           b <- round(floor(r / 0.2 + 1e-9) * 0.2, 1)
           tb <- table(b); mb <- as.numeric(names(which.max(tb)))
           A(
             shows = "In this chart we show how the ratings of our games are spread out. Each bar counts the games in a 0.2-point rating band, and the dashed line marks the mean.",
             findings = list(
               paste0("Across our ", length(r), " games, the mean rating is ", fmt(mean(r)), ", the median is ", fmt(median(r)),
                      " and the standard deviation is ", fmt(sd(r)), ". Ratings run from ", fmt(min(r)), " to ", fmt(max(r)), "."),
               paste0("We found that ", sum(r >= 9), " games (", pct(mean(r >= 9)), ") are rated 9.0 or higher, while ",
                      sum(r < 8.5), " (", pct(mean(r < 8.5)), ") are below 8.5."),
               paste0("The most crowded band we see is ", fmt(mb, 1), " to ", fmt(mb + 0.2, 1), ", which holds ", max(tb), " games."),
               if (mean(r) > median(r))
                 "Because the mean is above the median, we see a right skew: a handful of exceptionally high ratings stretches the right tail."
               else
                 "Because the mean is at or below the median, we see a left skew: a few lower-rated titles stretch the left tail."
             ),
             talk = c(
               "We notice that even the lowest-rated game in our list is rated highly, so everything we study sits in a narrow, high band.",
               "Because the spread is small, we treat a 0.1 difference in rating as meaningful, since it can move a game up or down many ranks.",
               "This tells us that we are comparing excellent games against other excellent games."
             ),
             caveat = "We need to keep in mind that our data is the Top 250, so the low end of the rating scale is cut off by design. This is not a sample of all games."
           )
         },
         
         votes_hist = {
           v <- games$votes[!is.na(games$votes)]
           top10 <- sort(v, decreasing = TRUE)[seq_len(ceiling(0.1 * length(v)))]
           A(
             shows = "Here we look at how many votes each game has received. We use a logarithmic axis so that both niche and blockbuster titles are visible.",
             findings = list(
               paste0("The median game in our data has ", fmt(median(v), 0), " votes, the mean is ", fmt(mean(v), 0),
                      ", and the range runs from ", fmt(min(v), 0), " to ", fmt(max(v), 0), " votes."),
               paste0("We see that the most-voted game has about ", fmt(max(v) / median(v), 1), " times the votes of the median game."),
               paste0("The top 10% of our games (", length(top10), " titles) hold ", pct(sum(top10) / sum(v)), " of all votes.")
             ),
             talk = c(
               "We read this as extreme inequality in popularity: a few mega-titles attract most of the attention.",
               "The mean sitting far above the median is, for us, the signature of a heavy-tailed distribution.",
               "We trust a high rating built on many votes more than one built on few, and this chart shows how much votes differ between games."
             ),
             caveat = "We should note that votes measure IMDb audience participation, not sales or player counts, and older or console-era games may attract fewer IMDb voters."
           )
         },
         
         top20 = {
           t <- games |> slice_max(votes, n = 20, with_ties = FALSE)
           rest <- games |> filter(!(name %in% t$name))
           A(
             shows = "In this chart we show the 20 games with the most IMDb votes, in other words the games that reached the largest audience.",
             findings = list(
               paste0("'", t$name[1], "' leads with ", fmt(t$votes[1], 0), " votes, while #20 ('", t$name[20], "') has ", fmt(t$votes[20], 0), "."),
               paste0("Together, these 20 titles hold ", pct(sum(t$votes) / sum(games$votes, na.rm = TRUE)),
                      " of all the votes in our data."),
               paste0("Their average rating is ", fmt(mean(t$rating, na.rm = TRUE)), ", compared with ",
                      fmt(mean(rest$rating, na.rm = TRUE)), " for the other games."),
               paste0("We found that ", sum(t$rank <= 20), " of these 20 also sit inside the overall Top 20 by rank, and the median rank of the group is ",
                      fmt(median(t$rank), 0), ".")
             ),
             talk = c(
               "We see that most-voted does not mean best-ranked, so we compare the vote leaders with their actual rank.",
               "In our view, a small group of well-known franchises dominates the conversation, which tells a story about mainstream versus niche appeal.",
               "The question we are left with is whether popularity makes a game better rated, or whether being good makes it popular."
             ),
             caveat = "We must remember that vote counts accumulate over time, so older, long-available games have an advantage over recent releases."
           )
         },
         
         top15_rated = {
           t <- games |> arrange(desc(rating), desc(votes)) |> slice_head(n = 15)
           A(
             shows = "Here we show the 15 highest-rated games. The size of each point shows how many votes back up the rating.",
             findings = list(
               paste0("The highest-rated game is '", t$name[1], "' at ", fmt(t$rating[1]), ", and #15 ('", t$name[15], "') is at ", fmt(t$rating[15]),
                      ", a gap of only ", fmt(t$rating[1] - t$rating[15]), " points."),
               paste0("The median vote count for these 15 games is ", fmt(median(t$votes), 0), ", compared with ", fmt(median(games$votes, na.rm = TRUE), 0),
                      " for all of our games."),
               paste0("Their typical release year is ", fmt(median(t$year, na.rm = TRUE), 0), ", while the overall median is ",
                      fmt(median(games$year, na.rm = TRUE), 0), ".")
             ),
             talk = c(
               "At the very top we see tiny differences, so the order of the ranking is sensitive to small changes in votes.",
               "When we look at the point sizes, we see that some top-rated games are backed by huge audiences and others by modest ones."
             ),
             caveat = "We should note that IMDb rounds ratings to one decimal, so several games may be tied, and we separate them here by vote count."
           )
         },
         
         rank_rating = {
           o <- games |> arrange(rank)
           k <- min(50, floor(n_games / 2))
           inv <- sum(diff(o$rating) > 0, na.rm = TRUE)
           A(
             shows = "In this chart each dot is a game, and we plot its IMDb rank (left = best) against its rating. The red line is a smoothed trend.",
             findings = list(
               paste0("We see the rating fall from ", fmt(o$rating[1]), " at rank 1 to ", fmt(o$rating[nrow(o)]), " at rank ", nrow(o), "."),
               paste0("The top ", k, " games average ", fmt(mean(head(o$rating, k), na.rm = TRUE)), ", while the bottom ", k, " average ",
                      fmt(mean(tail(o$rating, k), na.rm = TRUE)), "."),
               paste0("In ", inv, " places we find a lower-ranked game that actually has a higher rating than the one just above it.")
             ),
             talk = c(
               "We read the relationship as close to monotone, so rating is the main driver of rank.",
               "The places where it is not monotone show us IMDb's weighting at work, because votes also influence a game's position.",
               "The trend line lets us see whether the rating drops steadily or falls off faster at one end of the list."
             ),
             caveat = "We have to remember that IMDb uses a weighted rating formula for its rankings, so rank is not a pure sort by displayed rating."
           )
         },
         
         rank_votes = {
           o <- games |> arrange(rank)
           k <- min(50, floor(n_games / 2))
           tv <- mean(head(o$votes, k), na.rm = TRUE); bv <- mean(tail(o$votes, k), na.rm = TRUE)
           rho <- spear(games$rank, games$votes)
           A(
             shows = "Here we plot rank (left = best) against the number of votes on a log scale, because we want to know whether better-ranked games attract more votes.",
             findings = list(
               paste0("The Spearman correlation we measure between rank and votes is ", fmt(rho), ", which we describe as ", strength(rho), " and ", direction(rho), "."),
               paste0("The top ", k, " games average ", fmt(tv, 0), " votes, versus ", fmt(bv, 0), " for the bottom ", k, ", a ratio of ", fmt(tv / bv, 1), "x."),
               paste0("The most-voted game sits at rank ", games$rank[which.max(games$votes)], ", and the least-voted at rank ",
                      games$rank[which.min(games$votes)], ".")
             ),
             talk = c(
               "If we see the cloud slope clearly, popularity and rank go hand in hand. If it is scattered, we conclude that quality and popularity are largely independent here.",
               "We call games far below the trend 'hidden gems': they have a high rank but a small audience.",
               "We call games far above the trend 'crowd favourites': they rank lower than their popularity would suggest."
             ),
             caveat = "We should be careful with the log scale, because it compresses differences: a visually small gap can be a very large difference in vote counts."
           )
         },
         
         votes_rating = {
           d <- games |> filter(!is.na(votes), !is.na(rating))
           fit <- lm(rating ~ log10(votes), data = d)
           pr <- cor(d$rating, d$votes); pl <- cor(d$rating, log10(d$votes)); sp <- spear(d$rating, d$votes)
           A(
             shows = "In this chart each dot is a game, and we plot its number of votes (log scale) against its rating, together with a fitted linear trend.",
             findings = list(
               paste0("We measure a Pearson correlation of ", fmt(pr), " with raw votes, ", fmt(pl), " with log10(votes), and a Spearman correlation of ", fmt(sp), "."),
               paste0("On the log scale, we describe the relationship as ", strength(pl), " and ", direction(pl), "."),
               paste0("In our model, each 10x increase in votes is associated with a rating change of ", fmt(coef(fit)[[2]], 3), " points on average."),
               paste0("Our model explains ", pct(summary(fit)$r.squared), " of the variation in ratings.")
             ),
             talk = c(
               "We use the log version because the raw correlation understates the relationship: votes are so skewed that the log scale is the fairer test.",
               "A small slope tells us that being popular barely changes how highly a game is rated.",
               "We cannot claim causation here: great games may attract votes, or popular games may attract friendly voters."
             ),
             caveat = "We should note that within a Top-250 list, selection truncates the rating range, which weakens any correlation we measure."
           )
         },
         
         genre_bar = , genre_pie = {
           gc <- gd |> count(genre, sort = TRUE)
           ng <- n_distinct(gd$rank)
           A(
             shows = "Here we count how often each genre appears. A game can carry several genres, so our counts add up to more than the number of games.",
             findings = list(
               sel_note,
               paste0("'", gc$genre[1], "' is the most common genre, appearing in ", gc$n[1], " of our ", ng, " games (", pct(gc$n[1] / ng), ")",
                      if (nrow(gc) >= 3) paste0("; next are '", gc$genre[2], "' (", gc$n[2], ") and '", gc$genre[3], "' (", gc$n[3], ").") else "."),
               paste0("We count ", nrow(gc), " distinct genres, and the top three account for ", pct(sum(head(gc$n, 3)) / sum(gc$n)),
                      " of all genre tags."),
               paste0("On average, a game in our data carries ", fmt(nrow(gd) / ng, 1), " genre tags.")
             ),
             talk = c(
               "We treat Action and Adventure as umbrella labels, so we switch them off to see what really differentiates the games.",
               "If the distribution is concentrated, we conclude that the Top 250 favours a few styles of game. If it is flat, we see variety.",
               "We use the bar chart for exact comparisons and the pie chart to show proportions at a glance."
             ),
             caveat = "We should note that pie charts are hard to read with many small slices, so we rely on the bar chart for precise differences."
           )
         },
         
         genre_rating = {
           gr <- gd |> filter(!is.na(rating)) |> group_by(genre) |>
             summarise(n = n(), m = mean(rating), .groups = "drop")
           rel <- gr |> filter(n >= 5)
           A(
             shows = "In this chart we show the average rating of games in each genre. The size of each point shows how many games our average is based on.",
             findings = list(
               sel_note,
               if (nrow(rel) >= 2) {
                 b <- slice_max(rel, m, n = 1, with_ties = FALSE); w <- slice_min(rel, m, n = 1, with_ties = FALSE)
                 paste0("Among genres with at least 5 games, we find that '", b$genre, "' has the highest average (", fmt(b$m), ", ", b$n,
                        " games) and '", w$genre, "' the lowest (", fmt(w$m), ", ", w$n, " games), a spread of only ",
                        fmt(b$m - w$m), " points.")
               } else "We have too few genres with at least 5 games to compare reliably.",
               paste0("For context, the overall mean rating in our data is ", fmt(mean(games$rating, na.rm = TRUE)), ", with a standard deviation of ",
                      fmt(sd(games$rating, na.rm = TRUE)), "."),
               paste0(sum(gr$n < 5), " genres have fewer than 5 games, so we treat their averages as unstable.")
             ),
             talk = c(
               "The differences between genres are small compared with the spread of individual ratings, so we avoid claiming that one genre is simply 'better'.",
               "We trust the large dots, and we treat tiny dots at the extremes as probably noise.",
               "We pair this chart with the box plot to check whether the averages hide wide variation."
             ),
             caveat = "We count games with several genres once for each genre, so our groups overlap and are not independent."
           )
         },
         
         genre_box = {
           rel <- gd |> filter(!is.na(rating)) |> group_by(genre) |>
             summarise(n = n(), med = median(rating), iqr = IQR(rating), mx = max(rating), .groups = "drop") |>
             filter(n >= 5)
           A(
             shows = "Here we show the full spread of ratings within each genre: the box is the middle 50% of games, the line is the median, and the dots are outliers.",
             findings = list(
               sel_note,
               if (nrow(rel) >= 2) paste0("We find that '", slice_max(rel, med, n = 1, with_ties = FALSE)$genre, "' has the highest median rating (",
                                          fmt(max(rel$med)), "), and '", slice_min(rel, med, n = 1, with_ties = FALSE)$genre,
                                          "' has the lowest (", fmt(min(rel$med)), ")."),
               if (nrow(rel) >= 2) paste0("The most variable genre is '", slice_max(rel, iqr, n = 1, with_ties = FALSE)$genre,
                                          "' (IQR ", fmt(max(rel$iqr)), "), and the most consistent is '",
                                          slice_min(rel, iqr, n = 1, with_ties = FALSE)$genre, "' (IQR ", fmt(min(rel$iqr)), ")."),
               if (nrow(rel) >= 1) paste0("The single highest rating we see (", fmt(max(rel$mx)), ") belongs to a game in '",
                                          slice_max(rel, mx, n = 1, with_ties = FALSE)$genre, "'.")
             ),
             talk = c(
               "When the boxes overlap heavily, we conclude that the genres are similar in quality.",
               "A tall box tells us a genre has both standout hits and weaker entries, while a short box tells us it keeps a consistent standard.",
               "We pay special attention to the outlier dots, because those are the games worth naming."
             ),
             caveat = "We only show genres with at least 5 games, and because genre tags overlap, some games appear in several boxes."
           )
         },
         
         genre_votes = {
           gv <- gd |> filter(!is.na(votes)) |> group_by(genre) |>
             summarise(n = n(), med = median(votes), m = mean(rating, na.rm = TRUE), .groups = "drop") |>
             filter(n >= 5)
           A(
             shows = "In this chart we show the typical (median) audience size for games in each genre, in other words which genres draw the most votes.",
             findings = list(
               sel_note,
               if (nrow(gv) >= 2) paste0("We find that '", slice_max(gv, med, n = 1, with_ties = FALSE)$genre, "' draws the biggest typical audience (median ",
                                         fmt(max(gv$med), 0), " votes), and '", slice_min(gv, med, n = 1, with_ties = FALSE)$genre,
                                         "' the smallest (", fmt(min(gv$med), 0), ")."),
               if (nrow(gv) >= 2) paste0("The ratio between the largest and smallest genre medians is ", fmt(max(gv$med) / min(gv$med), 1), "x."),
               if (nrow(gv) >= 2) paste0("The most-voted genre is ",
                                         if (slice_max(gv, med, n = 1, with_ties = FALSE)$genre == slice_max(gv, m, n = 1, with_ties = FALSE)$genre)
                                           "also" else "not",
                                         " the highest-rated genre ('", slice_max(gv, m, n = 1, with_ties = FALSE)$genre, "').")
             ),
             talk = c(
               "We use this chart to separate 'mass-market' genres from 'critic's choice' genres: big audiences versus high ratings.",
               "We read it together with the average-rating-by-genre chart to compare popularity against quality.",
               "We use the median instead of the mean so that one mega-hit cannot dominate a genre."
             ),
             caveat = "We only show genres with at least 5 games, and genre tags overlap between games."
           )
         },
         
         genre_cooc = {
           pr <- cooc_pairs(gd)
           multi <- gd |> count(rank) |> summarise(multi = sum(n >= 2), tot = n())
           A(
             shows = "Here we show how often two genres are listed on the same game, for the 12 most common genres. Darker cells mean more shared games.",
             findings = list(
               sel_note,
               if (nrow(pr) >= 1) paste0("The most frequent pairing we find is '", pr$g1[1], "' + '", pr$g2[1], "' (", pr$n[1], " games)",
                                         if (nrow(pr) >= 3) paste0(", followed by '", pr$g1[2], "' + '", pr$g2[2], "' (", pr$n[2],
                                                                   ") and '", pr$g1[3], "' + '", pr$g2[3], "' (", pr$n[3], ").") else "."),
               paste0(multi$multi, " of our ", multi$tot, " games (", pct(multi$multi / multi$tot), ") have two or more genres in this view.")
             ),
             talk = c(
               "We see that genres rarely stand alone: games are often hybrids, and the strongest pairings show us which combinations audiences reward.",
               "We read dark rows as 'connector' genres that combine with almost everything.",
               "When we switch off Action and Adventure, we reveal the more specific pairings that were hidden behind them."
             ),
             caveat = "We limit this chart to the 12 most common genres, and a bright cell shows us frequency, not quality."
           )
         },
         
         ngenres_rating = {
           d <- games |> filter(!is.na(n_genres), !is.na(rating))
           s <- d |> group_by(n_genres) |> summarise(n = n(), m = mean(rating), .groups = "drop")
           rho <- spear(d$n_genres, d$rating)
           A(
             shows = "Here we ask whether games labelled with more genres tend to be rated higher or lower.",
             findings = list(
               paste0("Looking at games by genre count, we find: ", paste0(s$n_genres, " genres = ", s$n, " games (mean ", fmt(s$m), ")", collapse = "; "), "."),
               paste0("The Spearman correlation we measure between the number of genres and rating is ", fmt(rho), ", which we describe as ", strength(rho), " and ", direction(rho), "."),
               paste0("The highest average rating we see is for games with ", s$n_genres[which.max(s$m)], " genre(s) (", fmt(max(s$m)), ").")
             ),
             talk = c(
               "With this chart we test the idea that 'genre-blending' games are better received.",
               "If the correlation is negligible, we conclude that the number of labels is simply not what drives quality.",
               "We point to the sample sizes: we do not over-interpret groups with few games."
             ),
             caveat = "We should note that the number of genre tags depends on how IMDb labels a game, so it is not an objective measure of design complexity."
           )
         },
         
         year_rating = {
           d <- games |> filter(!is.na(year), !is.na(rating))
           yr <- d |> group_by(year) |> summarise(m = mean(rating), n = n(), .groups = "drop")
           yr3 <- filter(yr, n >= 3)
           fit <- lm(rating ~ year, data = d)
           p <- summary(fit)$coefficients[2, 4]
           A(
             shows = "In this chart we show the average rating of our games released in each year. The size of each point shows how many games our average is based on.",
             findings = list(
               paste0("The trend we fit is ", fmt(coef(fit)[[2]] * 10, 3), " rating points per decade (p = ", fmt(p, 3), "), which we find is ",
                      if (p < 0.05) "statistically significant." else "not statistically significant."),
               if (nrow(yr3) >= 2) paste0("Among years with at least 3 games, we see the best average in ", yr3$year[which.max(yr3$m)], " (",
                                          fmt(max(yr3$m)), ") and the lowest in ", yr3$year[which.min(yr3$m)], " (", fmt(min(yr3$m)), ")."),
               paste0("The year with the most games is ", yr$year[which.max(yr$n)], " (", max(yr$n), " games)."),
               paste0("Our data covers ", min(yr$year), " to ", max(yr$year), ", across ", nrow(yr), " distinct release years.")
             ),
             talk = c(
               "We use the trend line to answer a direct question: does quality improve, decline, or stay flat over time?",
               "We treat wobbles at small point sizes as noise, and we focus on years with larger dots.",
               "We link this to the release-count chart, because years with many entries give us more reliable averages."
             ),
             caveat = "We should note that newer games have had less time to collect votes, and fans of recent releases may rate differently from retro fans."
           )
         },
         
         year_count = {
           yc <- games |> filter(!is.na(year)) |> count(year)
           yy <- games$year[!is.na(games$year)]
           recent <- mean(yy >= max(yy) - 9)
           A(
             shows = "Here we count how many of our games were released in each year.",
             findings = list(
               paste0("The peak year is ", paste(yc$year[yc$n == max(yc$n)], collapse = " and "), ", with ", max(yc$n), " games."),
               paste0("The median release year is ", fmt(median(yy), 0), ". The earliest game we have is from ", min(yy), " and the latest from ", max(yy), "."),
               paste0(pct(recent), " of our games were released in the final 10 years of the data (", max(yy) - 9, "-", max(yy), ")."),
               paste0("We see ", nrow(yc), " distinct years represented.")
             ),
             talk = c(
               "We use this chart to see which eras the community considers the strongest in gaming.",
               "If we see a cluster in one period, we read it as a 'golden age', or simply as the period when most current IMDb voters grew up.",
               "We explain the gaps in early years by fewer games and fewer IMDb votes for them."
             ),
             caveat = "We should note that these counts reflect which games reached the IMDb Top 250, not the total number of games released in a year."
           )
         },
         
         decade_box = {
           d <- games |> filter(!is.na(decade), !is.na(rating))
           s <- d |> group_by(decade) |> summarise(n = n(), med = median(rating), .groups = "drop")
           kw <- tryCatch(kruskal.test(rating ~ factor(decade), data = d)$p.value, error = function(e) NA)
           A(
             shows = "Here we show the spread of ratings in each decade of release: the box is the middle 50%, the line is the median, and the points are individual games.",
             findings = list(
               paste0("We have this many games per decade: ", paste0(s$decade, "s = ", s$n, collapse = ", "), "."),
               paste0("The highest median rating is in the ", s$decade[which.max(s$med)], "s (", fmt(max(s$med)), "), and the lowest in the ",
                      s$decade[which.min(s$med)], "s (", fmt(min(s$med)), ")."),
               if (!is.na(kw)) paste0("Our Kruskal-Wallis test gives p = ", fmt(kw, 3), ", so we find the differences between decades are ",
                                      if (kw < 0.05) "statistically significant." else "not statistically significant.")
             ),
             talk = c(
               "We compare the medians first, and then we check whether the boxes overlap.",
               "We do not draw strong conclusions from a decade with few games.",
               "We combine this with the year-wise trend chart to get a smoother picture of change over time."
             ),
             caveat = "We should note that decades have very different numbers of games, so we cannot compare the boxes as if they had equal sample sizes."
           )
         },
         
         decade_pie = {
           d <- gd |> filter(!is.na(decade))
           top <- d |> count(decade, genre) |> group_by(decade) |> slice_max(n, n = 1, with_ties = FALSE) |> ungroup()
           cnt <- games |> filter(!is.na(decade)) |> count(decade)
           A(
             shows = "Here we show the mix of genres within each decade. Each pie shows the share of genre tags.",
             findings = c(
               list(sel_note),
               as.list(paste0("In the ", top$decade, "s (", cnt$n[match(top$decade, cnt$decade)], " games), the leading genre we see is '", top$genre,
                              "' with ", top$n, " tags (", pct(top$n / sapply(top$decade, function(x) sum(d$decade == x))), ")."))
             ),
             talk = c(
               "We watch how the dominant slices change, because this tells the story of how gaming evolved through its genres.",
               "Early decades have few games, so we treat their pies as very small samples.",
               "When we need to compare exact shares between decades, we switch to the stacked bar chart."
             ),
             caveat = "We should note that pie charts only show proportions: a decade with 5 games and one with 80 look equally 'full'."
           )
         },
         
         decade_prop = {
           d <- gd |> filter(!is.na(decade))
           dec <- d |> count(decade) |> filter(n >= 10)
           findings <- list(sel_note)
           if (nrow(dec) >= 2) {
             f <- min(dec$decade); l <- max(dec$decade)
             topg <- d |> count(genre, sort = TRUE) |> slice_head(n = 8) |> pull(genre)
             sh <- function(dc, g) sum(d$decade == dc & d$genre == g) / sum(d$decade == dc)
             ch <- tibble(genre = topg) |> mutate(a = map_dbl(genre, ~ sh(f, .x)), b = map_dbl(genre, ~ sh(l, .x)), diff = b - a)
             up <- slice_max(ch, diff, n = 1, with_ties = FALSE); dn <- slice_min(ch, diff, n = 1, with_ties = FALSE)
             findings <- c(findings, list(
               paste0("When we compare the ", f, "s with the ", l, "s, we see that '", up$genre, "' grew from ", pct(up$a), " to ", pct(up$b),
                      " of genre tags, the largest gain among the top genres."),
               paste0("'", dn$genre, "' moved from ", pct(dn$a), " to ", pct(dn$b), ", which is the largest decline."),
               paste0("For this comparison we only use decades with at least 10 genre tags (", paste0(dec$decade, "s", collapse = ", "), ").")
             ))
           } else findings <- c(findings, list("We have too little data per decade to compare genre shares."))
           A(
             shows = "In this chart each bar is a decade, split by the share of genre tags it contains, so we can see directly how the genre mix changes over time.",
             findings = findings,
             talk = c(
               "We read rising bands as genres gaining prominence, and shrinking bands as genres fading.",
               "Because we normalise the bars to 100%, they show us mix, not volume, so we cross-check the counts in the release chart.",
               "We toggle Action and Adventure to see whether the change in mix is real or just reflects those broad labels."
             ),
             caveat = "We should note that decades with few games produce volatile shares, so we treat the early decades as illustrative only."
           )
         },
         
         corr_heat = {
           m <- games |> transmute(Rank = rank, Rating = rating, `Votes (log10)` = log10(votes),
                                   Year = year, `# Genres` = n_genres)
           cm <- cor(m, use = "pairwise.complete.obs", method = "spearman")
           lo <- which(lower.tri(cm), arr.ind = TRUE)
           pairs <- tibble(a = rownames(cm)[lo[, 1]], b = colnames(cm)[lo[, 2]], r = cm[lo]) |> arrange(desc(abs(r)))
           f <- function(i) paste0(pairs$a[i], " vs ", pairs$b[i], ": r = ", fmt(pairs$r[i]), " (", strength(pairs$r[i]), " ", direction(pairs$r[i]), ")")
           A(
             shows = "Here we show the Spearman correlations between all of our numeric variables. Blue means they move together, red means they move in opposite directions, and white means they are unrelated.",
             findings = list(
               paste0("The strongest relationship we find is ", f(1), "."),
               if (nrow(pairs) >= 2) paste0("The second strongest is ", f(2), "."),
               if (nrow(pairs) >= 3) paste0("The third strongest is ", f(3), "."),
               paste0("The weakest relationship is ", f(nrow(pairs)), ".")
             ),
             talk = c(
               "We expect rank and rating to be negatively linked by construction: rank 1 is the best, so smaller rank numbers mean higher ratings.",
               "We look for unexpected pairs, such as votes and year, or rating and number of genres, because those are our real findings.",
               "We use Spearman because votes and years are skewed, and it measures consistent ordering rather than straight-line fit."
             ),
             caveat = "We cannot claim causation from correlation, and the restricted range of a Top-250 list shrinks the correlations we measure."
           )
         },
         
         A("We have no analysis available for this chart.", list(), character(), "")
  )
}

render_analysis <- function(a, title) {
  tagList(
    h3(title),
    h5("What the chart shows"), p(a$shows),
    h5("Key findings"),
    tags$ul(lapply(a$findings, tags$li)),
    h5("Interpretations"),
    tags$ul(lapply(a$talk, tags$li)),
    h5("Caveats"), p(a$caveat)
  )
}

# ------------------------------------------------------------------
# UI
# ------------------------------------------------------------------
ui <- page_sidebar(
  title = "IMDb Top 250 Video Games Explorer",
  theme = bs_theme(bootswatch = "flatly"),
  sidebar = sidebar(
    width = 320,
    selectInput("plot_id", "Choose a plot", choices = plot_groups),
    input_switch("include_aa", "Include Action & Adventure genres", value = TRUE),
    helpText("The toggle applies to the genre-based plots and their analyses."),
    hr(),
    h6("Rating summary"),
    tableOutput("stats")
  ),
  navset_card_tab(
    nav_panel("Plot", plotOutput("main_plot", height = "650px")),
    nav_panel("Analysis", uiOutput("analysis_ui")),
    nav_panel("Data", DTOutput("data_table"))
  )
)

# ------------------------------------------------------------------
# SERVER
# ------------------------------------------------------------------
server <- function(input, output, session) {
  
  gd <- reactive({
    if (input$include_aa) games_genre
    else games_genre |> filter(!genre %in% c("Action", "Adventure"))
  })
  
  plot_label <- reactive(names(all_choices)[match(input$plot_id, all_choices)])
  current_plot <- reactive(make_plot(input$plot_id, games, gd(), input$include_aa))
  analysis <- reactive(make_analysis(input$plot_id, games, gd(), input$include_aa))
  
  output$main_plot   <- renderPlot(current_plot())
  output$analysis_ui <- renderUI(render_analysis(analysis(), plot_label()))
  
  output$stats <- renderTable({
    data.frame(
      Statistic = c("Mean", "Median", "Variance", "Std. dev."),
      Value = round(c(mean(games$rating, na.rm = TRUE), median(games$rating, na.rm = TRUE),
                      var(games$rating, na.rm = TRUE), sd(games$rating, na.rm = TRUE)), 3)
    )
  })
  
  output$data_table <- renderDT(
    datatable(games, options = list(pageLength = 15, scrollX = TRUE), rownames = FALSE)
  )
  
  output$dl_plot <- downloadHandler(
    filename = function() paste0(input$plot_id, ".png"),
    content = function(file) ggsave(file, current_plot(), width = 11, height = 7, dpi = 150)
  )
  
  output$dl_analysis <- downloadHandler(
    filename = function() paste0(input$plot_id, "_analysis.html"),
    content = function(file) {
      htmltools::save_html(
        tagList(tags$head(tags$meta(charset = "utf-8")),
                tags$body(style = "font-family:sans-serif;max-width:800px;margin:2em auto;",
                          render_analysis(analysis(), plot_label()))),
        file
      )
    }
  )
}

shinyApp(ui, server)