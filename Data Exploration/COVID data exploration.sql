/*

Thes two datasets are covid deaths and covid vaccinations taken from the COVID website ourworldindata.com

*/

select Location, date, total_cases, new_cases, population
from dbo.death
order by 1,2

 --Total cases vs total deaths : How did the death rate changed as time passed

select Location, date, total_cases, total_deaths, ROUND(ISNULL((CAST(total_deaths AS float) / CAST(total_cases as float))*100,0),1) as deathpercentage
from dbo.death
order by 1,2

--Total cases vs population : How much populating had covid on that day

select Location, date, total_cases, population, ROUND(ISNULL((CAST(total_cases AS float) / CAST(population as float))*100,0),2) as perc_pop_infected
from dbo.death
where Location like '%states%'
order by 1,2

-- What countries have highest infection rate?

select Location, max(total_cases) as highest_inf_count, population, max(ROUND(ISNULL((CAST(total_cases AS float) / CAST(population as float))*100,0),2)) as perc_pop_infected
from dbo.death
--where Location like '%states%'
group by Location,population
order by perc_pop_infected desc

/******** Which countries had highest death rate out of their population?********/

select Location, max(total_cases) as highest_inf_count, max(total_deaths) as highest_deaths, max(cast(total_deaths as float))/max(cast(total_cases as float)) as death_percentage
from dbo.death
--where Location like '%states%'
where continent is not NULL
group by Location
order by highest_deaths desc

/********  showing continents by highest death counts  ********/

select continent, max(total_cases) as highest_inf_count, max(total_deaths) as highest_deaths, max(cast(total_deaths as float))/max(cast(total_cases as float)) as death_percentage
from dbo.death
--where Location like '%states%'
where continent is not NULL
group by continent
order by highest_deaths desc

/********  global numbers by date  ********/
select date, sum(new_cases) as total_cases, sum(new_deaths) as total_deaths, case when sum(new_cases) = 0 then null else ISNULL(sum(new_deaths)/ sum(cast (new_cases as float)),0)*100 end as death_precentage

from dbo.death
group by date
order by 1

--
/************ Vaccinations per population***********/

With popvsvacc(continent,location, date, population, new_vaccinations,rolling_vaccinated ) as

(
select A.continent, A.[location], A.date, A.population, B.new_vaccinations, 
        sum(B.new_vaccinations) over(partition by A.location order by A.location, A.date) as rolling_vaccinated
from dbo.death A join dbo.vacc B on A.[location] = B.[location] and A.[date] = B.[date]
where A.continent is not NULL


)
select *, (rolling_vaccinated/cast(population as float))*100 as rolling_percentage_vaccination from popvsvacc


/************ USING temp_table***********/
drop table if exists #percentpopvaccinated
create table #percentpopvaccinated(
continent varchar(255),
location varchar(255),
date datetime,
population NUMERIC,
new_vaccinations NUMERIC,
rolling_vaccinated NUMERIC
)
INSERT INTO #percentpopvaccinated
select A.continent, A.[location], A.date, A.population, B.new_vaccinations, 
        sum(B.new_vaccinations) over(partition by A.location order by A.location, A.date) as rolling_vaccinated
from dbo.death A join dbo.vacc B on A.[location] = B.[location] and A.[date] = B.[date]
where A.continent is not NULL

select * from #percentpopvaccinated;


/***** Using this as a view *******/

create View percentpopvaccinated as 
select A.continent, A.[location], A.date, A.population, B.new_vaccinations, 
        sum(B.new_vaccinations) over(partition by A.location order by A.location, A.date) as rolling_vaccinated
from dbo.death A join dbo.vacc B on A.[location] = B.[location] and A.[date] = B.[date]
where A.continent is not NULL

select top 5 * from percentpopvaccinated