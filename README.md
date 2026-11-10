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

The scraping script generates the following CSV files:

| File | Description |
|---|---|
| `IMDb_Video_Game_Cleaned_Data.csv` | Main cleaned dataset |
| `IMDb_Year_Wise_Mean_Rating.csv` | Mean rating and number of games by year |
| `IMDb_Genre_Count_All.csv` | Genre counts including Action and Adventure |
| `IMDb_Genre_Count_Without_Action_Adventure.csv` | Genre counts excluding Action and Adventure |
| `IMDb_Decade_Wise_Genre_Count_All_Genres.csv` | Genre counts by decade |
| `IMDb_Decade_Wise_Genre_Count_Without_Action_Adventure.csv` | Genre counts by decade, excluding Action and Adventure |

The cleaned dataset generated in this stage became the primary data source for the extended Shiny application.

---

### Stage 2: Extended Project — Interactive R Shiny Application

The final project extends the initial scraping and exploratory analysis into an interactive data exploration platform.

Instead of presenting only fixed visualizations, the extended application allows users to select different analyses, explore relationships between variables, compare genres, and view dynamically generated statistical interpretations.

The application is developed using `shiny` and is implemented in `final_project.R`.

#### Key Features

- 18 selectable visualizations organized into four categories.
- Option to include or exclude Action and Adventure from genre-focused analysis.
- Dynamic statistical summaries and interpretations.
- Separate Plot, Analysis, and Data views.
- Interactive data table using `DT`.
- IMDb rating summary.
- Data download functionality.
- Automatic loading of the cleaned CSV dataset.
- HTML-based fallback data extraction if the CSV is unavailable.

#### Visualizations

| Category | Visualizations |
|---|---|
| Distributions | Rating Distribution, Votes Distribution |
| Popularity & Ranking | Top 20 Most-Voted Games, Top 15 Highest-Rated Games, Rank vs Rating, Rank vs Votes, Votes vs Rating |
| Genres | Genre Counts, Genre Distribution, Average Rating by Genre, Rating Spread by Genre, Median Votes by Genre, Number of Genres vs Rating |
| Time | Year-wise Mean Rating, Games Released per Year, Rating by Decade, Genre Distribution by Decade, Genre Share by Decade |

The application also contains additional analysis logic for genre co-occurrence and a Spearman correlation matrix.

---

## Dataset Description

The cleaned dataset contains 250 video games with the following variables:

| Column | Description |
|---|---|
| `rank` | Position in the IMDb Top 250 list |
| `name` | Name of the video game |
| `rating` | IMDb user rating |
| `votes` | Number of IMDb votes |
| `genre` | Genre or genres associated with the game |
| `year` | Release year |
| `decade` | Decade derived from the release year |

The Shiny application additionally derives `n_genres`, representing the number of genres associated with each game.

For genre-specific analysis, multiple genre labels are separated into individual observations.

### Data Source

The project uses a saved HTML snapshot of IMDb's Top 250 Rated Video Games list.

The supplied source page describes the list as unofficial, includes games with at least 1,000 votes, and identifies the ranking snapshot as **April 10, 2026**.

**Note:** The project uses saved webpage data rather than continuously updated live IMDb information. Therefore, rankings, ratings, and vote counts represent the supplied snapshot.

---

## Project Workflow

```text
             IMDb Saved HTML Page
                       |
                       v
                web_scrapping.R
                       |
                       v
                Data Extraction
                       |
                       v
                 Data Cleaning
                       |
                       v
            Exploratory Data Analysis
                       |
                       v
             Statistical Visualizations
                       |
                       v
             Cleaned CSV Dataset
                       |
                       v
                final_project.R
                       |
                       v
              Interactive Shiny App
                       |
             +---------+---------+
             |         |         |
             v         v         v
            Plot    Analysis    Data
```

---

## Technology Stack

| Technology / Package | Purpose |
|---|---|
| R | Data processing and statistical analysis |
| `rvest` | HTML parsing and web scraping |
| `jsonlite` | Extracting JSON-LD metadata |
| `tidyverse` | Data manipulation and visualization |
| `ggplot2` | Statistical graphics |
| `scales` | Formatting plot axes and labels |
| `shiny` | Interactive web application |
| `bslib` | Shiny interface and Bootstrap styling |
| `DT` | Interactive data tables |
| `rmarkdown` | Project report generation |

---

## Repository Structure

```text
project/
│
├── web_scrapping.R
├── final_project.R
│
├── IMDb_Video_Game_Cleaned_Data.csv
├── IMDb Top 250 Rated Video Games.html
│
├── Project Report.Rmd
├── Project-Report.html
│
├── IMDb_Year_Wise_Mean_Rating.csv
├── IMDb_Genre_Count_All.csv
├── IMDb_Genre_Count_Without_Action_Adventure.csv
├── IMDb_Decade_Wise_Genre_Count_All_Genres.csv
└── IMDb_Decade_Wise_Genre_Count_Without_Action_Adventure.csv
```

