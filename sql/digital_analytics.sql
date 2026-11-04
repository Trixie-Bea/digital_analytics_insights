SELECT *
FROM digital_projects
LIMIT 5;

--================================================================================
--How are digital projects distributed across countries and implementation status,
--and where are there concentrations of projects that may require
--management attention?
--================================================================================

SELECT
	Country,
	COUNT( CASE WHEN status = 'On Track'Then 1 End) As on_track,
	COUNT( CASE WHEN status = 'At Risk'Then 1 End) As At_risk,
	COUNT( CASE WHEN status = 'Completed'Then 1 End) As Completed,
	COUNT( CASE WHEN status = 'Delayed'Then 1 End) As Delayed,
	COUNT( CASE WHEN status = 'In Progress'Then 1 End) As In_Progress,
	COUNT(DISTINCT project_id) As total_projects
FROM digital_projects
GROUP BY 
	country
ORDER BY 
	country;

--============================================================================
--Can you give me a quick overview of our digital project portfolio? 
--I need to know how many projects we're managing, the total budget allocated,
--total expenditure, total beneficiaries reached, and the overall 
--average planned versus actual progress.”
--=============================================================================

SELECT
	COUNT(DISTINCT project_id) As total_projects,
	ROUND(SUM(budget_usd)/1000000,2) As total_budget_in_millions,
	ROUND(SUM(spent_usd)/1000000,2) As total_expenditure_in_millions,
	ROUND(SUM(beneficiaries)/1000000,2) As total_beneficiaries_in_millions,	
	ROUND(AVG(planned_progress_pct),2) As avg_planned_progress_pct,
	ROUND(AVG(actual_progress_pct),2)As avg_actual_progress_pct
FROM digital_projects;

--=======================================================================================================
--For each project, calculate the percentage of its budget that has been spent and identify any projects
--where expenditure has exceeded the approved budget.
--=======================================================================================================

SELECT
    project_id,
    country,
    status,
    budget_usd,
    spent_usd,
    ROUND(
        spent_usd / NULLIF(budget_usd, 0) * 100, 2
    ) AS budget_utilization_pct,
    spent_usd - budget_usd AS budget_variance_usd,
    CASE
        WHEN spent_usd > budget_usd THEN 'Over Budget'
        ELSE 'Within Budget'
    END AS budget_status
FROM digital_projects
ORDER BY budget_utilization_pct DESC;

--===========================================================================================================
--Which projects are falling behind their implementation plans? Compare planned progress with actual progress 
--and show the projects with the largest negative variance.
--===========================================================================================================
SELECT 
	Project_id,
	country,
	status,
	Planned_progress_pct,
	actual_progress_pct,
	(actual_progress_pct- planned_progress_pct) As progress_variance
FROM digital_projects
ORDER BY progress_variance;

--==============================================================================================================
--Give a country-level picture of implementation? Show the number of projects, 
--average planned progress, average actual progress, average progress variance, and 
--total beneficiaries for each country.
--==============================================================================================================
SELECT 
	country,
	COUNT(Project_id) As total_projects,
	ROUND(AVG(Planned_progress_pct),2)AS avg_planned_progress_pct,
	ROUND(AVG(actual_progress_pct),2)As avg_actual_progress_pct,
	ROUND(AVG(actual_progress_pct - planned_progress_pct),2) As avg_progress_variance,
	ROUND(SUM(beneficiaries)/1000000,2) AS total_beneficiaries_in_millions
FROM digital_projects
GROUP BY country 
ORDER BY total_projects DESC;

--==============================================================================================================
--Can you show how the different digital pillars are performing in terms of project numbers, 
--implementation progress, and expenditure
--==============================================================================================================
SELECT
	digital_pillar,
	COUNT(Project_id) As total_projects,
	ROUND(AVG(Planned_progress_pct),2)AS avg_planned_progress_pct,
	ROUND(AVG(actual_progress_pct),2)As avg_actual_progress_pct,
	ROUND(SUM(budget_usd)/1000000,2) As total_budget_in_millions,
	ROUND(SUM(spent_usd)/1000000,2) As total_expenditure_in_millions
FROM digital_projects
GROUP BY digital_pillar
ORDER BY avg_actual_progress_pct DESC ;

