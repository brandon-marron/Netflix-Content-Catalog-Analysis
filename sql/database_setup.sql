CREATE DATABASE IF NOT EXISTS netflix_analysis
    CHARACTER SET utf8mb4
    COLLATE utf8mb4_unicode_ci;
 
USE netflix_analysis;
 
-- Drop child tables first so foreign keys don't block the drops
DROP TABLE IF EXISTS netflix_title_genre;
DROP TABLE IF EXISTS netflix_title_country;
DROP TABLE IF EXISTS netflix_titles_base;
 
-- -----------------------------------------------------------------------------
-- Base table: one row per title
-- -----------------------------------------------------------------------------
CREATE TABLE netflix_titles_base (
    show_id         VARCHAR(10)  NOT NULL,
    type            VARCHAR(20)  NOT NULL,
    title           VARCHAR(255) NOT NULL,
    director        VARCHAR(255) NULL,
    `cast`          TEXT         NULL,
    country         VARCHAR(255) NULL,
    date_added      DATE         NULL,
    day_added       INT          NULL,
    month_added     INT          NULL,
    year_added      INT          NULL,
    release_year    INT          NOT NULL,
    rating          VARCHAR(10)  NULL,
    duration        VARCHAR(20)  NULL,
    listed_in       VARCHAR(255) NOT NULL,
    description     TEXT         NULL,
    primary_country VARCHAR(100) NULL,
    PRIMARY KEY (show_id)
);
 
-- -----------------------------------------------------------------------------
-- Bridge tables: the composite primary key enforces that each
-- (show_id, genre) and (show_id, country) pair can only appear once, so
-- COUNT(*) on these tables can't be inflated by duplicate rows.
-- -----------------------------------------------------------------------------
CREATE TABLE netflix_title_genre (
    show_id VARCHAR(10)  NOT NULL,
    genre   VARCHAR(100) NOT NULL,
    PRIMARY KEY (show_id, genre),
    CONSTRAINT fk_title_genre_title
        FOREIGN KEY (show_id) REFERENCES netflix_titles_base (show_id)
);
 
CREATE TABLE netflix_title_country (
    show_id VARCHAR(10)  NOT NULL,
    country VARCHAR(100) NOT NULL,
    PRIMARY KEY (show_id, country),
    CONSTRAINT fk_title_country_title
        FOREIGN KEY (show_id) REFERENCES netflix_titles_base (show_id)
);
 
-- -----------------------------------------------------------------------------
-- Before running: set the three file paths below.
--   * Use forward slashes (C:/Users/...) or doubled backslashes (C:\\Users\\...)
--   * LOAD DATA LOCAL needs local_infile enabled on both server and client:
--       SET GLOBAL local_infile = 1;          (requires admin rights)
--       MySQL Workbench: connection > Advanced > Others: OPT_LOCAL_INFILE=1
--   * If the CSVs have Windows (CRLF) line endings, change '\n' to '\r\n'
--
-- Blank CSV fields are converted to NULL with NULLIF so missing values are
-- real NULLs, not empty strings. Without this, IS NULL / COALESCE checks
-- (e.g. the 'Unknown' rating bucket) silently miss them.
-- -----------------------------------------------------------------------------
LOAD DATA LOCAL INFILE 'C:/path/to/netflix_titles_base.csv'
INTO TABLE netflix_titles_base
CHARACTER SET utf8mb4
FIELDS TERMINATED BY ','
ENCLOSED BY '"'
LINES TERMINATED BY '\n'
IGNORE 1 ROWS
(show_id, type, title, @director, @cast, @country, @date_added,
 @day_added, @month_added, @year_added, release_year, @rating,
 @duration, listed_in, @description, @primary_country)
SET director        = NULLIF(@director, ''),
    `cast`          = NULLIF(@cast, ''),
    country         = NULLIF(@country, ''),
    date_added      = NULLIF(@date_added, ''),
    day_added       = NULLIF(@day_added, ''),
    month_added     = NULLIF(@month_added, ''),
    year_added      = NULLIF(@year_added, ''),
    rating          = NULLIF(@rating, ''),
    duration        = NULLIF(@duration, ''),
    description     = NULLIF(@description, ''),
    primary_country = NULLIF(@primary_country, '');
 
LOAD DATA LOCAL INFILE 'C:/path/to/netflix_title_genre.csv'
INTO TABLE netflix_title_genre
CHARACTER SET utf8mb4
FIELDS TERMINATED BY ','
ENCLOSED BY '"'
LINES TERMINATED BY '\n'
IGNORE 1 ROWS
(show_id, genre);
 
LOAD DATA LOCAL INFILE 'C:/path/to/netflix_title_country.csv'
INTO TABLE netflix_title_country
CHARACTER SET utf8mb4
FIELDS TERMINATED BY ','
ENCLOSED BY '"'
LINES TERMINATED BY '\n'
IGNORE 1 ROWS
(show_id, country);