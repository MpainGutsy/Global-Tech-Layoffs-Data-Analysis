# 💼 Case Study: Global Tech Layoffs Data Analysis

![Layoffs-banner](https://github.com/user-attachments/assets/82cb03a2-3a66-4bd2-bfc3-daf544dfd5e6)

## 📚 Table of Contents

- [Business Task](#business-task)
- [Entity Design](#entity-design)
- [Step-by-Step SQL Process](#step-by-step-sql-process)
- [Data Cleaning Process](#data-cleaning-process)
- [Exploratory Data Analysis](#exploratory-data-analysis)
- [Insights & Observations](#insights--observations)

---

## 📌 Business Task

Tech layoffs surged across the globe. Using real-world layoff data, the goal is to:
- Clean and transform the raw data into a structured format.
- Analyze which companies, industries, and countries saw the most layoffs.
- Identify patterns over time to understand broader economic signals.

---

## 🧹 Entity Design

We used a single source table: `layoffs`, containing:
- Company, Location, Industry, Stage
- Layoff metrics (total, percentage)
- Date, Country, Funds Raised

Post-cleaning, we used a staging table `layoffs_sample` to prepare data for analysis.

---

## 🛠 Step-by-Step SQL Process

### 🔁 Step 1: Create a Staging Table

```sql
CREATE TABLE layoffs_staging LIKE layoffs;

INSERT INTO layoffs_staging
SELECT * FROM layoffs;
```

---

### 🔍 Step 2: Remove Duplicate Records

```sql
WITH duplicate_cte AS (
  SELECT *, 
    ROW_NUMBER() OVER (
      PARTITION BY company, location, industry, total_laid_off, percentage_laid_off, `date`, stage, country, funds_raised_millions
    ) AS row_num
  FROM layoffs_staging
)
DELETE FROM layoffs_sample
WHERE row_num > 1;
```

---

## 🧼 Data Cleaning Process

### ✅ Trim Whitespaces

```sql
UPDATE layoffs_sample
SET company = TRIM(company);
```

### ✅ Standardize Industries

```sql
UPDATE layoffs_sample
SET industry = 'Crypto'
WHERE industry LIKE 'Crypto%';
```

### ✅ Country Normalization

```sql
UPDATE layoffs_sample
SET country = 'United States'
WHERE country LIKE 'United States%';
```

### ✅ Date Conversion

```sql
UPDATE layoffs_sample
SET `date` = STR_TO_DATE(`date`, '%m/%d/%Y');

ALTER TABLE layoffs_sample
MODIFY COLUMN `date` DATE;
```

---

### 🔁 Fill Missing Industries

```sql
UPDATE layoffs_sample AS t1
JOIN layoffs_sample AS t2 ON t1.company = t2.company AND t1.location = t2.location
SET t1.industry = t2.industry
WHERE (t1.industry IS NULL OR t1.industry = '')
  AND t2.industry IS NOT NULL;
```

---

### 🗑 Remove Useless Rows

```sql
DELETE FROM layoffs_sample
WHERE total_laid_off IS NULL AND percentage_laid_off IS NULL;
```

---

## 📊 Exploratory Data Analysis

### 🔴 Fully Laid-Off Companies

```sql
SELECT * FROM layoffs_sample
WHERE percentage_laid_off = 1;
```

---

### 🏢 Companies with Highest Layoffs

```sql
SELECT company, SUM(total_laid_off) AS total
FROM layoffs_sample
GROUP BY company
ORDER BY total DESC;
```

---

### 🏪 Top Hit Industries

```sql
SELECT industry, SUM(total_laid_off) AS total
FROM layoffs_sample
GROUP BY industry
ORDER BY total DESC;
```

---

### 🌍 Country-Wise Impact

```sql
SELECT country, SUM(total_laid_off)
FROM layoffs_sample
GROUP BY country
ORDER BY 2 DESC;
```

---

### 📆 Year-Wise Trend

```sql
SELECT YEAR(`date`) AS year, SUM(total_laid_off)
FROM layoffs_sample
GROUP BY year
ORDER BY year DESC;
```

---

### 📈 Monthly Trend with Rolling Total

```sql
WITH monthly AS (
  SELECT DATE_FORMAT(`date`, '%Y-%m') AS month, SUM(total_laid_off) AS layoffs
  FROM layoffs_sample
  GROUP BY month
)
SELECT *, SUM(layoffs) OVER(ORDER BY month) AS rolling_total
FROM monthly;
```

---

### 🏆 Top 5 Companies by Year

```sql
WITH company_year AS (
  SELECT company, YEAR(`date`) AS year, SUM(total_laid_off) AS layoffs
  FROM layoffs_sample
  GROUP BY company, year
),
ranked AS (
  SELECT *, DENSE_RANK() OVER(PARTITION BY year ORDER BY layoffs DESC) AS rank
  FROM company_year
)
SELECT * FROM ranked WHERE rank <= 5;
```

---

## 💡 Insights & Observations

- **Rising Layoffs**: Peaks visible around major economic slowdowns (e.g., COVID recovery, inflation spikes).
- **Industries at Risk**: Tech and crypto took the hardest hits.
- **Geographic Pattern**: United States dominates layoff numbers.
- **Repeat Offenders**: Some companies show up in top 5 layoffs multiple years.



