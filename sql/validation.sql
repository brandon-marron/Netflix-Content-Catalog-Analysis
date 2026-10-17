USE netflix_analysis;

-- Genre bridge table uniqueness check
SELECT show_id, genre, COUNT(*) AS n
FROM netflix_title_genre
GROUP BY show_id, genre
HAVING COUNT(*) > 1;

-- Country bridge table uniqueness check
SELECT show_id, country, COUNT(*) AS n
FROM netflix_title_country
GROUP BY show_id, country
HAVING COUNT(*) > 1;

-- Dataset endpoint check
SELECT MAX(date_added) AS max_date, YEAR(MAX(date_added)) AS latest_year, MAX(date_added) < STR_TO_DATE(CONCAT(YEAR(MAX(date_added)), '-12-31'), '%Y-%m-%d') AS latest_year_is_partial
FROM netflix_titles_base;