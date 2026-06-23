-- CREATING TABLE

CREATE TABLE enrollment_data (
    enroll_date DATE,
    states VARCHAR(100),
    districts VARCHAR(100),
    pincode INT,
    age_0_5 INT,
    age_5_17 INT,
    age_18_greater INT
);

-- LOADING FIRST CSV

LOAD DATA LOCAL INFILE 'D:/data hackathon/api_data_aadhar_enrolment/api_data_aadhar_enrolment_0_500000.csv'
INTO TABLE enrollment_data
FIELDS TERMINATED BY ','
OPTIONALLY ENCLOSED BY '"'
LINES TERMINATED BY '\n'
IGNORE 1 ROWS;

-- LOADING SECOND CSV

LOAD DATA LOCAL INFILE 'D:/data hackathon/api_data_aadhar_enrolment/api_data_aadhar_enrolment_500000_1000000.csv'
INTO TABLE enrollment_data
FIELDS TERMINATED BY ','
OPTIONALLY ENCLOSED BY '"'
LINES TERMINATED BY '\n'
IGNORE 1 ROWS;

-- LOADING THIRD CSV

LOAD DATA LOCAL INFILE 'D:/data hackathon/api_data_aadhar_enrolment/api_data_aadhar_enrolment_1000000_1006029.csv'
INTO TABLE enrollment_data
FIELDS TERMINATED BY ','
OPTIONALLY ENCLOSED BY '"'
LINES TERMINATED BY '\n'
IGNORE 1 ROWS;

-- RENAMING THE TABLE

RENAME TABLE api_data_aadhar_enrolment_0_500000 TO enrollment_data;

-- VIEWING DATA

SELECT * FROM enrollment_data;

-- STANDARDIZING STATE NAMES

UPDATE enrollment_data
SET states = CONCAT(
    UPPER(LEFT(states,1)),
    LOWER(SUBSTRING(states,2))
);

-- CORRECTING MISSPELLED STATE NAMES

UPDATE enrollment_data
SET states = 'West Bengal'
WHERE LOWER(states) IN ('west bangal', 'westbengal');

-- FIXING INCONSISTENT STATE NAMES

UPDATE enrollment_data
SET states = CASE
    WHEN states = 'Jammu And Kashmir' THEN 'Jammu & Kashmir'
    WHEN states = 'West  Bengal' THEN 'West Bengal'
    WHEN states = 'Dadra And Nagar Haveli' THEN 'Dadra & Nagar Haveli'
    WHEN states = 'Puducherry' THEN 'Pondicherry'
    WHEN states = 'Daman And Diu' THEN 'Daman & Diu'
    WHEN states = 'The Dadra And Nagar Haveli And Daman And Diu'
         THEN 'Dadra And Nagar Haveli And Daman And Diu'
    WHEN states = 'Andaman And Nicobar Islands'
         THEN 'Andaman & Nicobar Islands'
    ELSE states
END;

-- REMOVING INVALID RECORDS

DELETE FROM enrollment_data
WHERE states = '100000'
   OR districts = '100000'
   OR pincode = 100000;

-- TOTAL ROW COUNT

SELECT COUNT(*) AS total_records
FROM enrollment_data;

-- [1. Overall Enrollment Load]

SELECT
    SUM(age_0_5 + age_5_17 + age_18_greater) AS total_enrollments
FROM enrollment_data;

-- [2. State-wise Enrollment Pattern]

SELECT
    states,
    SUM(age_0_5 + age_5_17 + age_18_greater) AS total_enrollments
FROM enrollment_data
GROUP BY states
ORDER BY total_enrollments DESC;

-- [3. District Concentration Hotspots]

SELECT
    states,
    districts,
    SUM(age_0_5 + age_5_17 + age_18_greater) AS district_enrollments
FROM enrollment_data
GROUP BY states, districts
ORDER BY district_enrollments DESC;

-- [4. Age-wise Demand Distribution]

SELECT
    SUM(age_0_5) AS children_0_5,
    SUM(age_5_17) AS children_5_17,
    SUM(age_18_greater) AS adults_18_plus
FROM enrollment_data;

-- [5. Child Dependency Ratio]

SELECT
    states,
    ROUND(
        CAST(SUM(age_0_5 + age_5_17) AS DECIMAL(18,2))
        /
        NULLIF(SUM(age_18_greater), 0),
        2
    ) AS child_dependency_ratio
FROM enrollment_data
GROUP BY states
ORDER BY child_dependency_ratio DESC;

-- [6. Daily Enrollment Trend]

SELECT
    enroll_date,
    SUM(age_0_5 + age_5_17 + age_18_greater) AS daily_enrollments
FROM enrollment_data
GROUP BY enroll_date
ORDER BY enroll_date;

-- [7. Anomaly Detection]

SELECT
    enroll_date,
    states,
    districts,
    (age_0_5 + age_5_17 + age_18_greater) AS total_enrollment
FROM enrollment_data
WHERE (age_0_5 + age_5_17 + age_18_greater) >
(
    SELECT AVG(age_0_5 + age_5_17 + age_18_greater) * 2
    FROM enrollment_data
)
ORDER BY total_enrollment DESC;

-- [8. Pincode-level Operational Load]

SELECT
    pincode,
    SUM(age_0_5 + age_5_17 + age_18_greater) AS pincode_load
FROM enrollment_data
GROUP BY pincode
ORDER BY pincode_load DESC;

