select *
from coviddeaths
order by 3,4;

select *
from coviddeaths
where continent not like ''
order by 3,4;

select *
from covidvaccinations 
order by 3,4;

-- creating backup table to prevent data loss 
-- attempting to change column type of 'date' to date instead of varchar

create table coviddeaths_backup as select * 
from CovidPortfolioProject.coviddeaths; 

select date
from coviddeaths_backup
where str_to_date(date, '%m-%d-%Y') is null;

-- returning dates as null values
-- changing format string to '%m/%d/%Y' since returned values were not hyphenated
-- updating backup table to the correct date format

update coviddeaths_backup
set date = DATE_FORMAT(STR_TO_DATE(date, '%m/%d/%Y'), '%Y-%m-%d');

-- checking for no null values 

select date
from coviddeaths_backup
where STR_TO_DATE(date, '%Y-%m-%d') is null; 

alter table coviddeaths_backup 
modify date DATE;

select date
from coviddeaths_backup 
order by 1;

-- comfirming it works
-- going back to original table
-- repeating steps from backup table to original table

select date 
from coviddeaths
where STR_TO_DATE(date, '%m/%d/%Y') is null;

update coviddeaths 
set date = DATE_FORMAT(STR_TO_DATE(date, '%m/%d/%Y'), '%Y-%m-%d');

select date
from coviddeaths
where STR_TO_DATE(date, '%Y-%m-%d') is null; 

alter table coviddeaths
modify date DATE; 

select location, date
from coviddeaths
order by 1,2;

select location, date, total_cases, new_cases, total_deaths, population
from coviddeaths
order by 1,2;

-- checking table for mistakes

describe coviddeaths;

select * 
from coviddeaths 
limit 100;

-- looking at total cases vs total deaths 
-- calculating risk of dying if you contract covid 

select location, date, total_cases, total_deaths, (total_deaths/total_cases)*100 as DeathPercentage
from coviddeaths
where continent not like ''
and location like '%states%'
order by 1,2;

-- looking at total cases vs population 
-- calculating percentage of population that got covid

select location, date, total_cases, population, (total_cases/population)*100 as PercentPopulationInfected
from coviddeaths
where continent not like ''
and location like '%states%'
order by 1,2;

-- looking at countries with highest infection rate compared to population 

select location, MAX(total_cases) as HighestInfectionCount, population, MAX((total_cases/population))*100 as PercentPopulationInfected
from coviddeaths
where continent not like ''
group by location, population 
order by PercentPopulationInfected desc;

-- showing countries with highest death count per population

select location, MAX(total_deaths) as TotalDeathCount
from coviddeaths
where continent not like ''
group by location
order by TotalDeathCount desc;

-- breaking it down by continent
-- showing continents with the highest death count per population

select location, MAX(total_deaths) as TotalDeathCount
from coviddeaths
where continent like ''
group by location
order by TotalDeathCount desc;

-- global numbers

select date, SUM(new_cases) as total_cases, SUM(new_deaths) as total_deaths, SUM(new_deaths)/SUM(new_cases)*100 as DeathPercentage
from coviddeaths
where continent not like ''
group by date
order by 1,2;

select SUM(new_cases) as total_cases, SUM(new_deaths) as total_deaths, SUM(new_deaths)/SUM(new_cases)*100 as DeathPercentage
from coviddeaths
where continent not like ''
order by 1,2;

-- joining the two tables

select*
from coviddeaths dea
join covidvaccinations vac
	on dea.location = vac.location 
	and dea.date = vac.date
	
-- recieving an error, need to fix datetime value for covidvaccination table first
	
describe covidvaccinations;

select date
from covidvaccinations
where str_to_date(date, '%m/%d/%Y') is null;

update covidvaccinations
set date = DATE_FORMAT(STR_TO_DATE(date, '%m/%d/%Y'), '%Y-%m-%d');

select date
from covidvaccinations 
where STR_TO_DATE(date, '%Y-%m-%d') is null; 

alter table covidvaccinations 
modify date DATE; 

select*
from covidvaccinations;

-- can now join the two tables
-- looking at total population vs vaccinations

select*
from coviddeaths dea
join covidvaccinations vac
	on dea.location = vac.location 
	and dea.date = vac.date

select dea.continent, dea.location, dea.date, dea.population, vac.new_vaccinations, SUM(vac.new_vaccinations) over (partition by dea.location order by dea.location, dea.date) as RollingPeopleVaccinated
from coviddeaths dea
join covidvaccinations vac
	on dea.location = vac.location 
	and dea.date = vac.date
where dea.continent not like ''
order by 1,2,3;

-- using cte in order to be able to use the newly created column for further calculations

with PopvsVac (Continent, Location, Date, Population, new_vaccinations, RollingPeopleVaccinated)
as
(
select dea.continent, dea.location, dea.date, dea.population, vac.new_vaccinations, SUM(vac.new_vaccinations) over (partition by dea.location order by dea.location, dea.date) as RollingPeopleVaccinated
from coviddeaths dea
join covidvaccinations vac
	on dea.location = vac.location 
	and dea.date = vac.date
where dea.continent not like ''
)
select *, (RollingPeopleVaccinated/Population)*100
from PopvsVac;

-- isolating vaccinations in the United States

with PopvsVac (Continent, Location, Date, Population, new_vaccinations, RollingPeopleVaccinated)
as
(
select 
dea.continent, 
dea.location, 
dea.date, 
dea.population, 
vac.new_vaccinations, 
SUM(vac.new_vaccinations) over (partition by dea.location order by dea.location, dea.date) as RollingPeopleVaccinated
from coviddeaths dea
join covidvaccinations vac
	on dea.location = vac.location 
	and dea.date = vac.date
where dea.continent not like ''
)
select *, (RollingPeopleVaccinated/Population)*100
from PopvsVac
where location like '%United States%';

-- finding out how # of vaccinations correlate to the # of deaths

with PopvsVac (Continent, Location, Date, Population, new_vaccinations, new_cases, new_deaths, DeathPercentage, RollingPeopleVaccinated)
as
(
select 
dea.continent, 
dea.location, 
dea.date, 
dea.population, 
vac.new_vaccinations, 
dea.new_cases,
dea.new_deaths,
(dea.new_deaths)/(dea.new_cases)*100 as DeathPercentage, 
SUM(vac.new_vaccinations) over (partition by dea.location order by dea.location, dea.date) as RollingPeopleVaccinated
from coviddeaths dea
join covidvaccinations vac
	on dea.location = vac.location 
	and dea.date = vac.date
where dea.continent not like ''
)
select *, (RollingPeopleVaccinated/Population)*100
from PopvsVac
where location like '%United States%';

-- creating view to store data for later visualizations

create view PopvsVac as
select dea.continent, dea.location, dea.date, dea.population, vac.new_vaccinations, SUM(vac.new_vaccinations) over (partition by dea.location order by dea.location, dea.date) as RollingPeopleVaccinated
from coviddeaths dea
join covidvaccinations vac
	on dea.location = vac.location 
	and dea.date = vac.date
where dea.continent not like '';

select*
from popvsvac;









