# Netflix Content Additions Analysis

**Python · MySQL · Tableau Public**

This project analyzes approximately 8,800 Netflix titles to understand how recorded content additions changed over time and which content types, ratings, genres, and country associations contributed the most to those additions.

[View the Interactive Tableau Dashboard](https://public.tableau.com/app/profile/brandon.marron8358/viz/NetflixProject_17919232967500/Dashboard1)

![Netflix Content Additions Dashboard](<img width="1303" height="1046" alt="image" src="https://github.com/user-attachments/assets/cea0a414-f397-4f17-a71f-4246f7b97112" />)


---

## 1. Project Overview

In this project, we examined how Netflix’s recorded content additions changed over time. Our analysis focused mainly on content type, ratings, genre/category classifications, and country associations to identify which areas contributed the most to Netflix’s recorded additions.

We began with a raw Netflix dataset obtained from Kaggle. We first loaded the data into Python using Pandas for cleaning and validation. After cleaning the data, we moved it into MySQL, modeled it into relational tables, and performed our analysis. Finally, we exported the SQL results and visualized them in an interactive Tableau Public dashboard.

The goal of the project was not only to create a dashboard, but to build an end-to-end data analysis workflow from raw data to final business insights.

---

## 2. Business Question

>**How have Netflix’s content additions changed over time, and which genres, countries, ratings, and content types have contributed most to those additions?**

To address this question, we broke the analysis into five main areas:

1. How did the number of recorded Netflix additions change over time?
2. How did the share of Movies and TV Shows change?
3. Which content ratings made up the largest share of additions?
4. Which genres/categories consistently contributed the most additions?
5. Which country associations appeared most frequently among added titles?

---

## 3. Dataset

**Dataset Source:** [Kaggle Dataset](https://www.kaggle.com/datasets/debayank2024/netflix-movies-and-series)

The original dataset contains approximately 8,800 Netflix title records.

Some of the key variables used in this project include:

| Variable | Description |
|---|---|
| `show_id` | Unique identifier for a Netflix title/listing |
| `type` | Identifies whether a title is a Movie or TV Show |
| `title` | Name of the title |
| `country` | Country or countries associated with the title |
| `date_added` | Date the title was recorded as being added to Netflix |
| `rating` | Content rating such as TV-MA, TV-14, PG, R, etc. |
| `listed_in` | Netflix genre/category classifications associated with the title |

> **Important:** `date_added` represents when a title was recorded as being added to Netflix in this dataset. It does **not** represent when the title was originally released.

---

## 4. Tools Used

| Tool | Purpose |
|---|---|
| **Google Colab / Python / Pandas** | Data cleaning, validation, and preparation |
| **MySQL** | Relational data modeling, transformations, and analytical queries |
| **Tableau Public** | Data visualization and interactive dashboard creation |
| **GitHub** | Project documentation and organization |


---

## 5. Project Workflow

```text
Raw CSV
   ↓
Python / Pandas
Cleaning & Validation
   ↓
Cleaned Master Dataset
   ↓
MySQL Database
   ↓
Relational Data Modeling
   ├── netflix_titles_base
   ├── netflix_title_genre
   └── netflix_title_country
   ↓
SQL Analysis
   ↓
Analysis-Ready CSV Exports
   ↓
Tableau Public Dashboard
   ↓
Final Findings
```
---

## 6. Data Cleaning and Preparation

Title Standardization and Duplicate Handling

We first standardized the title column to remove unnecessary whitespace and non-breaking spaces.

```python
df["title"] = (
    df["title"]
    .str.replace("\xa0", " ", regex=False)
    .str.strip()
)
```

The show_id field uniquely identifies each record, so we didn't automatically treat titles with the same name as duplicates. For example, two records could have the same title while representing different content types or different catalog addition records.

Because of this, we investigated repeated titles rather than simply deleting every repeated title name.

We removed a record only when the remaining fields showed it was a true duplicate, not a separate Netflix listing or addition record.

This prevented us from accidentally removing legitimate records that shared the same title.

---

### Correcting the Rating Column

While reviewing the data, we found a small number of records where duration values had incorrectly been placed in the `rating` column.

For example, values representing minutes clearly belonged in `duration` rather than `rating`.

We corrected these records by moving the misplaced duration values to the appropriate column and replacing the incorrect rating values with null.

This prevented invalid rating categories from appearing in later analysis.

---

### Date Standardization and Preparation

The `date_added` field was originally stored as text.

We first removed unnecessary whitespace, then converted the field to a proper datetime format using Pandas.

```python
df["date_added"] = pd.to_datetime(df["date_added"])
```

From date_added, we created additional fields for:

- `day_added`
- `month_added`
- `year_added`

These fields allowed us to perform time-based analysis of Netflix’s recorded additions.

---

### Country Data

Some titles were associated with multiple countries.

For example:
```text
United States, United Kingdom, Ireland
```

Keeping multiple countries inside a single field makes country-level analysis difficult. To solve this, we created a separate title_country dataset containing only:
```text
show_id
country
```

The country values were split using:
```python
.str.split(",")
```
The resulting lists were expanded using:
```python
.explode()
```
We then removed unnecessary whitespace from each country value.

This allowed one title to maintain multiple valid country relationships without duplicating the title itself in the main dataset.

---

### Genre and Category Data

The source dataset uses the field listed_in rather than a field explicitly named genre.

For analysis purposes, we treated these values as Netflix genre/category classifications and created a separate title-to-genre dataset.

Like the country field, one title could contain several classifications. We split and expanded the values into a separate dataset containing:
```text
show_id
genre
```
The generic classifications:
```text
Movies
TV Shows
```
were removed from the genre analysis because the `type` field already identifies whether a record is a Movie or TV Show.

This prevented redundant information from being counted as a genre/category.

---

## 7. Data Modeling

After cleaning the dataset, we created a relational structure in MySQL.

Our primary table was:
```text
netflix_titles_base
```
This table maintains one row per Netflix title record.

Two additional bridge tables were created:
```text
netflix_title_genre
netflix_title_country
```
The resulting structure was:

                  netflix_titles_base
                         │
                 ┌───────┴───────┐
                 │               │
                 ▼               ▼
      netflix_title_genre   netflix_title_country

This structure was important because both genre and country are multi-valued fields.

Originally, exploding both genre and country into a single dataset created **row multiplication**. For example, a title with three country associations and four genre classifications could incorrectly become twelve rows.

Separating these relationships into individual bridge tables kept the main table at one row per title while still letting us analyze every country and genre associated with that title.

Before using the bridge tables for analysis, we also checked for duplicate relationship pairs:
```sql
(show_id, genre)
(show_id, country)
```
This helped ensure that duplicate relationships didn’t inflate genre and country counts.

---

## 8. SQL Analysis

After modeling the data, we used MySQL to answer the project’s business question.

Some of the SQL techniques used throughout the analysis included:

- `GROUP BY` aggregations
- joins across relational tables
- Common Table Expressions (CTEs)
- recursive CTEs
- window functions
- `LAG()` for year-over-year analysis
- `DENSE_RANK()` for Top 5 rankings
- `COALESCE()` for missing categories
-  division-by-zero protection
-  handling partial-year data for 2021

The complete SQL analysis can be found here:

[View SQL Analysis](SQL ANALYSIS LINK)

### Overall Growth

We calculated:

- total titles added per year
- total titles added per month
- year-over-year absolute changes
- year-over-year percentage changes

Because the dataset ends in September 2021, full-year YoY comparisons were protected from treating 2021 as a complete year.

---

### Content Type

We analyzed the number and percentage of:
```text
Movies
TV Shows
```
added each year.

This let us see not only which content type had more additions, but also how the composition of annual additions changed over time.

---

### Ratings

We analyzed:

- titles added per rating per year
- each rating’s percentage of yearly additions
- year-over-year changes by rating

We represented missing ratings as `Unknown` when calculating yearly rating composition so they remained visible rather than silently disappearing from the denominator.

---

### Genres

Using `netflix_title_genre`, we analyzed:

- title counts by genre/category and year
- each genre’s share of yearly title additions
- Top 5 genre/category classifications by year
- year-over-year genre changes

Because a title can have multiple genre/category classifications, genre percentages are **not mutually exclusive** and should not be expected to sum to 100%.

---

### Countries

Using `netflix_title_country`, we analyzed:

- title counts by country association and year
- each country’s share of yearly additions
- Top 5 country associations by year
- year-over-year country changes

Like genres, one title can be associated with multiple countries. Therefore, country percentages are also not mutually exclusive.

---

## 9. Tableau Dashboard

After completing the SQL analysis, we exported five analysis-ready datasets from MySQL and brought them into Tableau Public.

[View the Interactive Tableau Dashboard](https://public.tableau.com/app/profile/brandon.marron8358/viz/NetflixProject_17919232967500/Dashboard1)

![Netflix Content Additions Dashboard](<img width="1303" height="1046" alt="image" src="https://github.com/user-attachments/assets/cea0a414-f397-4f17-a71f-4246f7b97112" />)

The final dashboard contains five main visualizations:

| Visualization | Purpose |
|---|---|
| **Titles Added by Year** | Shows overall recorded addition volume over time |
| **Movie vs. TV Show Share** | Shows changes in yearly content-type composition |
| **Rating Share by Year** | Shows how ratings contributed to yearly additions |
| **Top 5 Genres by Year** | Shows the leading genre/category contributors |
| **Top 5 Country Associations by Year** | Shows changes among the leading country associations |


Rating, genre, country, and content-composition views focus primarily on 2015–2021 because the earlier years contain relatively few recorded additions.

---

## 10. Key Findings

### 1. Recorded additions grew rapidly before peaking in 2019

Recorded additions increased from **82 titles in 2015 to 2,015 titles in 2019**, the highest full-year total in the dataset.

Additions then decreased **6.7% to 1,879 titles in 2020**.

The dataset therefore shows rapid expansion in recorded additions, followed by a slowdown after the 2019 peak.

---

### 2. Movies remained the majority of yearly additions

Movies accounted for most recorded additions throughout the 2015–2021 analysis period.

TV Shows reached their highest share in **2016 at 41.0%**, fell to **25.0% in 2018**, and later represented **33.7% of 2021 YTD additions**.

This shows that although Movies consistently remained the majority, the Movie/TV Show composition changed throughout the period.

---

### 3. TV-MA consistently dominated the rating mix

TV-MA represented roughly **one-third to two-fifths of annual additions** throughout the analysis period, making it the most consistently dominant rating.

R-rated content increased from **3.7% of additions in 2015** to **12.7% in 2021 YTD**.

Meanwhile, NR-rated additions declined substantially over the same period and recorded no new additions in 2020 or 2021 YTD.

---

### 4. International Movies, Dramas, and Comedies consistently led genre additions

International Movies, Dramas, and Comedies repeatedly appeared among the leading Netflix genre/category classifications.

International Movies led from 2017 through 2020 before Dramas narrowly moved ahead in **2021 YTD**, with:
```text
Dramas:               412 titles
International Movies: 408 titles
```
This suggests that the same major genre/category groups consistently drove a large portion of additions, although their relative ranking changed over time.

---

### 5. The United States remained the leading country association

The United States ranked **#1 in country association throughout 2015–2021**.

India held the #2 position for several later years, but in **2021 YTD the United Kingdom moved into the #2 position while India moved to #3**.

While the United States remained consistently dominant, the rankings below it changed over time.

---

## 11. Limitations

The dataset has several limitations that affect the conclusions we can draw from the analysis.

### Recorded Additions Are Not Catalog Size

The dataset includes `date_added`, but not dates when titles were removed.

As a result, we cannot reconstruct Netflix’s total catalog size or calculate net catalog growth.

The analysis therefore focuses specifically on **recorded title additions**.

---

### 2021 Is Incomplete

The final date represented in the dataset is:
```text
September 25, 2021
```
Therefore, 2021 represents **year-to-date data**, not a complete calendar year.

We do not treat 2021’s total title count as directly comparable to a complete full-year YoY total.

---

### Early-Year Records Are Sparse

The years before 2015 contain relatively few recorded additions.

Because percentage-based comparisons can be misleading when yearly totals are very small, rating, genre, country, and content-composition views focus primarily on **2015–2021**.

The earlier years remain visible in the overall additions analysis.

---

### Genres and Countries Are Multi-Label Categories

One Netflix title can be associated with multiple genres and multiple countries.

Therefore, genre and country percentages are not mutually exclusive.

For example, one title associated with both the United States and the United Kingdom contributes to both countries’ counts.

As a result, genre or country percentages should not be expected to sum to 100%.

---

### No Causal Data

The dataset does not include information such as:

- subscriber demand
- viewership
- content performance
- acquisition strategy
- licensing decisions
- removal reasons

As a result, the project can identify **what changed**, but it cannot reliably determine **why Netflix made those changes**.

Explaining Netflix’s business strategy would require additional information and data.

---

## 12. Repository Structure
```text
netflix-content-analysis/
│
├── README.md
│
├── data/
│   └── netflix_titles.csv
│
├── python/
│   └── netflix_cleaning.ipynb
│
├── sql/
│   ├── database_setup.sql
│   ├── validation.sql
│   └── analysis.sql
│
├── tableau_data/
│   ├── netflix_1a_yearly_growth.csv
│   ├── netflix_2b_movie_tv_pct.csv
│   ├── netflix_3b_rating_growth.csv
│   ├── netflix_4c_top5_genre.csv
│   └── netflix_5c_top5_country.csv
│
└── images/
    └── netflix_dashboard.png
```
---

## 13. How to Reproduce the Analysis

1. Clone this repository.
2. Download or place the original Netflix dataset in the data/ folder.
3. Open and run the Python cleaning notebook/script.
4. Load the cleaned datasets into MySQL.
5. Run the database setup and validation SQL.
6. Run the analytical SQL queries.
7. Export the Tableau-ready query results.
8. Open the Tableau Public workbook or view the published interactive dashboard.

---

## 14. Project Takeaways

One of the most important lessons from this project was understanding the unit of analysis before aggregation.

During the project, splitting country and genre values into the same exploded dataset initially multiplied rows. A title associated with multiple countries and genres could appear multiple times, inflating counts if we aggregated the data directly.

This led us to restructure the data using separate relational bridge tables for genre and country while keeping one record per title in the main table.

The project also reinforced the importance of:

- validating data before analysis
- choosing the correct denominator when calculating percentages
- distinguishing mutually exclusive categories from multi-label categories
- handling missing values explicitly
- protecting against division-by-zero in growth calculations
- treating partial-year data carefully
- separating data availability from the conclusions that can reasonably be made from the data

Overall, this project demonstrated how decisions made during data cleaning and modeling directly affect the accuracy of the final analysis and visualization.

---

## 15. Links

Tableau Dashboard: [View Dashboard](https://public.tableau.com/app/profile/brandon.marron8358/viz/NetflixProject_17919232967500/Dashboard1)

Dataset Source: [View Dataset](https://www.kaggle.com/datasets/debayank2024/netflix-movies-and-series)

GitHub Repository: [View Repository]()

LinkedIn: [LinkedIn Profile](linkedin.com/in/brandonmarron)

