

-- Total deaths and infections over time
SELECT Location, date, total_cases, total_deaths, (total_deaths/total_cases)*100 as DeathRate, (total_cases/population)*100 as InfectionRate 
FROM CovidDeaths
WHERE LoCATION like '%states%'
ORDER BY 1,2

-- Order countries by highest infection rate on a specific date
SELECT Location, date, total_cases, population, (total_cases/population)*100 AS InfectionRate
FROM CovidDeaths
WHERE date = '2021-04-30'
ORDER BY InfectionRate DESC

-- Order countries by highest infection rate ever reached
SELECT LOCATION, POPULATION, MaX(total_cases) AS HighestInfectionCount, MAX((total_cases/population))*100 AS PercentagePopInfected
FROM CovidDeaths
GROUP BY LOCATION, POPULATION
ORDER BY PercentagePopInfected DESC

-- Order countries by highest number of deaths
SELECT LOCATION, max(cast(total_deaths AS INT)) AS DeathCount
FROM CovidDeaths
WHERE continent IS NOT NULL
GROUP BY LOCATION, POPULATION
ORDER BY DeathCount DESC
s
-- Order continents by highest number of deaths
SELECT LOCATION, max(cast(total_deaths AS INT)) AS DeathCount
FROM CovidDeaths
WHERE continent IS NULL
GROUP BY LOCATION
ORDER BY DeathCount DESC

-- Order continents by highest death rate
SELECT LOCATION, max(cast(total_deaths AS INT)/population)*100 AS DeathRate
FROM CovidDeaths
WHERE continent IS NULL
GROUP BY LOCATION
ORDER BY DeathRate DESC

-- Time Series of Daily Cases and Deaths across Globe
SELECT date, sum(new_cases) AS daily_cases, sum(cast(new_deaths AS int)) AS daily_deaths,
	sum(cast(new_deaths AS int))/sum(new_cases)*100 AS DailyDeathPercent
FROM CovidDeaths
WHERE continent IS NOT NULL
GROUP BY date
ORDER BY 1,2

-- Rolling Vaccination Sum for each country
SELECT dea.continent, dea.location, dea.date, dea.population, 
	vac.new_vaccinations, 
	sum(convert(int,vac.new_vaccinations)) OVER (PARTITION BY dea.Location ORDER BY dea.location, dea.date)
FROM CovidDeaths dea
JOIN CovidVaccines vac
	ON dea.location = vac.location
	AND dea.date = vac.date
WHERE dea.continent IS NOT NULL
ORDER BY 2,3




-- Rolling Vax Count w/ Rolling Percentage of Population Vaccinated
-- (First way)
WITH PopvsVac (Continent, Location, Date, Population, New_Vaccs, RollingVaxCount)
AS
(
SELECT dea.continent, dea.location, dea.date, dea.population, 
	vac.new_vaccinations, 
	sum(convert(int,vac.new_vaccinations)) OVER (PARTITION BY dea.Location ORDER BY dea.location, dea.date)
FROM CovidDeaths dea
JOIN CovidVaccines vac
	ON dea.location = vac.location
	AND dea.date = vac.date
WHERE dea.continent IS NOT NULL
)
SELECT *, (RollingVaxCount/Population)*100 AS VaxPercentage
FROM PopvsVac





-- (Second way, temp table)
DROP TABLE IF EXISTS #PercentPopulationVaccinated
Create Table #PercentPopulationVaccinated
(
Continent nvarchar(255),
Location nvarchar(255),
Date datetime,
Population numeric,
New_vaccinations numeric,
RollingVaxCount numeric
)

Insert into #PercentPopulationVaccinated
SELECT dea.continent, dea.location, dea.date, dea.population, 
	vac.new_vaccinations, 
	sum(convert(numeric,vac.New_vaccinations)) OVER (PARTITION BY dea.Location ORDER BY dea.location, dea.date)
FROM CovidDeaths dea
JOIN CovidVaccines vac
	ON dea.location = vac.location
	AND dea.date = vac.date
--WHERE dea.continent IS NOT NULL

SELECT *, (RollingVaxCount/Population)*100
FROM #PercentPopulationVaccinated

-- Creating view to store data for visualizations
Create View PercentPopVaxxed AS 
SELECT dea.continent, dea.location, dea.date, dea.population, 
	vac.new_vaccinations, 
	sum(convert(numeric,vac.New_vaccinations)) OVER (PARTITION BY dea.Location ORDER BY dea.location, dea.date) AS RollingVaxCount
FROM CovidDeaths dea
JOIN CovidVaccines vac
	ON dea.location = vac.location
	AND dea.date = vac.date
WHERE dea.continent IS NOT NULL




-- Call on view
SELECT *
FROM PercentPopVaxxed