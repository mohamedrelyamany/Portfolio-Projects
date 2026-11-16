-- Baby Name Trend Analysis Guided Project --
USE baby_names_db;

-- Objective 1: Track Changes in Populartity
SELECT * FROM names;

-- 1. Find the overall most populart girl name and most popular boy name. Show how they have changed in populartity rankings over the years.
-- Overall most popular girl name
SELECT	 Name, SUM(Births) AS babies
FROM	 names
WHERE	 Gender = 'F'
GROUP BY Name
ORDER BY babies DESC
LIMIT	 1;  -- Jessica --> 863121

-- Overall most popular boy name
SELECT	 Name, SUM(Births) AS babies
FROM	 names
WHERE	 Gender = 'M'
GROUP BY Name
ORDER BY babies DESC
LIMIT	 1;  -- Michael --> 1376418

-- Jessica Name popularity change over years
WITH girl_pop AS   (SELECT	 Year, Name, SUM(Births) AS babies,
							 ROW_NUMBER() OVER(PARTITION BY Year ORDER BY SUM(Births) DESC) AS popularity
					FROM	 names
					WHERE	 Gender = 'F'
					GROUP BY Year, Name
					ORDER BY Year, popularity)
SELECT	*
FROM	girl_pop
WHERE	Name = 'Jessica';  -- Jessical 

-- Michael Name popularity change over years
WITH girl_pop AS   (SELECT	 Year, Name, SUM(Births) AS babies,
							 ROW_NUMBER() OVER(PARTITION BY Year ORDER BY SUM(Births) DESC) AS popularity
					FROM	 names
					WHERE	 Gender = 'M'
					GROUP BY Year, Name
					ORDER BY Year, popularity)
SELECT	*
FROM	girl_pop
WHERE	Name = 'Michael'; -- Michael Name is pretty consistent in popularity over years

-- 2. Find the names with the biggest jumps in populartity from the first year of the dataset to the last year of the dataset.
WITH names_1980 AS (
	WITH all_names AS  (SELECT	 Year, Name, SUM(Births) AS babies
						FROM	 names
						GROUP BY Year, Name)
                    
	SELECT	Year, Name,
			ROW_NUMBER() OVER(PARTITION BY Year ORDER BY babies DESC) AS popularity
	FROM	all_names
	WHERE	Year = 1980),
    
	 names_2009 AS (
	WITH all_names AS  (SELECT	 Year, Name, SUM(Births) AS babies
						FROM	 names
						GROUP BY Year, Name)
                    
	SELECT	Year, Name,
			ROW_NUMBER() OVER(PARTITION BY Year ORDER BY babies DESC) AS popularity
	FROM	all_names
	WHERE	Year = 2009)
    
SELECT	t1.Year, t1.name, t1.popularity AS pop_1980,
		t2.popularity AS pop_2009,
        CAST(t2.popularity AS SIGNED) - CAST(t1.popularity AS SIGNED) AS diff
FROM	names_1980 t1 INNER JOIN names_2009 t2
		ON t1.Name = t2.Name
ORDER BY diff;

-- Objective 2: Compare Popularity across decades

-- 1. For each year, return the 3 most popular girl names and 3 most popular boy names.
WITH name_rank AS  (SELECT	 Year, Gender, Name, SUM(Births) AS babies,
							 ROW_NUMBER() OVER(PARTITION BY Year, Gender ORDER BY SUM(Births) DESC) AS popularity
					FROM	 names
					GROUP BY Year,Gender, Name)
SELECT	*
FROM	name_rank
WHERE	popularity <=3;

-- 2. For each decade, return the 3 most popular girl names and 3 most popular boy names
WITH babies_by_decade AS (SELECT FLOOR(Year / 10) * 10 AS decade, Gender, Name, SUM(Births) AS babies
						  FROM	 names
                          GROUP BY decade, Gender, Name),
	 name_rank AS  (SELECT	 decade, Gender, Name, babies,
							 ROW_NUMBER() OVER(PARTITION BY decade, Gender ORDER BY babies DESC) AS popularity
					FROM	 babies_by_decade)
SELECT	*
FROM	name_rank
WHERE	popularity <=3;


-- Objective 3: Compare Popularity Across Regions
SELECT * FROM regions;

-- 1. Return the number of babies born in each of the six regions. (Hint: The state of MI should be in the Midwest region, but it is not represented that way in data)
WITH clean_regions AS (SELECT State,
							  CASE WHEN Region = "New England" THEN "New_England" ELSE Region END AS clean_region
					   FROM	  regions
                       UNION
                       SELECT "MI" AS State, "Midwest" AS Region)
                       
SELECT	 clean_region, SUM(Births) AS num_babies
FROM	 names n LEFT JOIN clean_regions cr
			ON n.State = cr.State
GROUP BY clean_region
ORDER BY num_babies DESC;

-- 2. Return the 3 most popular girl names and 3 most popular boy names within each region.
SELECT * FROM

(WITH babies_by_region AS (
WITH clean_regions AS (SELECT State,
							  CASE WHEN Region = "New England" THEN "New_England" ELSE Region END AS clean_region
					   FROM	  regions
                       UNION
                       SELECT "MI" AS State, "Midwest" AS Region)
                       
SELECT	 clean_region, Gender, Name, SUM(Births) AS num_babies
FROM	 names n LEFT JOIN clean_regions cr
			ON n.State = cr.State
GROUP BY clean_region, Gender, Name)

SELECT	clean_region, Gender, Name,
		ROW_NUMBER() OVER(PARTITION BY clean_region, Gender ORDER BY num_babies DESC) AS popularity
FROM	babies_by_region) AS region_popularity

WHERE popularity <= 3;


-- Objective 4: Dig into Some unique names

-- 1. Find the 10 most popular androgynous names (names given to both females and males)
SELECT	 Name, COUNT(DISTINCT Gender) AS num_genders, SUM(Births) AS num_babies
FROM	 names
GROUP BY Name
HAVING	 num_genders = 2
ORDER BY num_babies DESC
LIMIT	 10;

-- 2. Find the length of the shortest and longest names. Identify the most popular short names (those with the fewest characters) and long names (those with most chars)
SELECT	 DISTINCT Name, LENGTH(Name) AS name_length
FROM	 names
ORDER BY name_length; -- Shortest are 2 characters

SELECT	 DISTINCT Name, LENGTH(Name) AS name_length
FROM	 names
ORDER BY name_length DESC; -- longest names are 15 characters

WITH short_long_names AS (SELECT *
						  FROM	 names
						  WHERE	 LENGTH(Name) IN (2, 15))
                          
SELECT	Name, SUM(Births) AS num_babies
FROM	short_long_names
GROUP BY Name
ORDER BY num_babies DESC; -- most popular short Name: Ty, Most popular long Name is Francisco

-- 3. The founder of our website's name is Chris. Find the state with the highest percent of Chris's
WITH count_chris AS (SELECT	  State, SUM(Births) AS num_chris
					 FROM	  names
					 WHERE	  Name = "Chris"
					 GROUP BY State),
	 count_all AS  (SELECT	 State, SUM(Births) AS num_babies
					FROM	 names
					GROUP BY State)
                    
SELECT	cc.State, num_chris, num_babies,
		num_chris / num_babies * 100 AS chris_pct
FROM	count_chris cc INNER JOIN count_all ca
			ON cc.State = ca.State
ORDER BY chris_pct DESC; -- LA state has the highest percentage of chris names