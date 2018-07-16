clear all


set matsize 4000


global home "/Users/max/Dropbox/research/PolicyDecisions/Applications/2701_RAND_data"  	

 
use ${home}/AnalysisData/person_years.dta

*dropping mixed plans
drop if rand_plan_group3==1
drop if rand_plan_group5==1


	quietly generate fam_start_month_string = string(fam_start_month)
	quietly generate site_string = string(site)
	quietly egen fam_start_month_site_string = concat(fam_start_month_string site_string)
	quietly encode(fam_start_month_site_string), generate(fam_start_month_site)
	quietly	drop fam_start_month_site_string fam_start_month_string site_string

	quietly tabulate fam_start_month_site, generate(fam_start_month_site)
	quietly tabulate fam_start_year, generate(cal_year)
	foreach var of varlist fam_start_month_site* cal_year* {
		quietly egen mean_`var' = mean(`var')
		quietly generate demeaned_`var' = `var' - mean_`var'
		quietly drop mean_`var'
	}
	quietly drop demeaned_fam_start_month_site


****************************************
*output for baseline spec (like row 2 in tables)




*x= coinsurance rate under different plans
generate x = .25 * rand_plan_group2 + .5 * rand_plan_group4 + .95 * rand_plan_group6


local Y "spending_infl"
local X "x"
local W "fam_start_month_site fam_start_year"
 

outsheet `Y' using ${home}/Y.csv, nonames nolabel comma replace
outsheet `X' using ${home}/X.csv, nonames nolabel comma replace
outsheet `W' using ${home}/W.csv, nonames nolabel comma replace



**************************************
*now for the inclusion of covariates


* Demean covariates	local covs "hosp hosp_missing havemd havemd_missing mdexam mdexam_missing mdvis mdvis_missing log_mdexp log_mdexp_missing any_d_routine any_d_routine_missing any_d_special any_d_special_missing female age_6to17 age_18to44 age_45plus white white_missing hs_grad more_than_hs educ_missing city_backgrnd suburb_backgrnd town_backgrnd backgrnd_missing log_fam_income log_fam_income_sq fam_income_missing any_working_fam any_working_fam_missing insured insured_missing workins workins_missing privins privins_missing publins publins_missing exc_health good_health health_status_missing has_pain has_pain_missing has_worry has_worry_missing"	foreach cov of local covs {		replace `cov' = -1 if `cov' == .		egen mean_`cov' = mean(`cov')		replace `cov' = `cov' - mean_`cov'		drop mean_`cov'	}	 	
	
	
	_rmcollright demeaned_fam_start_month_site* demeaned_cal_year* `covs'
	return list
	di "`r(dropped)'" 
	di "`r(varlist)'" 
		local Wfull ="`r(varlist)'" 
	
	outsheet demeaned_fam_start_month_site1 demeaned_fam_start_month_site2 demeaned_fam_start_month_site3 demeaned_fam_start_month_site4 demeaned_fam_start_month_site5 demeaned_fam_start_month_site6 demeaned_fam_start_month_site7 demeaned_fam_start_month_site8 demeaned_fam_start_month_site9 demeaned_fam_start_month_site10 demeaned_fam_start_month_site11 demeaned_fam_start_month_site12 demeaned_fam_start_month_site13 demeaned_fam_start_month_site14 demeaned_fam_start_month_site15 demeaned_fam_start_month_site16 demeaned_fam_start_month_site17 demeaned_fam_start_month_site18 demeaned_fam_start_month_site19 demeaned_fam_start_month_site20 demeaned_fam_start_month_site21 demeaned_fam_start_month_site22 demeaned_fam_start_month_site23 demeaned_fam_start_month_site24 demeaned_fam_start_month_site25 demeaned_fam_start_month_site26 demeaned_fam_start_month_site27 demeaned_fam_start_month_site28 demeaned_cal_year1 demeaned_cal_year2 demeaned_cal_year3 demeaned_cal_year4 demeaned_cal_year5 demeaned_cal_year6 demeaned_cal_year7 hosp hosp_missing havemd havemd_missing mdexam mdexam_missing mdvis mdvis_missing log_mdexp log_mdexp_missing any_d_routine any_d_routine_missing any_d_special female age_6to17 age_18to44 age_45plus white white_missing hs_grad more_than_hs educ_missing city_backgrnd suburb_backgrnd town_backgrnd backgrnd_missing log_fam_income log_fam_income_sq fam_income_missing any_working_fam any_working_fam_missing insured insured_missing workins workins_missing privins privins_missing publins publins_missing exc_health good_health health_status_missing has_pain has_pain_missing has_worry has_worry_missing using ${home}/Wfull.csv, nonames nolabel comma replace



************************************
*generate reference tables
* Demean covariates	local covs "hosp hosp_missing havemd havemd_missing mdexam mdexam_missing mdvis mdvis_missing log_mdexp log_mdexp_missing any_d_routine any_d_routine_missing any_d_special any_d_special_missing female age_6to17 age_18to44 age_45plus white white_missing hs_grad more_than_hs educ_missing city_backgrnd suburb_backgrnd town_backgrnd backgrnd_missing log_fam_income log_fam_income_sq fam_income_missing any_working_fam any_working_fam_missing insured insured_missing workins workins_missing privins privins_missing publins publins_missing exc_health good_health health_status_missing has_pain has_pain_missing has_worry has_worry_missing"	foreach cov of local covs {		replace `cov' = -1 if `cov' == .		egen mean_`cov' = mean(`cov')		replace `cov' = `cov' - mean_`cov'		drop mean_`cov'	}		_rmcollright   rand_plan_group2 rand_plan_group4 rand_plan_group6 demeaned_fam_start_month_site* demeaned_cal_year* 	local rhs1 `r(varlist)'	_rmcollright   rand_plan_group2 rand_plan_group4 rand_plan_group6 demeaned_fam_start_month_site* demeaned_cal_year* `covs'	local rhs2 `r(varlist)' 

eststo clear

 eststo: regress any_spending rand_plan_group1 `rhs1', noconstant cluster(ifamily)   
 eststo: regress spending_infl rand_plan_group1 `rhs1', noconstant cluster(ifamily)
 eststo: regress any_spending rand_plan_group1 `rhs2', noconstant cluster(ifamily)
 eststo: regress spending_infl rand_plan_group1 `rhs2', noconstant cluster(ifamily)
 
 esttab using ${home}/`tables'/ReplicaTables.csv, keep(rand_plan_group1 rand_plan_group2 rand_plan_group4 rand_plan_group6) replace se nostar	




  
