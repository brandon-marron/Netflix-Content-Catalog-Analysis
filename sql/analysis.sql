USE netflix_analysis;

-- Number of titles added in each year
SELECT year_added, COUNT(*) AS num_titles
FROM netflix_titles_base
WHERE year_added IS NOT NULL
GROUP BY year_added
ORDER BY year_added ASC;

-- Including Month
SELECT year_added, month_added, COUNT(*) AS num_titles
FROM netflix_titles_base
WHERE year_added IS NOT NULL AND month_added IS NOT NULL
GROUP BY year_added, month_added
ORDER BY year_added ASC, month_added ASC;

-- Movie vs TV Show per year
SELECT type, year_added, COUNT(*) AS num_titles
FROM netflix_titles_base
WHERE year_added IS NOT NULL
GROUP BY year_added, type
ORDER BY year_added, type;

-- Movie vs TV Show per Year Percentage
SELECT type, year_added, COUNT(*) AS num_titles, ROUND(COUNT(*) * 100.0 / SUM(COUNT(*)) OVER(PARTITION BY year_added), 1) AS pct_of_year
FROM netflix_titles_base
WHERE year_added IS NOT NULL
GROUP BY type, year_added
ORDER BY year_added, type;

-- Year-Over-Year Titles
WITH yearly_count AS (
SELECT year_added, COUNT(*) AS num_titles
FROM netflix_titles_base
WHERE year_added IS NOT NULL
GROUP BY year_added
),
dataset_meta AS (
SELECT YEAR(MAX(date_added)) AS latest_year, MAX(date_added) < STR_TO_DATE(CONCAT(YEAR(MAX(date_added)), '-12-31'), '%Y-%m-%d') AS latest_year_is_partial
FROM netflix_titles_base
)
SELECT yc.year_added, yc.num_titles, (yc.year_added = dm.latest_year AND dm.latest_year_is_partial) AS is_partial_year, LAG(yc.num_titles) OVER (ORDER BY yc.year_added) AS previous_year_title,
CASE WHEN yc.year_added = dm.latest_year AND dm.latest_year_is_partial THEN NULL
ELSE yc.num_titles - LAG(yc.num_titles) OVER (ORDER BY yc.year_added)
END AS yoy_change,
CASE
WHEN yc.year_added = dm.latest_year AND dm.latest_year_is_partial THEN NULL
WHEN LAG(yc.num_titles) OVER (ORDER BY yc.year_added) IS NULL THEN NULL
WHEN LAG(yc.num_titles) OVER (ORDER BY yc.year_added) = 0 THEN NULL
ELSE ROUND((yc.num_titles - LAG(yc.num_titles) OVER (ORDER BY yc.year_added)) * 100.0 / LAG(yc.num_titles) OVER (ORDER BY yc.year_added), 1)
END AS yoy_pct_change
FROM yearly_count AS yc
CROSS JOIN dataset_meta AS dm
ORDER BY yc.year_added;

-- Rating Trends Over Time 3a
SELECT rating, year_added, COUNT(*) AS num_titles
FROM netflix_titles_base
WHERE year_added IS NOT NULL AND rating IS NOT NULL
GROUP BY rating, year_added
ORDER BY year_added, rating;

-- Rating Percentage per Year 3b
SELECT COALESCE(rating, 'Unknown') AS rating, year_added, COUNT(*) AS num_titles, ROUND(COUNT(*) * 100.0 / SUM(COUNT(*)) OVER (PARTITION BY year_added), 1) AS pct_of_year
FROM netflix_titles_base
WHERE year_added IS NOT NULL
GROUP BY COALESCE(rating,'Unknown'), year_added
ORDER BY year_added, pct_of_year DESC;

