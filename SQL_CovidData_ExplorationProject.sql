/*
Covid 19 Data Exploration with SQL

Skills used: Joins, CTE's, Temp Tables, Windows Functions, Aggregate Functions, Creating Views, Converting Data Types

*/

SELECT *
FROM SQL_Covid_Project..covid_deaths
WHERE continent is not null
ORDER BY 3,4

SELECT *
FROM SQL_Covid_Project..covid_vaccinations
WHERE continent is not null
ORDER BY 3,4 

Select
	location,
	date,
	total_cases,
	new_cases,
	total_deaths,
	population
From SQL_Covid_Project..covid_deaths
where continent is not null
order by 1,2


-- Looking at Total Cases vs Total Deaths
-- Shows the probability of dying if you contract covid in your country

Select
	location,
	date,
	total_cases,
	total_deaths,
	(cast(total_deaths as numeric)/cast(total_cases as numeric))*100 as DeathPercentage 
From SQL_Covid_Project..covid_deaths
where continent is not null
order by 1,2


-- Looking at Total Cases vs Total Deaths United States

Select
	location,
	date,
	total_cases,
	total_deaths,
	(cast(total_deaths as numeric)/cast(total_cases as numeric))*100 as DeathPercentage 
From SQL_Covid_Project..covid_deaths
Where location like '%states%'
order by 1,2


-- Looking at the Total Cases vs the Population (in the US)
-- Shows the percentatge of population that contracted Covid

Select
	location,
	date,
	population,
	total_cases,
	(total_cases/population)*100 as Contraction_Percentage
From SQL_Covid_Project..covid_deaths
Where location like '%states%'
order by 1,2

-- Looking at Countries with the Highest Infection Rate vs Population

Select
	location,
	population,
	MAX(total_cases) as Highest_Infection_Count,
	MAX((total_cases/population))*100 as Infection_Percentage
FROM SQL_Covid_Project..covid_deaths
where continent is not null
Group by location, Population
order by Infection_Percentage desc


-- Looking at Countries with the Highest Death Count per Population

Select
	location,
	MAX(total_deaths) as Total_Death_Count
FROM SQL_Covid_Project..covid_deaths
where continent is not null
Group by location
order by Total_Death_Count desc


-- Breakdown by Continent

Select
	continent,
	MAX(total_deaths) as Total_Death_Count
FROM SQL_Covid_Project..covid_deaths
where continent is not null
Group by continent
order by Total_Death_Count desc

-- Continent with Highest Death Count per Population

Select
	location,
	MAX(total_deaths) as Total_Death_Count
FROM SQL_Covid_Project..covid_deaths
where continent is null
Group by location
order by Total_Death_Count desc


-- Global Numbers

Select
	SUM(new_cases) as total_cases,
	SUM(cast(new_deaths as int)) as total_deaths,
	SUM(cast(new_deaths as int))/SUM(New_Cases)*100 as Death_Percentage
From SQL_Covid_Project..covid_deaths
where continent is not null 
order by 1,2


-- Joining Covid Death with Covid Vaccinations

Select *
FROM SQL_Covid_Project..covid_deaths death
Join SQL_Covid_Project..covid_vaccinations vax
	On death.location = vax.location
	and death.date = vax.date
WHERE death.continent is not null


-- Total Population vs Vaccinations
-- Shows Percentage of Population that has recieved at least one Covid Vaccine

Select
	death.continent, 
	death.location,
	death.date,
	death.population,
	vax.new_vaccinations,
	SUM(CONVERT(numeric, vax.new_vaccinations)) 
		OVER (Partition by death.Location Order by death.location, death.Date)
		as RollingCountVaccinated
From SQL_Covid_Project..covid_deaths death
Join SQL_Covid_Project..covid_vaccinations vax
	On death.location = vax.location
	and death.date = vax.date
where death.continent is not null 
order by 2,3


-- USE CTE (Common Table Expression)

With population_VS_vaccination (Continent, Location, Date, Population, new_vaccinations, Rolling_Count_Vaccinated)
as
(
Select 
	death.continent, 
	death.location,
	death.date,
	death.population,
	vax.new_vaccinations,
	SUM(CONVERT(numeric, vax.new_vaccinations)) 
		OVER (Partition by death.Location Order by death.location, death.Date)
		as Rolling_Count_Vaccinated 
From SQL_Covid_Project..covid_deaths death
Join SQL_Covid_Project..covid_vaccinations vax
	On death.location = vax.location
	and death.date = vax.date
where death.continent is not null 
)
Select * , (Rolling_Count_Vaccinated/population)*100 as Rolling_Count_Percentage
From population_VS_vaccination


-- Temporary Table

DROP table if exists #Percentage_Population_Vaccinated
Create Table #Percent_Population_Vaccinated
(
continent nvarchar(255),
location nvarchar(255),
date datetime,
population numeric,
new_vaccinations numeric,
Rolling_Count_Vaccinated numeric
)

Insert into #Percent_Population_Vaccinated
Select
	death.continent, 
	death.location,
	death.date,
	death.population,
	vax.new_vaccinations,
	SUM(CONVERT(numeric, vax.new_vaccinations)) 
		OVER (Partition by death.Location Order by death.location, death.Date)
		as Rolling_Count_Vaccinated 
From SQL_Covid_Project..covid_deaths death
Join SQL_Covid_Project..covid_vaccinations vax
	On death.location = vax.location
	and death.date = vax.date
where death.continent is not null

Select * , (Rolling_Count_Vaccinated/population)*100 as Rolling_Count_Percentage
From #Percent_Population_Vaccinated


-- Create View to store data for visualizations

Create View Percent_of_Population_Vaccinated as
Select
	death.continent,
	death.location,
	death.date,
	death.population,
	vax.new_vaccinations,
	SUM(CONVERT(int,vax.new_vaccinations))
		OVER (Partition by death.Location Order by death.location, death.Date)
		as Rolling_Count_Vaccinated
--, (Rolling_Count_Vaccinated/population)*100
From SQL_Covid_Project..covid_deaths death
Join SQL_Covid_Project..covid_vaccinations vax
	On death.location = vax.location
	and death.date = vax.date
where death.continent is not null 

SELECT *
FROM Percent_of_Population_Vaccinated
