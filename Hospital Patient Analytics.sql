-- Hospital Analytics project --
USE hospital_db;

-- Objective 1: Encounters Overview
SELECT * FROM encounters;

-- 1. How many total encounters occured each year?
SELECT	 YEAR(START) AS yr, COUNT(ID) AS total_encounters
FROM	 encounters
GROUP BY yr
ORDER BY yr;

-- 2. For each year, what percentage of all encounters belonged to each encounter class (ambulatory, outpatient, wellness, urgentcare, emergency, and inpatient)?
SELECT	YEAR(START) AS yr, 
		ROUND(SUM(CASE WHEN ENCOUNTERCLASS = 'ambulatory' THEN 1 ELSE 0 END) / COUNT(*) * 100, 1) AS ambulatory,
        ROUND(SUM(CASE WHEN ENCOUNTERCLASS = 'outpatient' THEN 1 ELSE 0 END) / COUNT(*) * 100, 1) AS outpatient,
        ROUND(SUM(CASE WHEN ENCOUNTERCLASS = 'wellness' THEN 1 ELSE 0 END) / COUNT(*) * 100, 1) AS wellness,
        ROUND(SUM(CASE WHEN ENCOUNTERCLASS = 'urgentcare' THEN 1 ELSE 0 END) / COUNT(*) * 100, 1) AS urgentcare,
        ROUND(SUM(CASE WHEN ENCOUNTERCLASS = 'emergency' THEN 1 ELSE 0 END) / COUNT(*) * 100, 1) AS emergency,
        ROUND(SUM(CASE WHEN ENCOUNTERCLASS = 'inpatient' THEN 1 ELSE 0 END) / COUNT(*) * 100, 1) AS inpatient
FROM	encounters
GROUP BY yr;

-- 3. What percentage of encounters were over 24 hours vs. under 24 hours?
SELECT	ROUND(SUM(CASE WHEN TIMESTAMPDIFF(HOUR, START, STOP) >= 24 THEN 1 ELSE 0 END) / COUNT(*) * 100, 1) AS over_24_hours,
        ROUND(SUM(CASE WHEN TIMESTAMPDIFF(HOUR, START, STOP) < 24 THEN 1 ELSE 0 END) / COUNT(*) * 100, 1) AS under_24_hours,
        COUNT(*) AS total_encounters
FROM	encounters;


-- Objective 2: Cost & Coverage Insights

-- 1. How many encounters had zero payer coverage, and what percentage of total encounters does this represent?
SELECT	ROUND(COUNT(ID) / (SELECT COUNT(*) FROM encounters) * 100, 1) AS num_encounters
FROM	encounters
WHERE	PAYER_COVERAGE = 0;

-- 2. What are the top 10 most frequent procedures performed and the average base cost for each?
SELECT	 description, 
		 COUNT(ENCOUNTER) AS num_encounters, 
		 ROUND(AVG(base_cost), 1) AS avg_base_cost
FROM	 procedures
GROUP BY description
ORDER BY num_encounters DESC
LIMIT	 10;

-- 3. What are the top 10 procedures with the highest average base cost and the number of times they were performed?
SELECT	 description,
		 ROUND(AVG(base_cost), 1) AS avg_base_cost,
		 COUNT(ENCOUNTER) AS num_encounters
FROM	 procedures
GROUP BY description
ORDER BY avg_base_cost DESC
LIMIT	 10;

-- 4. What is the average total claim cost for encounters, broken down by payer?
SELECT	 p.NAME, AVG(e.TOTAL_CLAIM_COST) AS avg_total_claim_cost
FROM	 payers p LEFT JOIN encounters e
		 ON p.ID = e.PAYER
GROUP BY p.NAME
ORDER BY avg_total_claim_cost DESC;


-- Objective 3: Patient Behaviour Analysis

-- 1. How many uniqure patients are addmitted each quarter over time?
SELECT	YEAR(START) AS yr, quarter(START) AS qrt,
		COUNT(DISTINCT PATIENT) AS num_unique_patients
FROM	encounters
GROUP BY yr, qrt
ORDER BY yr, qrt;

-- 2. How many patients were readmitted within 30 days of a previous encounter?
SELECT	PATIENT, START, STOP,
		LEAD(START) OVER(PARTITION BY PATIENT ORDER BY PATIENT) AS next_start_date
FROM	encounters;

WITH cte AS (SELECT	PATIENT, START, STOP,
					LEAD(START) OVER(PARTITION BY PATIENT ORDER BY START) AS next_start_date
			 FROM	encounters)
SELECT	COUNT(DISTINCT PATIENT) AS num_patients
FROM	cte
WHERE	DATEDIFF(next_start_date, STOP) < 30; -- 771

-- 3. Which patients had the most readmissions?
WITH cte AS (SELECT	PATIENT, START, STOP,
					LEAD(START) OVER(PARTITION BY PATIENT ORDER BY START) AS next_start_date
			 FROM	encounters)
SELECT	 PATIENT, COUNT(*) AS num_readmissions
FROM	 cte
WHERE	 DATEDIFF(next_start_date, STOP) < 30
GROUP BY PATIENT
ORDER BY num_readmissions DESC; -- 771