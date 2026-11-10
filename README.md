# IMDb Top 250 Video Games — Web Scraping, Exploratory Analysis & Interactive Explorer

An academic data science project that began with **web scraping and exploratory data analysis** of IMDb's Top 250 Rated Video Games and was later extended into an **interactive R Shiny application**.

The project consists of two stages:

1. **Initial Stage — Web Scraping and Exploratory Data Analysis:** Extract game information from a saved IMDb page, create a cleaned dataset, perform statistical analysis, generate exploratory visualizations, and export analysis-ready CSV files.
2. **Extended Stage — Interactive Shiny Application:** Extend the initial work by developing an interactive application with selectable visualizations, dynamic statistical interpretations, genre comparisons, and an interactive data table.

Developed by **Team 7** for **SDS208 — Data Science Lab I** at the **Indian Institute of Technology Kanpur**, under the guidance of **Dr. Satya Singh**.

---

## Project at a Glance

| Item | Details |
|---|---|
| Topic | IMDb Top 250 Rated Video Games |
| Programming Language | R |
| Initial Work | Web Scraping and Exploratory Data Analysis |
| Extended Work | Interactive R Shiny Application |
| Dataset Size | 250 Games |
| Institution | Indian Institute of Technology Kanpur |
| Course | SDS208 — Data Science Lab I |
| Team | Team 7 |

---

## Project Evolution

### Stage 1: Web Scraping and Exploratory Data Analysis

The project initially focused on collecting and exploring information about games listed in IMDb's Top 250 Rated Video Games.

The script `web_scrapping.R` reads a saved HTML snapshot of the IMDb list and extracts relevant information.

**Workflow:**

1. Read the saved IMDb HTML page using `rvest`.
2. Extract game titles and release years from the HTML structure.
3. Extract ratings, vote counts, and genres from embedded JSON-LD metadata using `jsonlite`.
4. Combine the extracted information into a structured dataset.
5. Assign ranks to the games.
6. Calculate the release decade from the release year.
7. Perform statistical analysis and exploratory data visualization.
8. Export the cleaned dataset and additional summary datasets as CSV files.

#### Exploratory Analysis

The initial analysis includes:

- Mean, median, variance, and standard deviation of IMDb ratings.
- Distribution of IMDb ratings.
- Top 20 games by number of IMDb votes.
- Relationship between IMDb rank and rating.
- Correlation between ratings and vote counts.
- Genre counts and genre distributions.
- Genre analysis with and without Action and Adventure.
- Average IMDb rating by genre.
- Year-wise mean IMDb rating.
- Genre distribution across different decades.

#### Outputs from Stage 1

The scraping script generates the following