### Important Files

- **`web_scrapping.R`** — Initial web scraping, data cleaning, exploratory analysis, and CSV generation.
- **`final_project.R`** — Extended interactive Shiny application.
- **`IMDb_Video_Game_Cleaned_Data.csv`** — Main cleaned dataset used by the application.
- **`IMDb Top 250 Rated Video Games.html`** — Saved source webpage.
- **`Project Report.Rmd`** — R Markdown source file.
- **`Project-Report.html`** — Rendered project report.
- **Other CSV files** — Summary datasets generated during the initial analysis.

---

## Installation and Setup

### 1. Install R

Download and install R from:

https://cran.r-project.org/

RStudio Desktop is also recommended:

https://posit.co/download/rstudio-desktop/

### 2. Install Required Packages

Run the following command in the R console:

```r
install.packages(c(
  "rvest",
  "jsonlite",
  "tidyverse",
  "shiny",
  "bslib",
  "scales",
  "DT",
  "rmarkdown"
))
```

### 3. Prepare the Project Files

Keep the R scripts, cleaned CSV dataset, and saved IMDb HTML file in the project directory.

The original scripts contain a machine-specific Windows HTML path:

```r
"D:/IMDb Top 250 Rated Video Games.html"
```

Update this path in `web_scrapping.R` and the `HTML_PATH` setting in `final_project.R` according to your computer.

For example:

```r
HTML_PATH <- "IMDb Top 250 Rated Video Games.html"
```

### 4. Run Stage 1: Web Scraping

Open `web_scrapping.R` in RStudio and execute the script.

It will:

- Read the saved IMDb webpage.
- Extract game information.
- Clean and transform the dataset.
- Generate exploratory visualizations.
- Calculate statistical summaries.
- Export the cleaned dataset and additional CSV files.

### 5. Run Stage 2: Shiny Application

Make sure `final_project.R` and `IMDb_Video_Game_Cleaned_Data.csv` are available in the same project directory.

Run:

```r
shiny::runApp()
```

Alternatively, open and execute `final_project.R` in RStudio.

The application first attempts to load the cleaned CSV dataset. If the CSV is unavailable, it attempts to extract the data from the saved HTML page using the configured path.

### 6. Generate the Project Report

To render the R Markdown report, run:

```r
rmarkdown::render("Project Report.Rmd")
```

This generates the HTML report.

---

## Important Functions

| Function | Purpose |
|---|---|
| `get_year()` | Extracts release years from HTML game entries |
| `json_to_df()` | Converts JSON-LD metadata into a data frame |
| `scrape_games()` | Extracts game information from the saved HTML page in the extended application |
| `load_games()` | Loads the cleaned dataset or uses the HTML fallback |
| `cooc_pairs()` | Identifies genre pairs occurring together |
| `make_plot()` | Generates the selected visualization |
| `make_analysis()` | Generates statistical interpretations |
| `reactive()` | Updates outputs based on user selections |
| `renderPlot()` | Displays plots |
| `renderUI()` | Displays dynamic analysis |
| `renderDT()` | Displays the interactive data table |

---

## Limitations

- **Selection Bias:** The dataset contains only the Top 250 games, not a random sample of all video games.
- **Restricted Rating Range:** The selected games are already highly rated, which affects the interpretation of rating distributions and correlations.
- **Multiple Genres:** A game can belong to multiple genres, so genre counts are not mutually exclusive.
- **Vote Counts:** The number of votes indicates audience participation and popularity, not necessarily game quality.
- **Rank and Rating:** IMDb rank and rating are related measures and should not be interpreted as independent variables.
- **Correlation vs Causation:** Statistical associations do not establish causal relationships.
- **Static Data:** The analysis is based on a saved IMDb snapshot, not continuously updated live data.
- **HTML Structure:** Changes to IMDb's webpage structure or JSON-LD metadata may require modifications to the scraping code.
- **Local File Paths:** The original scripts use local file paths that must be updated when running the project on another computer.

---

## Team Members

**Team 7 — Indian Institute of Technology Kanpur**

1. Adinath Bhadane
2. Ankit Samanta
3. Anagh Atri
4. Chaitanya Malhotra
5. Deepak Bihani

**Course:** SDS208 — Data Science Lab I  
**Institution:** Indian Institute of Technology Kanpur  
**Guided by:** Dr. Satya Singh

---

## Acknowledgements

- IMDb for the source list and game metadata used in the project.
- The R and RStudio ecosystem and the developers of the packages used for data extraction, analysis, visualization, and application development.

---

*This repository presents an academic data science project demonstrating the progression from web scraping and exploratory data analysis to an interactive Shiny application.*
