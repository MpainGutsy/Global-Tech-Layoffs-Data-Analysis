select *
from layoffs ; 


#To do's
-- 1. Remove Duplicates 
-- 2. Standardize the data
-- 3. Remove any columns#

create table layoffs_staging
like layoffs ; 

insert layoffs_staging
select * 
from layoffs ; 

select * 
from layoffs_staging ; 

select * ,
ROW_NUMBER() OVER(
Partition by company , location , industry , total_laid_off , percentage_laid_off ,'date', stage , country , funds_raised_millions) AS row_num
from layoffs_staging; 

WITh duplicate_cte as 
( 
select * ,
ROW_NUMBER() OVER(
Partition by company , location , industry , total_laid_off , percentage_laid_off ,'date', stage , country , funds_raised_millions) AS row_num
from layoffs_staging
)
select * 
from duplicate_cte 
where row_num > 1; 


CREATE TABLE `LAYOFFS_SAMPLE` (
  `company` text,
  `location` text,
  `industry` text,
  `total_laid_off` int DEFAULT NULL,
  `percentage_laid_off` text,
  `date` text,
  `stage` text,
  `country` text,
  `funds_raised_millions` int DEFAULT NULL,
  `row_num` INT DEFAULT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci;

select * 
from layoffs_sample ;

insert into layoffs_sample 
select * ,
ROW_NUMBER() OVER(
Partition by company , location , industry , total_laid_off , percentage_laid_off ,'date', stage , country , funds_raised_millions) AS row_num
from layoffs_staging ;

DELETE
from layoffs_sample 
where row_num > 1 ;

select * 
from layoffs_sample ;


#--- standardizing the data

select company , TRIM(company)
from layoffs_sample ;

Update layoffs_sample
set company = trim(layoffs_sample.company) ; 

select * 
from layoffs_sample ;

select distinct industry 
from layoffs_sample 
order by 1; 

select * 
from layoffs_sample
where industry like 'Crypto%';

update layoffs_sample
set industry = 'Crypto'
where industry like 'Crypto%';

select * 
from layoffs_sample ;

Update layoffs_sample
set country = 'United States'
where country like 'United States%';

select `date` ,
str_to_date(`date` , '%m/%d/%Y') as date
from layoffs_sample ;

Update layoffs_sample
set `date` = str_to_date(`date` , '%m/%d/%Y')
;

alter table layoffs_sample
modify column `date` DATE ; 

--- Modifying Blank Columns

select *
From layoffs_sample as t1
JOIN layoffs_sample as t2
	on t1.company = t2.company
    and t1.location = t2.location
where (t1.industry is null or t1.industry = '')
AND t2.industry is not null ; 

update layoffs_sample
set industry = NULL 
where industry = '' ; 

select industry 
from layoffs_sample
where industry = NUll
 ;

update layoffs_sample t1
JOIN layoffs_sample as t2
	on t1.company = t2.company
set t1.industry = t2.industry
where (t1.industry is null or t1.industry = '')
AND t2.industry is not null ; 



select industry
From layoffs_sample as t1
JOIN layoffs_sample as t2
	on t1.company = t2.company
    and t1.location = t2.location
where (t1.industry is null or t1.industry = '')
AND t2.industry is not null ;

select total_laid_off , percentage_laid_off
from layoffs_sample
where total_laid_off is NULL
AND  percentage_laid_off is NULL;


Delete 
from layoffs_sample
where total_laid_off is NULL
AND  percentage_laid_off is NULL;

select total_laid_off , percentage_laid_off
from layoffs_sample
where total_laid_off is NULL
AND  percentage_laid_off is NULL;

alter table layoffs_sample
drop column row_num ;

select * 
from layoffs_sample ;

---#EDA - Exploratory Data Analysis

select * 
from layoffs_sample
where  percentage_laid_off = 1 ; 

select company , SUM( total_laid_off )
from layoffs_sample 
group by company 
order by 2 desc ; 

select industry , SUM( total_laid_off )
from layoffs_sample 
group by industry
order by 2 desc ; 

select country , SUM( total_laid_off )
from layoffs_sample 
group by country
order by 2 desc ; 

select year(`date`) , SUM( total_laid_off )
from layoffs_sample 
group by year(`date`)
order by 1 desc ; 

select substring(`date` , 1, 7 ) AS `Month` , SUM(total_laid_off)
from layoffs_sample
where substring(`date` , 1, 7 ) is not null
group by `Month`
order by 1 ASC 
; 

with Rolling_total as 
(select substring(`date` , 1, 7 ) AS `Month` , SUM(total_laid_off) as total_off
from layoffs_sample
where substring(`date` , 1, 7 ) is not null
group by `Month`
order by 1 ASC 
)
select `Month` , total_off , SUM(total_off)over(order by `Month`) as rolling_total
from Rolling_total ; 

select company , YEAR(`date`) , SUM(totaL_laid_off) 
from layoffs_sample 
group by company , YEAR(`date`)
order by 3 desc ;


with company_year (company , years , total_laid_off ) as
(
select company , YEAR(`date`) , SUM(totaL_laid_off) 
from layoffs_sample 
group by company , YEAR(`date`)
order by 3 desc 
)
 , company_year_rank as
(select * , dense_rank()Over(partition by years order by total_laid_off desc) as ranking
from company_year
where years is not null
order by ranking asc )
select *
from company_year_rank 
where ranking <= 5 
;