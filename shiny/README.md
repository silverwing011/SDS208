# IMDb Top 250 Video Games Explorer

An interactive **R Shiny application** for exploring IMDb's Top 250
Rated Video Games dataset through statistical summaries, dynamic
visualizations, genre comparisons, and an interactive data table.

The project was developed by **Team 7** for **SDS208 --- Data Science
Lab I** at the **Indian Institute of Technology Kanpur**, under the
guidance of **Dr. Satya Singh**.

## Project Overview

This project turns an exploratory analysis of IMDb's Top 250 video games
into an interactive analytical application. Instead of relying only on a
fixed set of charts, users can select visualizations, change the scope
of genre analysis, read automatically generated interpretations, and
inspect the underlying records.

The Shiny application is the main deliverable. The accompanying R
Markdown report documents the data pipeline, application architecture,
statistical methods, findings, limitations, and reproducibility.

### What the application offers

-   **18 selectable visualizations** organized into four groups.
-   A switch to include or exclude the **Action** and **Adventure**
    genre tags in genre-focused analysis.
-   Dynamic statistical findings and explanatory text corresponding to
    the selected visualization.
-   A **Plot** view for visual exploration.
-   An **Analysis** view for generated interpretation.
-   A **Data** view with an interactive table.
-   A rating summary and data-download functionality.

## Analytical Views

The plot selector groups the visualizations as follows.

  -----------------------------------------------------------------------
  Category                            Visualizations
  ----------------------------------- -----------------------------------
  Distributions                       Rating distribution (histogram);
                                      votes distribution (log scale)

  Popularity & ranking                Top 20 most-voted games; top 15
                                      highest-rated games; IMDb rank
                                      vs. rating; IMDb rank vs. votes
                                      (log scale); votes vs. rating with
                                      trend line

  Genres                              Genre counts; genre distribution;
                                      average rating by genre; rating
                                      spread by genre; median votes by
                                      genre; number of genres vs. rating

  Time                                Year-wise mean rating; games
                                      released per year; rating by
                                      decade; genre distribution by
                                      decade; genre share by decade
  -----------------------------------------------------------------------

The analysis includes descriptive statistics, Spearman rank
correlations, trend lines, genre frequencies, genre co-occurrence, and
comparisons across release years and decades. The Action & Adventure
switch changes the genre scope for the relevant genre analyses; it does
not remove those games from the overall dataset.

## Dataset

The project works with a cleaned dataset of **250 games**. The supplied
CSV contains these fields:

  Column     Description
  ---------- --------------------------------------
  `rank`     Position in the Top 250 list
  `name`     Video game title
  `rating`   IMDb user rating
  `votes`    Number of IMDb votes
  `genre`    Comma-separated genre labels
  `year`     Release year
  `decade`   Decade derived from the release year

The application also derives `n_genres`, the number of genre labels
associated with each game, during data preparation.

### Data source and scope

The source material is a saved IMDb list page titled **IMDb Top 250
Rated Video Games**. The list's accompanying description states that it
is an unofficial user-rated list, includes games with at least 1,000
votes, and represents its ranking as of **April 10, 2026**. It also
notes that the list may not be complete or perfectly classified.

The project uses the supplied local HTML snapshot as a fallback source
and prefers the cleaned CSV for normal execution. Ratings, vote counts,
genres, and titles therefore describe the supplied snapshot; they should
not be assumed to be live IMDb values.

## Data Processing Workflow

1.  **Load data:** Read `IMDb_Video_Game_Cleaned_Data.csv` when it is
    available.
2.  **Fallback extraction:** If the CSV is unavailable, parse the saved
    IMDb HTML snapshot with `rvest`.
3.  **Structured metadata:** Extract rating, vote count, and genre
    information from JSON-LD embedded in the HTML using `jsonlite`.
4.  **Create derived variables:** Calculate the release decade and
    number of genre labels.
5.  **Reshape genres:** Split comma-separated genre values into
    individual rows for genre-level analysis.
6.  **Analyze and visualize:** Use the prepared game-level and
    genre-level data to generate plots and analytical summaries.

The game-level dataset is retained for analyses at the game level. A
separate long-format genre dataset is used where a game can contribute
to more than one genre.

## Technology Stack

  Tool / Package   Role
  ---------------- --------------------------------------------------------------
  R                Data processing, statistical analysis, and application logic
  Shiny            Interactive web application
  bslib            Page layout and Bootstrap theme
  tidyverse        Data manipulation and transformation
  rvest            HTML parsing and extraction
  jsonlite         Reading JSON-LD metadata
  ggplot2          Statistical visualizations (through tidyverse)
  scales           Axis labels and number formatting
  DT               Interactive data table
  rmarkdown        Project report generation

## Repository Structure

Keep the following files together in the project directory for the
simplest setup:

``` text
project/
├── final_project.R
├── IMDb_Video_Game_Cleaned_Data.csv
├── IMDb Top 250 Rated Video Games.html
├── Project Report.Rmd
└── Project-Report.html
```

-   `final_project.R` --- Shiny application source code.
-   `IMDb_Video_Game_Cleaned_Data.csv` --- cleaned dataset used by the
    application.