-- [9. Day-on-Day Enrollment Growth]

WITH daily_totals AS (
    SELECT
        enroll_date,
        SUM(age_0_5 + age_5_17 + age_18_greater) AS daily_enrollments
    FROM enrollment_data
    GROUP BY enroll_date
)
SELECT
    enroll_date,
    daily_enrollments -
    LAG(daily_enrollments)
    OVER (ORDER BY enroll_date) AS daily_growth
FROM daily_totals
ORDER BY enroll_date;

-- [10. Operational Load Index]

SELECT
    states,
    ROUND(
        SUM(age_0_5 * 1.2 +
            age_5_17 * 1.0 +
            age_18_greater * 0.8),
        2
    ) AS operational_load_index
FROM enrollment_data
GROUP BY states
ORDER BY operational_load_index DESC;

-- [11. Enrollment Volatility Index]

SELECT
    states,
    ROUND(
        STDDEV(age_0_5 + age_5_17 + age_18_greater),
        2
    ) AS enrollment_volatility
FROM enrollment_data
GROUP BY states
ORDER BY enrollment_volatility DESC;

-- [12. Enrollment Efficiency Score]

SELECT
    states,
    ROUND(
        SUM(age_0_5 + age_5_17 + age_18_greater)
        / COUNT(DISTINCT districts),
        2
    ) AS enrollment_efficiency
FROM enrollment_data
GROUP BY states
ORDER BY enrollment_efficiency DESC;


-- [13. Underperforming Districts]

WITH state_avg AS (
    SELECT
        states,
        AVG(age_0_5 + age_5_17 + age_18_greater) AS avg_enroll
    FROM enrollment_data
    GROUP BY states
)
SELECT
    e.states,
    e.districts,
    SUM(e.age_0_5 + e.age_5_17 + e.age_18_greater) AS district_enroll
FROM enrollment_data e
JOIN state_avg s
    ON e.states = s.states
GROUP BY e.states, e.districts, s.avg_enroll
HAVING SUM(e.age_0_5 + e.age_5_17 + e.age_18_greater) < s.avg_enroll
ORDER BY district_enroll;


-- [14. Adult Saturation Index] (MySQL)

SELECT
    states,
    ROUND(
        CAST(SUM(age_18_greater) AS DECIMAL(18,2))
        /
        NULLIF(
            SUM(age_0_5 + age_5_17 + age_18_greater),
            0
        ),
        2
    ) AS adult_saturation_index
FROM enrollment_data
GROUP BY states
ORDER BY adult_saturation_index DESC;


-- [15. Child-to-Teen Transition Pressure] (MySQL)

SELECT
    states,
    ROUND(
        CAST(SUM(age_0_5) AS DECIMAL(18,2))
        /
        NULLIF(SUM(age_5_17),0),
        2
    ) AS transition_pressure_ratio
FROM enrollment_data
GROUP BY states
ORDER BY transition_pressure_ratio DESC;


-- [16. Weekday-wise Load Distribution] (MySQL)

SELECT
    DAYOFWEEK(enroll_date) AS day_of_week,
    ROUND(
        AVG(age_0_5 + age_5_17 + age_18_greater),
        2
    ) AS avg_daily_load
FROM enrollment_data
GROUP BY day_of_week
ORDER BY day_of_week;

-- [17. Peak Pressure Days]

SELECT
    enroll_date,
    SUM(age_0_5 + age_5_17 + age_18_greater) AS peak_load
FROM enrollment_data
GROUP BY enroll_date
ORDER BY peak_load DESC
LIMIT 5;


-- [18. Long-Tail (Neglected) Districts]

WITH district_totals AS (
    SELECT
        districts,
        SUM(age_0_5 + age_5_17 + age_18_greater) AS total_enroll
    FROM enrollment_data
    GROUP BY districts
)
SELECT *
FROM district_totals
ORDER BY total_enroll ASC
LIMIT 10;


-- [19. Enrollment Momentum Score]

WITH daily_totals AS (
    SELECT
        enroll_date,
        SUM(age_0_5 + age_5_17 + age_18_greater) AS daily_enrollments
    FROM enrollment_data
    GROUP BY enroll_date
)
SELECT
    enroll_date,
    ROUND(
        (
            daily_enrollments -
            LAG(daily_enrollments)
            OVER (ORDER BY enroll_date)
        )
        /
        NULLIF(
            LAG(daily_enrollments)
            OVER (ORDER BY enroll_date),
            0
        ),
        2
    ) AS momentum_score
FROM daily_totals
ORDER BY enroll_date;


-- [20. Composite Risk Zone Classification]

WITH metrics AS (
    SELECT
        states,
        AVG(age_0_5 + age_5_17 + age_18_greater) AS avg_load,
        STDDEV(age_0_5 + age_5_17 + age_18_greater) AS volatility
    FROM enrollment_data
    GROUP BY states
)
SELECT
    states,
    avg_load,
    volatility,
    CASE
        WHEN avg_load > (SELECT AVG(avg_load) FROM metrics)
         AND volatility > (SELECT AVG(volatility) FROM metrics)
        THEN 'HIGH RISK'

        WHEN avg_load > (SELECT AVG(avg_load) FROM metrics)
        THEN 'MEDIUM RISK'

        ELSE 'LOW RISK'
    END AS risk_category
FROM metrics
ORDER BY risk_category;