-- Year-Over-Year on Rating
WITH RECURSIVE all_years AS (
    SELECT MIN(year_added) AS yr 
    FROM netflix_titles_base 
    WHERE year_added IS NOT NULL
    UNION ALL
    SELECT yr + 1 
    FROM all_years 
    WHERE yr < (SELECT MAX(year_added) 
    FROM netflix_titles_base 
    WHERE year_added IS NOT NULL)
),
all_ratings AS (
SELECT DISTINCT rating 
FROM netflix_titles_base 
WHERE rating IS NOT NULL
),
rating_year_grid AS (
SELECT r.rating, y.yr AS year_added
FROM all_ratings AS r
CROSS JOIN all_years AS y
),
actual_counts AS (
SELECT rating, year_added, COUNT(*) AS num_titles
FROM netflix_titles_base
WHERE year_added IS NOT NULL AND rating IS NOT NULL
GROUP BY rating, year_added
),
filled AS (
SELECT grid.rating, grid.year_added, COALESCE(ac.num_titles, 0) AS num_titles
FROM rating_year_grid AS grid
LEFT JOIN actual_counts AS ac
ON grid.rating = ac.rating AND grid.year_added = ac.year_added
),
dataset_meta AS (
SELECT YEAR(MAX(date_added)) AS latest_year, MAX(date_added) < STR_TO_DATE(CONCAT(YEAR(MAX(date_added)), '-12-31'), '%Y-%m-%d') AS latest_year_is_partial
FROM netflix_titles_base
)
SELECT f.rating, f.year_added, f.num_titles, LAG(f.num_titles) OVER (PARTITION BY f.rating ORDER BY f.year_added) AS previous_year_title,
CASE WHEN f.year_added = dm.latest_year AND dm.latest_year_is_partial THEN NULL
ELSE f.num_titles - LAG(f.num_titles) OVER (PARTITION BY f.rating ORDER BY f.year_added)
END AS yoy_change,
CASE
WHEN f.year_added = dm.latest_year AND dm.latest_year_is_partial THEN NULL
WHEN LAG(f.num_titles) OVER (PARTITION BY f.rating ORDER BY f.year_added) IS NULL THEN NULL
WHEN LAG(f.num_titles) OVER (PARTITION BY f.rating ORDER BY f.year_added) = 0 THEN NULL
ELSE ROUND((f.num_titles - LAG(f.num_titles) OVER (PARTITION BY f.rating ORDER BY f.year_added)) * 100.0 / LAG(f.num_titles) OVER (PARTITION BY f.rating ORDER BY f.year_added), 1)
END AS yoy_pct_change
FROM filled AS f
CROSS JOIN dataset_meta AS dm
ORDER BY f.rating, f.year_added;

-- Genre Analysis
-- Number of Titles per Genre per Year
SELECT b.year_added, g.genre, COUNT(*) AS num_titles
FROM netflix_titles_base AS b
INNER JOIN netflix_title_genre AS g
ON b.show_id = g.show_id
WHERE b.year_added IS NOT NULL
GROUP BY g.genre, b.year_added
ORDER BY b.year_added, num_titles DESC;

-- Number of Titles per Genre per Year Percentage (percentage of total titles added that year, not total genre tags)
SELECT b.year_added, g.genre, COUNT(DISTINCT b.show_id) AS num_titles, ROUND(COUNT(DISTINCT b.show_id) * 100.0 / (SELECT COUNT(*) FROM netflix_titles_base AS yr WHERE yr.year_added = b.year_added), 1) AS pct_of_year_titles
FROM netflix_titles_base AS b
INNER JOIN netflix_title_genre AS g 
ON b.show_id = g.show_id
WHERE b.year_added IS NOT NULL
GROUP BY g.genre, b.year_added
ORDER BY b.year_added, pct_of_year_titles DESC;

-- Top 5 Genres per Year
WITH genre_year_counts AS (
SELECT b.year_added, g.genre, COUNT(*) AS num_titles,
DENSE_RANK() OVER (PARTITION BY b.year_added ORDER BY COUNT(*) DESC) AS rn
FROM netflix_titles_base AS b
INNER JOIN netflix_title_genre AS g
ON b.show_id = g.show_id
WHERE b.year_added IS NOT NULL
GROUP BY g.genre, b.year_added
)
SELECT year_added, genre, num_titles, rn
FROM genre_year_counts
WHERE rn <= 5
ORDER BY year_added, rn;

