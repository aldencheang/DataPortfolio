SELECT *
FROM `Covid Deaths`.CovidDeaths cd 
WHERE cd.continent is not NULL
ORDER BY 3,4

SELECT Location, date, total_cases, new_cases, total_deaths, population
FROM `Covid Deaths`.CovidDeaths cd 
ORDER BY 1, 2

-- Cleaning data to make sure blank spaces will come out at NULL

UPDATE CovidDeaths 
SET continent = NULLIF(continent, '');

-- Clean date column up since it is importing as a VARCHAR 

ALTER TABLE CovidDeaths 
ADD COLUMN clean_date DATE;

UPDATE CovidDeaths
SET clean_date = STR_TO_DATE(date, '%c/%e/%y');

SELECT *
FROM CovidDeaths;

-- Move clean_date to the 4th position

ALTER TABLE CovidDeaths 
MODIFY COLUMN clean_date DATE AFTER location;

-- Check for data that we are now going to use

SELECT Location, clean_date, total_cases, new_cases, total_deaths, population
FROM `Covid Deaths`.CovidDeaths  
ORDER BY 1, 2

-- Total Cases vs Total Deaths 
-- Shows likiehood of dying given you contracting COVID-19 in the United States aggregated by date
SELECT Location, clean_date, total_cases, total_deaths, (total_deaths/total_cases)*100 as DeathPercentage
FROM `Covid Deaths`.CovidDeaths 
WHERE location like 'United States'
ORDER BY 1, 2

-- Total Cases vs Population
-- Shows population that has contracted COVID-19
SELECT Location, clean_date, total_cases, (total_cases/population)*100 as ContractedPercentage
FROM `Covid Deaths`.CovidDeaths 
WHERE location like 'United States'
ORDER BY 1, 2

-- What countries have the highest infection rate relative to the population

SELECT Location, Population, MAX(total_cases) as HighestInfectionCount, MAX((total_cases/population))*100 as ContractedPopluationPercentage
FROM `Covid Deaths`.CovidDeaths 
GROUP BY location, population 
ORDER BY 1, 2

-- Countries with the highest death count relative to the popluation 

SELECT Location, Population, MAX(total_deaths) as TotalDeathCount, MAX((total_deaths/population))*100 as HighestDeathPercentage
FROM `Covid Deaths`.CovidDeaths 
WHERE continent is not NULL
GROUP BY location, population 
ORDER BY HighestDeathPercentage DESC

-- Highest death broken down by contienents

SELECT continent, MAX(total_deaths) as TotalDeathCount
FROM `Covid Deaths`.CovidDeaths cd 
WHERE cd.continent IS NOT NULL
GROUP BY cd.continent 
ORDER BY TotalDeathCount desc

-- Global Statistics

SELECT clean_date, SUM(new_cases) as TotalGlobalCases, sum(new_deaths) as TotalGlobalDeaths, SUM(new_deaths)/SUM(new_cases)*100 as GlobalDeathPercentage
FROM `Covid Deaths`.CovidDeaths cd 
WHERE cd.continent is not NULL 
GROUP BY clean_date
ORDER BY 1,2

-- Covid Vaccine Table

SELECT * 
FROM CovidVaccinations
 
-- Clean dates column since it imported as VARCHAR

ALTER TABLE CovidVaccinations 
ADD COLUMN clean_date DATE;

UPDATE CovidVaccinations
SET clean_date = STR_TO_DATE(date, '%c/%e/%y');

SELECT *
FROM CovidVaccinations;

-- Move clean_date to the 4th position

ALTER TABLE CovidVaccinations 
MODIFY COLUMN clean_date DATE AFTER location;

SELECT *
FROM CovidVaccinations;

-- CovidDeaths & CovidVaccinations

SELECT *
FROM CovidDeaths cd 
JOIN CovidVaccinations cv 
	ON cd.clean_date = cv.clean_date
	AND cd.location = cv.location 

-- Total popluation vs vaccinations in world
WITH PopVsVac AS
(
SELECT 
	cd.continent 
	,cd.location
	,cd.clean_date
	,cd.population
	,cv.new_vaccinations
	,SUM(cv.new_vaccinations) OVER (PARTITION BY cd.location ORDER BY cd.location, cd.clean_date) AS RollingVaccinationCount
FROM `Covid Deaths`.CovidDeaths cd 
JOIN `Covid Deaths` .CovidVaccinations  cv 
	ON cd.clean_date = cv.clean_date 
	AND cd.location = cv.location 
WHERE cd.continent IS NOT NULL
)
SELECT *, (RollingVaccinationCount/Population)*100 AS VaccinationRate
FROM PopVsVac;

-- Creating a Temp Table to do PARTITION BY analysis

DROP TEMPORARY TABLE IF EXISTS PercentPopulationVaccinated;
CREATE TEMPORARY TABLE PercentPopulationVaccinated
(
	continent VARCHAR(255),
	location VARCHAR(255),
	`date` DATE,
	Population BIGINT,
	new_vaccinations VARCHAR(255),
	RollingVaccinationCount BIGINT
);

INSERT INTO PercentPopulationVaccinated
SELECT 
	cd.continent 
	,cd.location
	,cd.clean_date
	,cd.population
	,cv.new_vaccinations
	,SUM(cv.new_vaccinations) OVER (PARTITION BY cd.location ORDER BY cd.location, cd.clean_date) AS RollingVaccinationCount
FROM `Covid Deaths`.CovidDeaths cd 
JOIN `Covid Deaths`.CovidVaccinations  cv 
	ON cd.clean_date = cv.clean_date 
	AND cd.location = cv.location;
	
SELECT *, (RollingVaccinationCount/Population)*100 AS VaccinationRate
FROM PercentPopulationVaccinated;

-- View for data visualization 

CREATE VIEW PercentPopulationVaccinated AS
SELECT cd.continent, cd.location, cd.date, cd.population, cv.new_vaccinations
, SUM(cv.new_vaccinations) OVER (Partition by cd.Location Order by cd.location, cd.Date) as RollingVaccinationCount
FROM CovidDeaths cd
JOIN CovidVaccinations cv
	ON cd.location = cv.location
	AND cd.date = cv.date
WHERE cd.continent IS NOT NULL


