CREATE DATABASE healthcare_analysis;
USE healthcare_analysis;

Show databases;

CREATE TABLE healthcare (
    Name VARCHAR(100),
    Age INT,
    Gender VARCHAR(20),
    Blood_Type VARCHAR(10),
    Medical_Condition VARCHAR(50),
    Date_of_Admission DATE,
    Doctor VARCHAR(100),
    Hospital VARCHAR(150),
    Insurance_Provider VARCHAR(50),
    Billing_Amount DECIMAL(10,2),
    Room_Number INT,
    Admission_Type VARCHAR(30),
    Discharge_Date DATE,
    Medication VARCHAR(50),
    Test_Results VARCHAR(30),
    Length_of_Stay INT,
    Age_Group VARCHAR(20)
);

DESCRIBE healthcare;

SELECT COUNT(*) FROM healthcare;

SELECT *
FROM healthcare
LIMIT 10;

/* What is the overall patient volume and average healthcare cost?*/
SELECT
    COUNT(*) AS total_patients,
    ROUND(AVG(Billing_Amount), 2) AS average_bill,
    ROUND(AVG(Length_of_Stay), 2) AS average_stay
FROM healthcare;

/*Which medical conditions are most common among patients?*/
SELECT
    Medical_Condition,
    COUNT(*) AS patient_count
FROM healthcare
GROUP BY Medical_Condition
ORDER BY patient_count DESC;

/*How do different admission types compare in terms of patient volume, billing, and length of stay?*/
SELECT
    Admission_Type,
    COUNT(*) AS patient_count,
    ROUND(AVG(Billing_Amount), 2) AS average_bill,
    ROUND(AVG(Length_of_Stay), 2) AS average_stay
FROM healthcare
GROUP BY Admission_Type
ORDER BY patient_count DESC;

/*How does patient distribution vary across different age groups?*/
SELECT
    Age_Group,
    COUNT(*) AS patient_count,
    ROUND(AVG(Age)) AS average_age,
    ROUND(AVG(Billing_Amount), 2) AS average_bill,
    ROUND(AVG(Length_of_Stay), 2) AS average_stay
FROM healthcare
GROUP BY Age_Group
ORDER BY patient_count DESC;

/*Which insurance providers cover the most patients and what is their average billing?*/
SELECT
    Insurance_Provider,
    COUNT(*) AS patient_count,
    ROUND(AVG(Billing_Amount), 2) AS average_bill
FROM healthcare
GROUP BY Insurance_Provider
ORDER BY patient_count DESC;

/*Which medical conditions have the highest abnormal test-result rates?*/
SELECT
    Medical_Condition,
    COUNT(*) AS total_patients,
    SUM(
        CASE
            WHEN Test_Results = 'Abnormal' THEN 1
            ELSE 0
        END
    ) AS abnormal_cases,
    ROUND(
        SUM(
            CASE
                WHEN Test_Results = 'Abnormal' THEN 1
                ELSE 0
            END
        ) * 100.0 / COUNT(*),
        2
    ) AS abnormal_rate
FROM healthcare
GROUP BY Medical_Condition
ORDER BY abnormal_rate DESC;

/*Which hospitals have more than 10 patients and what is their average billing?*/
SELECT
    Hospital,
    COUNT(*) AS patient_count,
    ROUND(AVG(Billing_Amount), 2) AS average_bill
FROM healthcare
GROUP BY Hospital
HAVING COUNT(*) > 10
ORDER BY patient_count DESC;

/*Which medical condition has the highest average billing?*/
SELECT
    Medical_Condition,
    average_bill
FROM (
    SELECT
        Medical_Condition,
        ROUND(AVG(Billing_Amount), 2) AS average_bill
    FROM healthcare
    GROUP BY Medical_Condition
) AS condition_data
ORDER BY average_bill DESC
LIMIT 1;

/*What is the most commonly prescribed medication for each medical condition?*/
WITH medication_counts AS (
    SELECT
        Medical_Condition,
        Medication,
        COUNT(*) AS patient_count
    FROM healthcare
    GROUP BY Medical_Condition, Medication
),
ranked_medications AS (
    SELECT
        Medical_Condition,
        Medication,
        patient_count,
        RANK() OVER (
            PARTITION BY Medical_Condition
            ORDER BY patient_count DESC
        ) AS rnk
    FROM medication_counts
)
SELECT
    Medical_Condition,
    Medication,
    patient_count
FROM ranked_medications
WHERE rnk = 1;

/*How has the number of patient admissions changed compared with the previous year?*/
WITH yearly_data AS (
    SELECT
        YEAR(Date_of_Admission) AS admission_year,
        COUNT(*) AS patient_count
    FROM healthcare
    GROUP BY YEAR(Date_of_Admission)
)
SELECT
    admission_year,
    patient_count,
    LAG(patient_count) OVER (
        ORDER BY admission_year
    ) AS previous_year_patients
FROM yearly_data
ORDER BY admission_year;

/*What is the most common medical condition within each admission type?*/
WITH condition_counts AS (
    SELECT
        Admission_Type,
        Medical_Condition,
        COUNT(*) AS patient_count
    FROM healthcare
    GROUP BY Admission_Type, Medical_Condition
),
ranked_conditions AS (
    SELECT
        Admission_Type,
        Medical_Condition,
        patient_count,
        RANK() OVER (
            PARTITION BY Admission_Type
            ORDER BY patient_count DESC
        ) AS rnk
    FROM condition_counts
)
SELECT
    Admission_Type,
    Medical_Condition,
    patient_count
FROM ranked_conditions
WHERE rnk = 1
ORDER BY Admission_Type;

/*Which insurance provider has the largest share of patients?*/
WITH insurance_data AS (
    SELECT
        Insurance_Provider,
        COUNT(*) AS patient_count
    FROM healthcare
    GROUP BY Insurance_Provider
)
SELECT
    Insurance_Provider,
    patient_count,
    ROUND(
        patient_count * 100.0 /
        SUM(patient_count) OVER (),
        2
    ) AS patient_percentage
FROM insurance_data
ORDER BY patient_count DESC;

/*Which medical condition has the longest average hospital stay?*/
SELECT
    Medical_Condition,
    ROUND(AVG(Length_of_Stay), 2) AS average_stay
FROM healthcare
GROUP BY Medical_Condition
ORDER BY average_stay DESC
LIMIT 1;

/*Which month had the highest number of patient admissions?*/
SELECT
    MONTHNAME(Date_of_Admission) AS admission_month,
    COUNT(*) AS patient_count
FROM healthcare
GROUP BY MONTH(Date_of_Admission), MONTHNAME(Date_of_Admission)
ORDER BY patient_count DESC
LIMIT 1;

/*Which patients have a billing amount higher than the overall average billing?*/
SELECT
    Name,
    Medical_Condition,
    Billing_Amount
FROM healthcare
WHERE Billing_Amount > (
    SELECT AVG(Billing_Amount)
    FROM healthcare
)
ORDER BY Billing_Amount DESC;