-- Year-Over-Year Genre
WITH RECURSIVE all_years AS (
SELECT MIN(year_added) AS yr 
FROM netflix_titles_base 
WHERE year_added IS NOT NULL
UNION ALL
SELECT yr + 1 
FROM all_years 
WHERE yr < (SELECT MAX(year_added) 
FROM netflix_titles_base 
WHERE year_added IS NOT NULL)
),
all_genres AS (
SELECT DISTINCT genre 
FROM netflix_title_genre
),
genre_year_grid AS (
SELECT g.genre, y.yr AS year_added
FROM all_genres AS g
CROSS JOIN all_years AS y
),
actual_counts AS (
SELECT g.genre, b.year_added, COUNT(*) AS num_titles
FROM netflix_titles_base AS b
INNER JOIN netflix_title_genre AS g ON b.show_id = g.show_id
WHERE b.year_added IS NOT NULL
GROUP BY g.genre, b.year_added
),
filled AS (
SELECT grid.genre, grid.year_added, COALESCE(ac.num_titles, 0) AS num_titles
FROM genre_year_grid AS grid
LEFT JOIN actual_counts AS ac
ON grid.genre = ac.genre AND grid.year_added = ac.year_added
),
dataset_meta AS (
SELECT YEAR(MAX(date_added)) AS latest_year, MAX(date_added) < STR_TO_DATE(CONCAT(YEAR(MAX(date_added)), '-12-31'), '%Y-%m-%d') AS latest_year_is_partial
FROM netflix_titles_base
)
SELECT f.genre, f.year_added, f.num_titles, LAG(f.num_titles) OVER (PARTITION BY f.genre ORDER BY f.year_added) AS previous_year_title,
CASE WHEN f.year_added = dm.latest_year AND dm.latest_year_is_partial THEN NULL
ELSE f.num_titles - LAG(f.num_titles) OVER (PARTITION BY f.genre ORDER BY f.year_added)
END AS yoy_change,
CASE
WHEN f.year_added = dm.latest_year AND dm.latest_year_is_partial THEN NULL
WHEN LAG(f.num_titles) OVER (PARTITION BY f.genre ORDER BY f.year_added) IS NULL THEN NULL
WHEN LAG(f.num_titles) OVER (PARTITION BY f.genre ORDER BY f.year_added) = 0 THEN NULL
ELSE ROUND((f.num_titles - LAG(f.num_titles) OVER (PARTITION BY f.genre ORDER BY f.year_added)) * 100.0 / LAG(f.num_titles) OVER (PARTITION BY f.genre ORDER BY f.year_added),1)
END AS yoy_pct_change
FROM filled AS f
CROSS JOIN dataset_meta AS dm
ORDER BY f.genre, f.year_added;

-- Genre coverage per year
SELECT b.year_added, COUNT(DISTINCT b.show_id) AS total_titles, COUNT(DISTINCT g.show_id) AS titles_with_genre, ROUND(COUNT(DISTINCT g.show_id) * 100.0 / COUNT(DISTINCT b.show_id), 1) AS pct_with_usable_genre
FROM netflix_titles_base AS b
LEFT JOIN netflix_title_genre AS g 
ON b.show_id = g.show_id
WHERE b.year_added IS NOT NULL
GROUP BY b.year_added
ORDER BY b.year_added;

-- Country Analysis
-- Number of Titles per Country per Year
SELECT b.year_added, c.country, COUNT(*) AS num_titles
FROM netflix_titles_base AS b
INNER JOIN netflix_title_country AS c
ON b.show_id = c.show_id
WHERE b.year_added IS NOT NULL
GROUP BY b.year_added, c.country
ORDER BY b.year_added, c.country;

-- Number of Titles per Country per Year Percentage (percentage of total titles added that year, not total country tags)
SELECT b.year_added, c.country, COUNT(DISTINCT b.show_id) AS num_titles, ROUND(COUNT(DISTINCT b.show_id) * 100.0 / (SELECT COUNT(*) FROM netflix_titles_base AS yr WHERE yr.year_added = b.year_added) , 1) AS pct_of_year_titles
FROM netflix_titles_base AS b
INNER JOIN netflix_title_country AS c 
ON b.show_id = c.show_id
WHERE b.year_added IS NOT NULL
GROUP BY c.country, b.year_added
ORDER BY b.year_added, pct_of_year_titles DESC;