-   `IMDb Top 250 Rated Video Games.html` --- saved source-page snapshot
    used as a fallback if the CSV is absent.
-   `Project Report.Rmd` --- reproducible project report source.
-   `Project-Report.html` --- rendered HTML report.

The application code currently defines the CSV path as
`IMDb_Video_Game_Cleaned_Data.csv` and the HTML fallback path as a local
path. If you use a different folder or machine, update `HTML_PATH` in
`final_project.R` to the location of the saved HTML file. Keeping the
HTML snapshot beside the R script and setting `HTML_PATH` to that
relative filename is a portable option.

## Setup and Installation

### 1. Install R

Install a recent version of [R](https://cran.r-project.org/) and,
optionally, [RStudio
Desktop](https://posit.co/download/rstudio-desktop/).

### 2. Install the required packages

Run this in the R console:

``` r
install.packages(c(
  "shiny",
  "bslib",
  "rvest",
  "jsonlite",
  "tidyverse",
  "scales",
  "DT",
  "rmarkdown"
))
```

### 3. Prepare the project files

Place `final_project.R` and `IMDb_Video_Game_Cleaned_Data.csv` in the
same directory. The CSV is the preferred data source.

If you want to retain the HTML fallback, also place the saved IMDb HTML
file in the project directory and update `HTML_PATH` in
`final_project.R` to point to it. The application stops with a
data-not-found error if neither configured source is available.

## Run the Shiny Application

Open the project directory in RStudio, then run:

``` r
shiny::runApp()
```

Alternatively, open `final_project.R` and execute it in RStudio. The
script ends by launching the app with `shinyApp(ui, server)`.

Once the application opens, select a plot category and visualization
from the sidebar. Use the Action & Adventure switch to compare
genre-based results, then explore the Plot, Analysis, and Data views.

## Render the Project Report

The R Markdown report uses the cleaned CSV. Keep the report and CSV in
the same directory (or use one of the alternative locations handled in
the report's setup chunk).

Render it from R with:

``` r
rmarkdown::render("Project Report.Rmd")
```

The report produces an HTML document. Its setup also loads the packages
needed for the report and prepares the derived variables and long-format
genre data.

## Important Functions and Application Design

  -----------------------------------------------------------------------
  Function / component                Purpose
  ----------------------------------- -----------------------------------
  `scrape_games()`                    Extract game titles, years,
                                      ratings, votes, and genres from the
                                      saved HTML snapshot

  `load_games()`                      Load the cleaned CSV first, or use
                                      the HTML fallback

  `cooc_pairs()`                      Identify genre pairs that occur
                                      together in games

  `make_plot()`                       Generate the selected visualization

  `make_analysis()`                   Generate numerical findings,
                                      presentation notes, and caveats for
                                      the selected analysis

  `reactive()`                        Recompute outputs when relevant
                                      user inputs change

  `renderPlot()`                      Display the selected plot

  `renderUI()`                        Display generated analysis content

  `renderDT()`                        Render the interactive data table
  -----------------------------------------------------------------------

The application follows this general flow:

``` text
CSV / saved HTML
       |
   load_games()
       |
 Data preparation
       |
 games + games_genre
       |
 User selects plot / genre option
       |
 Reactive calculations
       |
  +----+----------------+
  |                     |
make_plot()       make_analysis()
  |                     |
Plot view          Analysis view

Prepared data ------------> Data view
```

## Interpretation and Limitations

Please keep the following limitations in mind when interpreting the
results:

-   **Selection bias:** This is a selected Top 250 list, not a random
    sample of all video games. Findings should not be generalized to the
    entire video-game industry.
-   **Restricted rating range:** Because the dataset contains highly
    rated games by construction, its rating distribution and
    correlations may differ from those of all games.
-   **Non-exclusive genres:** A game can have several genre labels.
    Genre counts represent genre associations, not mutually exclusive
    categories.
-   **Vote counts are not quality measures:** Votes indicate audience
    participation and exposure; they do not independently establish game
    quality.
-   **Rank and rating are related:** IMDb rank is based on the rating
    system and voting population, so rank and rating are not independent
    measurements.
-   **Descriptive analysis:** Correlation and trend lines describe
    associations; they do not establish causation.
-   **Snapshot data:** The supplied HTML page is a saved snapshot. The
    application does not continuously refresh IMDb data.

## Team

**Team 7 --- Indian Institute of Technology Kanpur**

-   Adinath Bhadane
-   Ankit Samanta
-   Anagh Atri
-   Chaitanya Malhotra
-   Deepak Bihani

**Course:** SDS208 --- Data Science Lab I\
**Guidance:** Dr. Satya Singh

## Acknowledgements

-   IMDb for the source list and game metadata represented in the
    supplied snapshot.
-   The R and RStudio package ecosystem used to build the
    data-processing workflow, visualizations, report, and Shiny
    application.

------------------------------------------------------------------------

*This repository contains an academic data-science project. IMDb
ratings, rankings, and vote counts are user-generated and may change
over time.*