--=================================================================================
--Please identify projects that may require management attention. 
--I'm particularly interested in projects that are significantly 
--behind plan or have spent more than their allocated budget.
--**significantly behind plan as actual progress being 20 or more percentage points
--below planned progress**
--===================================================================================
SELECT 
	Project_id,
	country,
	status,
	Planned_progress_pct,
	actual_progress_pct,
	(actual_progress_pct- planned_progress_pct) As progress_variance,
	ROUND(budget_usd/1000000,2) AS budget_usd_in_millions,
	ROUND(spent_usd/1000000,2) As spent_usd_in_millions,
	ROUND((spent_usd-budget_usd )/1000000,2) As budget_variance_in_millions
FROM digital_projects
WHERE 
	actual_progress_pct <= planned_progress_pct-20
	OR 
	spent_usd > budget_usd
ORDER BY
	progress_variance;
	
	
--===================================================================================
--We're preparing our beneficiary reporting. Can you identify projects 
--where female beneficiaries account for less than 40% of total beneficiaries, and
--give me the country, initiative, total beneficiaries and female beneficiary percentage?
--====================================================================================
SELECT
	project_id,
	country,
	initiative,
	beneficiaries,
	female_beneficiaries_pct
FROM digital_projects
WHERE female_beneficiaries_pct < 40
ORDER BY female_beneficiaries_pct ASC ;

--====================================================================================
--Can you review our completed projects and tell me how much of their allocated
--budgets they've actually utilized? I want to see whether there are completed 
--projects with particularly low budget utilization.
--=====================================================================================

SELECT
    COUNT(*) AS completed_projects,
    ROUND(AVG(spent_usd / NULLIF(budget_usd, 0) * 100), 2)
        AS avg_budget_utilization_pct,
    ROUND(MIN(spent_usd / NULLIF(budget_usd, 0) * 100), 2)
        AS min_budget_utilization_pct,
    ROUND(MAX(spent_usd / NULLIF(budget_usd, 0) * 100), 2)
        AS max_budget_utilization_pct,
    ROUND(SUM(budget_usd) / 1000000, 2)
        AS total_budget_millions,
    ROUND(SUM(spent_usd) / 1000000, 2)
        AS total_spent_millions
FROM digital_projects
WHERE status = 'Completed';

--Identify projects with less than 50% utilizaion

SELECT
    project_id,
    country,
    status,
    budget_usd,
    spent_usd,
    ROUND(
        spent_usd / NULLIF(budget_usd, 0) * 100, 2
    ) AS budget_utilization_pct
FROM digital_projects
WHERE status = 'Completed'
  AND spent_usd / NULLIF(budget_usd, 0) * 100 < 50
ORDER BY budget_utilization_pct ASC;

--==========================================================================================================
--Before we use this dataset for our management report, can you give me a list of records 
--that still have data-quality exceptions? I want to know which projects have invalid date sequences 
--or progress values outside the expected range.
--===========================================================================================================

SELECT
	project_id,
	country,
	status,
	start_date,
	end_date,
	planned_progress_pct,
	actual_progress_pct,
	date_logic_issue,
	progress_logic_issue
FROM digital_projects
WHERE
	date_logic_issue = true
	OR
	progress_logic_issue = true
	;

--============================================================================================================
--Based on the data, give the key findings.
--============================================================================================================

-- 1. Count projects at least 20 percentage points behind plan
SELECT COUNT(*) AS projects_behind_plan
FROM digital_projects
WHERE actual_progress_pct <= planned_progress_pct - 20;

-- 2. Confirm all projects that exceeded their budgets
SELECT
    project_id,
    country,
    budget_usd,
    spent_usd,
    spent_usd - budget_usd AS overspend_usd
FROM digital_projects
WHERE spent_usd > budget_usd;

-- 3. Identify the country with the most delayed projects
SELECT
    country,
    COUNT(*) AS delayed_projects
FROM digital_projects
WHERE status = 'Delayed'
GROUP BY country
ORDER BY delayed_projects DESC, country
LIMIT 1;

-- 4. Count projects with female representation below 40%
SELECT COUNT(*) AS projects_below_40_pct
FROM digital_projects
WHERE female_beneficiaries_pct < 40;


/*Findings;
1. Implementation: 33 projects are at least 20 percentage points behind plan, 
with the largest gap observed in DIG-0101-ZAMBIA.”

2.Financial risk: Financial risk: Project DIG-0064 has exceeded its allocated budget by $75,000, 
with total expenditure of $1,355,126 against an approved budget of $1,280,126.

3.Delivery status: Zambia has the highest number of delayed projects.

4.Beneficiaries Inclusion: 7 projects report female beneficiary representation below 40%.”

5.Management action: Validate anomalous records, investigate material budget and progress exceptions, 
and agree on corrective actions with project teams.

*/