-- Top 5 Countries per Year
WITH country_year_counts AS (
SELECT b.year_added, c.country, COUNT(*) AS num_titles,
DENSE_RANK() OVER (PARTITION BY b.year_added ORDER BY COUNT(*) DESC) AS rn
FROM netflix_titles_base AS b
INNER JOIN netflix_title_country AS c
ON b.show_id = c.show_id
WHERE b.year_added IS NOT NULL
GROUP BY c.country, b.year_added
)
SELECT year_added, country, num_titles, rn
FROM country_year_counts
WHERE rn <= 5
ORDER BY year_added, rn;

-- Year-Over-Year Countries
WITH RECURSIVE all_years AS (
SELECT MIN(year_added) AS yr 
FROM netflix_titles_base 
WHERE year_added IS NOT NULL
UNION ALL
SELECT yr + 1 
FROM all_years 
WHERE yr < (SELECT MAX(year_added) 
FROM netflix_titles_base 
WHERE year_added IS NOT NULL)
),
all_country AS (
SELECT DISTINCT country 
FROM netflix_title_country
),
country_year_grid AS (
SELECT c.country, y.yr AS year_added
FROM all_country AS c
CROSS JOIN all_years AS y
),
actual_counts AS (
SELECT c.country, b.year_added, COUNT(*) AS num_titles
FROM netflix_titles_base AS b
INNER JOIN netflix_title_country AS c 
ON b.show_id = c.show_id
WHERE b.year_added IS NOT NULL
GROUP BY c.country, b.year_added
),
filled AS (
SELECT grid.country, grid.year_added, COALESCE(ac.num_titles, 0) AS num_titles
FROM country_year_grid AS grid
LEFT JOIN actual_counts AS ac
ON grid.country = ac.country AND grid.year_added = ac.year_added
),
dataset_meta AS (
SELECT YEAR(MAX(date_added)) AS latest_year, MAX(date_added) < STR_TO_DATE(CONCAT(YEAR(MAX(date_added)), '-12-31'), '%Y-%m-%d') AS latest_year_is_partial
FROM netflix_titles_base
)
SELECT f.country, f.year_added, f.num_titles, LAG(f.num_titles) OVER (PARTITION BY f.country ORDER BY f.year_added) AS previous_year_title,
CASE WHEN f.year_added = dm.latest_year AND dm.latest_year_is_partial THEN NULL
ELSE f.num_titles - LAG(f.num_titles) OVER (PARTITION BY f.country ORDER BY f.year_added)
END AS yoy_change,
CASE
WHEN f.year_added = dm.latest_year AND dm.latest_year_is_partial THEN NULL
WHEN LAG(f.num_titles) OVER (PARTITION BY f.country ORDER BY f.year_added) IS NULL THEN NULL
WHEN LAG(f.num_titles) OVER (PARTITION BY f.country ORDER BY f.year_added) = 0 THEN NULL
ELSE ROUND((f.num_titles - LAG(f.num_titles) OVER (PARTITION BY f.country ORDER BY f.year_added)) * 100.0 / LAG(f.num_titles) OVER (PARTITION BY f.country ORDER BY f.year_added),1)
END AS yoy_pct_change
FROM filled AS f
CROSS JOIN dataset_meta AS dm
ORDER BY f.country, f.year_added;

-- Country coverage per year
SELECT b.year_added, COUNT(DISTINCT b.show_id) AS total_titles, COUNT(DISTINCT c.show_id) AS titles_with_country, ROUND(COUNT(DISTINCT c.show_id) * 100.0 / COUNT(DISTINCT b.show_id), 1) AS pct_with_known_country
FROM netflix_titles_base AS b
LEFT JOIN netflix_title_country c ON b.show_id = c.show_id
WHERE b.year_added IS NOT NULL
GROUP BY b.year_added
ORDER BY b.year_added;