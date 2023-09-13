select * 
from Projects..CovidDeaths$
order by 3,4

--select * 
--from Projects..CovidVaccinations$
--order by 3,4

Select location, date, total_cases, new_cases, total_deaths,population
from Projects..CovidDeaths$
Order by 1,2

--Looking at total cases vs total deaths
--shows the likelihood of dying if people contract covid in (Ethiopia)
Select location,date,total_cases, total_deaths,(cast(total_deaths AS float)/cast(total_cases AS float))*100 as DeathPercentage
from Projects..CovidDeaths$
where location like '%Ethiopia%'
Order by 1,2

--looking at the total cases vs the population
--shows what percentage of population got covid
Select location,date,population,total_cases, total_deaths,(cast(total_deaths AS float)/cast(total_cases AS float))*100 as DeathPercentage
from Projects..CovidDeaths$
where location like '%Ethiopia%'
Order by 1,2

--showing countries with the highest death count per population
Select Location, Max(cast(total_deaths as bigint)) as TotalDeathCount
From Projects..CovidDeaths$
where continent is null
Group by location
Order by TotalDeathCount desc


--breaking things down by continent
Select continent, Max(cast(total_deaths as bigint)) as TotalDeathCount
From Projects..CovidDeaths$
where continent is not null
Group by continent
Order by TotalDeathCount desc

--Global numbers
--Tableau 1 Global covid cases and deaths

Select SUM(new_cases) as total_cases, SUM(cast(new_deaths as int)) as total_deaths,
 SUM(cast(new_deaths as int))/NULLIF(SUM(new_cases),0)*100 as DeathPercentage
From Projects..CovidDeaths$
--where location like '%Ethiopia%'
where continent is not null
--Group by date
order by 1,2

--Tableau 2 Total deaths per Continent
SELECT location, SUM(Cast(new_deaths as int)) as TotalDeathCount
from Projects..CovidDeaths$
Where continent is null
and location not in('High income','European Union','Low income','Lower middle income')
Group by location
order by TotalDeathCount desc


--Tableau 3 
--looking at countries with highest infection rate comapred to the population
Select location,population,MAX(total_cases) as HighestInfectionCount, 
  Max(cast(total_cases AS float)/cast(population AS float))*100 as PercentPopulationInfected
from Projects..CovidDeaths$
--where location like '%Ethiopia%'
Group by location,population
Order by PercentPopulationInfected desc

--4 Percent population infected in populous African Countries
Select location, Population, date, MAX(total_cases) as HighestINfectionCount, Max((total_cases/population))*100 as PercentPopulationInfected
From Projects..CovidDeaths$
Group by location,Population,date
order by PercentPopulationInfected desc


--looking at total population vs total vaccination
--USe CTE
-- Create the temporary table separately
IF OBJECT_ID('tempdb..#PercentPopulationVaccinated') IS NOT NULL
    DROP TABLE #PercentPopulationVaccinated;

CREATE TABLE #PercentPopulationVaccinated (
  Continent nvarchar(255),
  Location nvarchar(255),
  Date datetime,
  Population numeric,
  New_vaccinations numeric,
  RollingPeopleVaccinated numeric
);

-- Populate the temporary table
INSERT INTO #PercentPopulationVaccinated
SELECT
  Death.continent,
  Death.location,
  Death.date,
  Death.population,
  Vax.new_vaccinations,
  SUM(CONVERT(bigint, Vax.new_vaccinations)) OVER (PARTITION BY Death.location ORDER BY Death.location, Death.date) AS rollingPeopleVaccinated
FROM
  Projects..CovidVaccinations$ Vax
JOIN
  Projects..CovidDeaths$ Death ON Vax.location = Death.location AND Vax.date = Death.date
WHERE
  Death.continent IS NOT NULL;

-- Use the temporary table within the CTE
WITH Popvsvac AS (
  SELECT
    Continent,
    Location,
    Date,
    Population,
    New_vaccinations,
    RollingPeopleVaccinated
  FROM
    #PercentPopulationVaccinated
)
SELECT *
FROM Popvsvac;

select *, (RollingPeopleVaccinated/population)*100
from #PercentPopulationVaccinated

--creating VIEW to store data for Visulaization later
CREATE VIEW PercentOfPopulationVaccinated AS
SELECT
  Death.continent,
  Death.location,
  Death.date,
  Death.population,
  Vax.new_vaccinations,
  SUM(CONVERT(bigint, Vax.new_vaccinations)) OVER (PARTITION BY Death.location ORDER BY Death.location, Death.date) AS RollingPeopleVaccinated
FROM
  Projects..CovidDeaths$ Death
JOIN
  Projects..CovidVaccinations$ Vax
  ON Death.location = Vax.location
  AND Death.date = Vax.date
WHERE
  Death.continent IS NOT NULL;


SELECT * FROM PercentOfPopulationVaccinated;































