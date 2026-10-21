**# log

log using peus_pwt_txt, replace name(peus_pwt_txt) text
log using peus_pwt_smcl, replace name(peus_pwt_smcl) smcl

**# 2.1 PWT data

// cd "..."

**## Data

use "pwt1001.dta", clear

egen id = group(country)
xtset id year

describe

/*

Here are the 3-letter ISO country codes for OECD (Organisation for Economic Co-operation and Development) member countries:

1. Australia - AUS  
2. Austria - AUT  
3. Belgium - BEL  
4. Canada - CAN  
5. Chile - CHL  
6. Colombia - COL  
7. Costa Rica - CRI  
8. Czech Republic - CZE  
9. Denmark - DNK  
10. Estonia - EST  
11. Finland - FIN  
12. France - FRA  
13. Germany - DEU  
14. Greece - GRC  
15. Hungary - HUN  
16. Iceland - ISL  
17. Ireland - IRL  
18. Israel - ISR  
19. Italy - ITA  
20. Japan - JPN  
21. Korea (South Korea) - KOR  
22. Latvia - LVA  
23. Lithuania - LTU  
24. Luxembourg - LUX  
25. Mexico - MEX  
26. Netherlands - NLD  
27. New Zealand - NZL  
28. Norway - NOR  
29. Poland - POL  
30. Portugal - PRT  
31. Slovak Republic - SVK  
32. Slovenia - SVN  
33. Spain - ESP  
34. Sweden - SWE  
35. Switzerland - CHE  
36. Türkiye - TUR  
37. United Kingdom - GBR  
38. United States - USA  

*/

**## OECD sample

generate cn_oecd = countrycode == "AUS" | countrycode == "AUT" | countrycode == "BEL" | countrycode == "CAN" | countrycode == "CHL" | countrycode == "COL" | countrycode == "CRI" | countrycode == "CZE" | countrycode == "DNK" | countrycode == "EST" | countrycode == "FIN" | countrycode == "FRA" | countrycode == "DEU" | countrycode == "GRC" | countrycode == "HUN" | countrycode == "ISL" | countrycode == "IRL" | countrycode == "ISR" | countrycode == "ITA" | countrycode == "JPN" | countrycode == "KOR" | countrycode == "LVA" | countrycode == "LTU" | countrycode == "LUX" | countrycode == "MEX" | countrycode == "NLD" | countrycode == "NZL" | countrycode == "NOR" | countrycode == "POL" | countrycode == "PRT" | countrycode == "SVK" | countrycode == "SVN" | countrycode == "ESP" | countrycode == "SWE" | countrycode == "CHE" | countrycode == "TUR" | countrycode == "GBR" | countrycode == "USA"

local oecd AUS AUT BEL CAN CHL COL CRI CZE DNK EST FIN FRA DEU GRC           ///
HUN ISL IRL ISR ITA JPN KOR LVA LTU LUX MEX NLD NZL NOR POL PRT SVK SVN      ///
ESP SWE CHE TUR GBR USA 
gen alt_cn_oecd = strpos("`oecd'", countrycode) > 0

* ege: cheking they are identical 
assert cn_oecd == alt_cn_oecd if cn_oecd != .
assert cn_oecd == alt_cn_oecd if alt_cn_oecd != .
drop alt_cn_oecd

tabulate year if cn_oecd

**## Specifications

describe rgdpo emp cn hc

generate double lnY = log(rgdpo)
generate double lnL = log(emp)
generate double lnK = log(cn)
generate double lnH = log(hc)

generate double lny = lnY - lnL
generate double lnk = lnK - lnL
generate double lnh = lnH - lnL

generate double lnHL = lnH + lnL

global spePWTCD "lnY lnK lnHL"

global spePWTTL "lnY (c.lnK c.lnHL)##(c.lnK c.lnHL)"

generate double half = 0.5
global spePWTTL2 "lnY lnK lnHL c.lnK#c.lnHL c.half#(c.lnK#c.lnK c.lnHL#c.lnHL)"

keep countrycode country cn_oecd year id lnY lnL lnK lnH half lny lnk lnh lnHL 

save "pwt_final.dta", replace    /* Saving dataset with modifications */


**# Cross-Sectional SF models

use "pwt_final.dta", clear         /* Calling dataset with modifications */

global CSyear 2000

**# 3.4 COLS

regress $spePWTTL if cn_oecd & year == $CSyear
predict epsilonTL if e(sample), residual
summarize epsilonTL
generate double tIneff = r(max) - epsilonTL if e(sample)
generate double te_COLS_TL = exp(-tIneff) if e(sample)
histogram te_COLS_TL, normal xtitle("Technical efficiency, COLS")

graph export "figs/te_COLS_CS_PWT_TL.pdf", as(pdf) name("Graph") replace

**# 3.7 ALS

frontier $spePWTCD if cn_oecd & year == $CSyear, distribution(hnormal)
estimates store CD_HN
frontier $spePWTTL if cn_oecd & year == $CSyear, distribution(hnormal)
estimates store TL_HN
frontier $spePWTCD if cn_oecd & year == $CSyear, distribution(exponential)
estimates store CD_Exp
frontier $spePWTTL if cn_oecd & year == $CSyear, distribution(exponential)
estimates store TL_Exp
frontier $spePWTCD if cn_oecd & year == $CSyear, distribution(tnormal) iter(150)
estimates store CD_TN
capture noisily frontier $spePWTTL if cn_oecd & year == $CSyear, distribution(tnormal) iter(150)
estimates store TL_TN

set linesize 125
// set linesize 85


estout CD_HN TL_HN CD_Exp TL_Exp CD_TN TL_TN, ///
 cells(b(star fmt(%9.4f)) p(par)) ///
 stats(ll N, ///
 labels("log-likelihood" "\$N\$") ///
 fmt(%9.6f %9.0f)) ///
 starlevels(* 0.10 ** 0.05 *** 0.01) ///
 varlabels(_cons Constant ) ///
 substitute("_ " "Frontier") ///
 legend label collabels(none) mlabels(none) style(tex) replace
 
estout CD_HN TL_HN CD_Exp TL_Exp CD_TN TL_TN, ///
cells(b(star fmt(%9.4f)) p(par)) ///
stats(ll N, labels("log-likelihood" "\$N\$") fmt(%9.6f %9.0f)) ///
starlevels(* 0.10 ** 0.05 *** 0.01) ///
varlabels(_cons Constant ) ///
substitute("_ " "Frontier") ///
legend label collabels(none) mlabels(none) style(tex) replace
 

**## Discussion
 
display invchi2(3, 0.95)

display chi2tail(3, 1.52)

**## Output Elasticities

**### Density


capture drop elast_TL_K
capture drop elast_TL_HL

quietly frontier $spePWTTL if cn_oecd & year == $CSyear
margins, dydx(lnK lnHL) generate(elast_TL_)
rename elast_TL_1 elast_TL_K
label variable elast_TL_K "Output elasticity of capital"
rename elast_TL_2 elast_TL_HL
label variable elast_TL_HL "Output elasticity of effective labor"
summarize elast_TL_*, detail

summarize elast_TL_K
local mean1 = r(mean)
summarize elast_TL_HL
local mean2 = r(mean)

twoway (kdensity elast_TL_K, lcolor(blue) lpattern(solid) lwidth(medium)) ///
       (kdensity elast_TL_HL, lcolor(red) lpattern(dash) lwidth(medium)), ///
			 xline(`mean1', lcolor(blue) lpattern(solid)) ///
       xline(`mean2', lcolor(red) lpattern(dash)) ///
       legend(label(1 "Capital") label(2 "Effective labor")) ///
       xtitle("Output elasticity")
graph export "figs/elast_TL.pdf", as(pdf) name("Graph") replace


**### Elasticities at means

frontier $spePWTTL if cn_oecd & year == $CSyear
margins, dydx(lnK lnHL) atmeans


// Step 1: Generate original variables
generate Kmean = exp(lnK) if cn_oecd & year == $CSyear
generate HLmean = exp(lnHL) if cn_oecd & year == $CSyear

// Step 2: Compute means and store logs in locals
summarize Kmean, meanonly
local log_mean_K = ln(r(mean))
summarize HLmean, meanonly
local log_mean_HL = ln(r(mean))

// Step 3: Marginal effects at log of means
margins, dydx(lnK lnHL) at(lnK = `log_mean_K' lnHL = `log_mean_HL')


**### Scaling the variables

foreach var of varlist lnY lnK lnHL{
	capture drop tym
	generate tym = exp(`var') if cn_oecd & year == $CSyear
	capture drop `var'_m
	summarize tym
	generate `var'_m = log(tym/r(mean))
	drop tym
}

global spePWTTL_m "lnY_m (c.lnK_m c.lnHL_m)##(c.lnK_m c.lnHL_m) "
frontier $spePWTTL_m if cn_oecd & year == $CSyear


**## RTS

**### CD

frontier $spePWTCD if cn_oecd & year == $CSyear
lincom lnK + lnHL
test lnK + lnHL = 1

**### TL

frontier $spePWTTL if cn_oecd & year == $CSyear
capture drop RTS_CS_PWT_TL
predictnl RTS_CS_PWT_TL = _b[lnK] + _b[lnHL] + ///
	2*_b[c.lnK#c.lnK]*lnK + 2*_b[c.lnHL#c.lnHL]*lnHL + ///
	_b[c.lnK#c.lnHL]*(lnK+lnHL), se(RTS_CS_PWT_TL_se)
label variable RTS_CS_PWT_TL "RTS, translog specification"	

histogram RTS_CS_PWT_TL
graph export "figs/RTS_CS_PWT_TL.pdf", as(pdf) name("Graph") replace

**#### Table

global significance_level = 0.05 // set significance level
global confidence_level = 1 - $significance_level // obtain confidence level
global critical_value = invnorm(1-$significance_level/2) // critical value at the chosen significance level
display "$critical_value"

capture drop CTS_CS_PWT_TL
generate RTS_CS_PWT_TL_lb = RTS_CS_PWT_TL - $critical_value*RTS_CS_PWT_TL_se if e(sample)
generate RTS_CS_PWT_TL_ub = RTS_CS_PWT_TL + $critical_value*RTS_CS_PWT_TL_se if e(sample)
generate CTS_CS_PWT_TL = (RTS_CS_PWT_TL_ub > 1) & ///
	(RTS_CS_PWT_TL_lb < 1) if e(sample)
tabulate CTS_CS_PWT_TL
summarize RTS_CS_PWT_TL_lb RTS_CS_PWT_TL_ub

tabstat RTS_CS_PWT_TL_lb RTS_CS_PWT_TL_ub, ///
	statistics(n min max) format(%10.2fc) columns(statistics)

**# 3.9 MOLS

regress $spePWTTL if cn_oecd & year == $CSyear
generate double epsilonTLsq = epsilonTL^2 if e(sample)
summarize epsilonTLsq if e(sample), meanonly
scalar m2 = r(mean)

generate double epsilonTLcubed = epsilonTL^3 if e(sample)
summarize epsilonTLcubed if e(sample)
scalar m3 = r(mean)
scalar nobs = r(N)

scalar m3t = m3/sqrt(6*m2^3/nobs)
				/* negative skewness, so one-side test */
scalar p_m3t = normal(m3t)

					/* correct 3rd moment to be negative */
scalar m3 = cond(r(sum) < 0, m3, -.0001)

scalar sigmaUsq = (m3/(sqrt(2/_pi)*(1-4/_pi)))^(2/3)
scalar sigmaVsq = m2 - (1-2/_pi)*sigmaUsq
scalar sigmaVsq = cond( sigmaVsq > 0, sigmaVsq, .0001)

scalar mu = sqrt(sigmaUsq*2/_pi)
regress $spePWTTL if cn_oecd & year == $CSyear



scalar list sigmaUsq sigmaVsq mu

**# 3.11 JMLS

frontier $spePWTTL if cn_oecd & year == $CSyear
capture drop tym
predict tym, u
capture drop te_jlms
generate double te_jlms = exp(-tym) // JLMS
label variable te_jlms "Technical efficiency via exp(-E(u|e))"
histogram te_jlms
graph export "figs/te_CS_PWT_TL.pdf", as(pdf) name("Graph") replace

predict te_bc, te // E(exp(-u)|e)

twoway (kdensity te_jlms, lpattern(dash) lwidth(vthick) lcolor(blue)) ///
       (kdensity te_bc, lpattern(solid) lwidth(medthick) lcolor(red)), ///
       legend(label(1 "JLMS, exp(-E(u|e))") label(2 "BC, E(exp(-u)|e)")) ///
       xlabel(, grid) ylabel(, grid) xtitle("Technical efficiency")
graph export "figs/te_CS_PWT_TL.pdf", as(pdf) name("Graph") replace

frontier $spePWTTL if cn_oecd & year == $CSyear

**# 3.13 CI

sfcross $spePWTTL if cn_oecd & year == $CSyear, distribution(hnormal)
predict sfc if e(sample), jlms ci
describe sfc*
browse country sfc* if !missing(sfc)
list country sfc* if !missing(sfc)

tempvar spePWTT_xb spePWTT_res spePWTT_mu spePWTT_sigma ///
		spePWTT_z spePWTT_zu spePWTT_zl
frontier $spePWTTL if cn_oecd & year == $CSyear
predict `spePWTT_xb' if e(sample), xb
generate `spePWTT_res' = lnY - `spePWTT_xb' if e(sample)
local prod = 1 // -1 for the cost function
generate double `spePWTT_mu' = -`prod' * `spePWTT_res' * ///
		e(sigma_u)^2 / (e(sigma_u)^2+e(sigma_v)^2) ///
		if e(sample) // e(sigma_u) and e(sigma_v) come from estimation
generate double `spePWTT_sigma' = e(sigma_u) * e(sigma_v) / ///
		sqrt( e(sigma_u)^2 + e(sigma_v)^2 ) if e(sample)
generate `spePWTT_z'  = `spePWTT_mu'/`spePWTT_sigma'

local alpha 0.05
generate `spePWTT_zu' = invnormal(1 - (1- (`alpha')/2) * normal(`spePWTT_z')  )
generate `spePWTT_zl' = invnormal(1 - ((`alpha')/2) * normal(`spePWTT_z')  )

generate man_LB95 = exp(-`spePWTT_mu' - `spePWTT_zl' * `spePWTT_sigma')
generate man_UB95 = exp(-`spePWTT_mu' - `spePWTT_zu' * `spePWTT_sigma')

list country sfc_* man_* if !missing(sfc)

preserve
drop if missing(sfc)
sort sfc
generate order = 39 - _n
sort order
list country sfc_* man_* in 1/10, divider separator(3)
restore



preserve

* 1) Create an order variable by TE (ascending)
drop if missing(sfc)
sort sfc
generate order = _n

* 2) Build a value label that maps 'order' -> country name
cap label drop country_order
levelsof order, local(ordlist)
foreach i of local ordlist {
    * Get country name for this order
    summarize order if order==`i', meanonly
    local cname = country[ r(min) ]
    label define country_order `i' "`cname'", add
}
label values order country_order

* 3) Plot
local yopts ytitle("Technical efficiency, CI") ///
    ylabel(0(0.1)1, angle(horizontal)) ///
    yscale(range(0 1))

twoway ///
    (rcap sfc_LB95 sfc_UB95 order, lcolor(gs8)) ///
    (scatter sfc order, mcolor(navy) msymbol(circle) msize(med)), ///
    xlabel(1(1)`=_N', valuelabel angle(45) labsize(small)) ///
    xtitle("Country (sorted by technical efficiency)") `yopts' ///
    legend(order(2 "Technical efficiency" 1 "95% CI") pos(6) ring(0)) ///
    title("")
graph export "figs/te_CS_PWT_TL_CI.pdf", as(pdf) name("Graph") replace
		
restore


**# Panel data SF models

use "pwt_final.dta", clear         /* Calling dataset with modifications */


capture drop sample_panel
generate sample_panel = cn_oecd & year >= $CSyear
// Make unbalanced panel data
replace sample_panel = 0 if countrycode == "FRA" & year >= $CSyear & year <= $CSyear + 1
replace sample_panel = 0 if countrycode == "DEU" & year >= $CSyear & year <= $CSyear + 1
replace sample_panel = 0 if countrycode == "NLD" & year >= $CSyear & year <= $CSyear + 2
replace sample_panel = 0 if countrycode == "NZL" & year >= $CSyear & year <= $CSyear + 2
// Make an indicator for a single year (reporting time-invariant efficieincies); in the year $CSyear + 5, we definitely have all 38 countries
generate sample_panel_one_year = cn_oecd & year == $CSyear + 5

**# last year available
capture drop year_last_available
bysort id: egen year_last_available = max(year) if sample_panel

**# Time-Invariant Efficiency

**## 4.1.2 LS

xtreg $spePWTTL if sample_panel, fe


regress $spePWTTL i.id if sample_panel
matrix b = e(b)

capture drop alphas_LS
generate alphas_LS = . // initialize a variable for alphas

levelsof id if sample_panel, local(ids)
display "`ids'"

local sum = 0
local count = 0

foreach j of local ids {
    local coefname = "`j'.id"
    capture confirm matrix b
    if _rc == 0 & colnumb(b, "`coefname'") != . { // proceed only if no error
        local coef = b[1, "`coefname'"]
        replace alphas_LS = `coef' if id == `j' & sample_panel
        local sum = `sum' + `coef'
        local count = `count' + 1
    }
}

local mean = `sum' / `count'
display "Mean of fixed effects: `mean'"

// The fixed effects are corrected by subtracting the mean
replace alphas_LS = alphas_LS - `mean'

**## 4.1.4 FE

xtreg $spePWTTL if sample_panel, fe
capture drop alphas_xtreg
predict alphas_xtreg if e(sample), u // u_i, the fixed error component

// Alternatively use the reghdfe command

reghdfe $spePWTTL if cn_oecd & year >= $CSyear, absorb(id) resid
capture drop alphas_reghdfe
predict double alphas_reghdfe if cn_oecd & year >= $CSyear, d

list alphas_LS alphas_xtreg alphas_reghdfe if cn_oecd & year == $CSyear + 5 // to make sure all OECD countries are included

correlate alphas_LS alphas_xtreg alphas_reghdfe ///
	if cn_oecd & year == $CSyear + 5 // to make sure all OECD countries are included

**### efficiency

egen u_star_LS = max(alphas_LS) if sample_panel
replace u_star_LS = u_star_LS - alphas_LS
generate te_panel_PWT_SS_LS = exp(-u_star_LS)

capture drop u_star_xtreg
egen u_star_xtreg = max(alphas_xtreg) if sample_panel
replace u_star_xtreg = u_star_xtreg - alphas_xtreg
generate te_panel_PWT_SS_xtreg = exp(-u_star_xtreg)

egen u_star_reghdfe = max(alphas_reghdfe) if sample_panel
replace u_star_reghdfe = u_star_reghdfe - alphas_reghdfe
generate te_panel_PWT_SS_reghdfe = exp(-u_star_reghdfe)

summarize te_panel_PWT_SS_LS te_panel_PWT_SS_xtreg te_panel_PWT_SS_reghdfe if cn_oecd & year == $CSyear + 5

twoway (kdensity te_panel_PWT_SS_LS if sample_panel_one_year, lpattern(dot) lwidth(vthick) lcolor(green)) ///
	   (kdensity te_panel_PWT_SS_xtreg if sample_panel_one_year, lpattern(dash) lwidth(medthick) lcolor(blue)) ///
       (kdensity te_panel_PWT_SS_reghdfe if sample_panel_one_year, lpattern(solid) lwidth(thin) lcolor(red)), ///
       legend(label(1 "LS") label(2 "xtreg") label(3 "reghdfe")) ///
       xlabel(, grid) ylabel(, grid) xtitle("Technical efficiency")
graph export "figs/te_panel_PWT_SS.pdf", as(pdf) name("Graph") replace



**## 4.1.6 RE

xtreg $spePWTTL if sample_panel, re
capture drop alphas_RE
predict alphas_RE if e(sample), u // u_i, the random-error component

// Efficiency
egen u_star_RE = max(alphas_RE) if sample_panel
replace u_star_RE = u_star_RE - alphas_RE
generate te_panel_PWT_SS_RE = exp(-u_star_RE)

**### sfpanel

sfpanel $spePWTTL if sample_panel, model(regls)
// Efficiency
predict u_panel_PWT_SS_regls if sample_panel, u
capture drop te_panel_PWT_SS_regls
generate double te_panel_PWT_SS_regls = exp(-u_panel_PWT_SS_regls)

**## 4.1.8 CRE

xtreg $spePWTTL if sample_panel, cre

// Manually
// Step 1: Extract dependent variable
local depvar : word 1 of $spePWTTL

// Step 2: Define raw variables
capture drop lnKsq
generate lnKsq = lnK^2
capture drop lnHLsq
generate lnHLsq = lnHL^2
capture drop lnKlnHL
generate lnKlnHL = lnHL*lnK

local rawvars lnK lnHL lnKsq lnHLsq lnKlnHL

// Step 3: Generate means with suffix _mean
foreach var of local rawvars {
	capture drop `var'_mean
    egen `var'_mean = mean(`var') if sample_panel, by(id)
}

// Step 4: Run the CRE model
xtreg `depvar' (c.lnK c.lnHL)##(c.lnK c.lnHL) ///
               (c.lnK_mean c.lnHL_mean)##(c.lnK_mean c.lnHL_mean) ///
							 if sample_panel, re

// Step 4: Run the CRE model
xtreg `depvar' (c.lnK c.lnHL)##(c.lnK c.lnHL) ///
               lnK_mean lnHL_mean lnKsq_mean lnHLsq_mean lnKlnHL_mean ///
							 if sample_panel, re
							 
capture drop alphas_CRE
predict alphas_CRE if e(sample), u // u_i, the random-error component

// there is no difference
xtreg lnY lnK lnHL if sample_panel, cre
xtreg lnY lnK lnHL lnK_mean lnHL_mean if sample_panel, re

// Efficiency
egen u_star_CRE = max(alphas_CRE) if sample_panel
replace u_star_CRE = u_star_CRE - alphas_CRE
generate te_panel_PWT_SS_CRE = exp(-u_star_CRE)

**## 4.1.10 MLE

xtreg $spePWTTL if sample_panel, mle
capture drop alphas_MLE
predict alphas_MLE if e(sample), u // u_i, the random-error component

// Efficiency
egen u_star_MLE = max(alphas_MLE) if sample_panel
replace u_star_MLE = u_star_MLE - alphas_MLE
generate te_panel_PWT_SS_MLE = exp(-u_star_MLE)

**### sfpanel: Pitt and Lee (1981)

timer on 11
sfpanel $spePWTTL if sample_panel, model(pl81)
timer off 11
timer list
// Efficiency
predict te_panel_PWT_SS_PL if sample_panel, bc

twoway (kdensity te_panel_PWT_SS_regls if sample_panel_one_year, lpattern(dot) lwidth(vthick) lcolor(green)) ///
	   (kdensity te_panel_PWT_SS_CRE if sample_panel_one_year, lpattern(dash) lwidth(medthick) lcolor(blue)) ///
	   (kdensity te_panel_PWT_SS_MLE if sample_panel_one_year, lpattern(shortdash) lwidth(medthick) lcolor(red)) ///
       (kdensity te_panel_PWT_SS_PL if sample_panel_one_year, lpattern(solid) lwidth(thin) lcolor(black)), ///
       legend(label(1 "RE") label(2 "CRE") label(3 "MLE") label(4 "PL")) ///
       xlabel(, grid) ylabel(, grid) xtitle("Technical efficiency")
graph export "figs/te_panel_PWT_SS_RE.pdf", as(pdf) name("Graph") replace


**# Time-Varying Efficiency

**## 4.2.6 CSS (1990)

generate trend = year - $CSyear + 1 // trend = 1 if year == $CSyear
// egen id = group(countrycode) // generate numeric id since string variables may not be used as factor variables

regress $spePWTTL i.id id#(c.trend c.trend#c.trend) if sample_panel
predict y_fitted_with_intercepts, xb

// Obtain variable names not involving intercepts
// First, run a simple regresison
regress $spePWTTL if sample_panel, noconstant
// Create a local macro with all variable names from e(b)
local vars : colnames e(b)

// Display the list to verify
display "`vars'"

capture drop y_fitted_no_intercept
generate double y_fitted_no_intercept = 0 if e(sample)

foreach var of local vars {
    replace y_fitted_no_intercept = y_fitted_no_intercept + _b[`var'] * `var'
}

capture drop alphas
generate double alphas = y_fitted_with_intercepts - y_fitted_no_intercept
summarize alphas

// Step 1: Compute alpha_t = max(alpha_it) within each year, only for sample
egen alpha_t = max(alphas) if e(sample), by(year)

// Step 2: Compute uhat = alpha_t - alpha_it, only for sample
generate uhat = alpha_t - alphas if e(sample)

generate double te_panel_PWT_CSS_FE = exp(-uhat)
label variable te_panel_PWT_CSS_FE "Technical efficiency, CSS model"
summarize te_panel_PWT_CSS_FE

histogram te_panel_PWT_CSS_FE
graph export "figs/te_css_PWT_TL.pdf", as(pdf) name("Graph") replace

twoway (kdensity te_panel_PWT_SS_xtreg if sample_panel_one_year, lpattern(dot) lwidth(vthick) lcolor(green)) ///
	   (kdensity te_panel_PWT_SS_RE if sample_panel_one_year, lpattern(dash) lwidth(medthick) lcolor(blue)) ///
	   (kdensity te_panel_PWT_SS_CRE if sample_panel_one_year, lpattern(shortdash) lwidth(medthick) lcolor(red)) ///
       (kdensity te_panel_PWT_CSS_FE, lpattern(solid) lwidth(thin) lcolor(black)), ///
       legend(label(1 "FE") label(2 "RE") label(3 "CRE") label(4 "CSS90")) ///
       xlabel(, grid) ylabel(, grid) xtitle("Technical efficiency")
graph export "figs/te_panel_PWT_SS_CSS.pdf", as(pdf) name("Graph") replace


// net install xtsf1g2g, from("https://raw.githubusercontent.com/OlegBadunenko/sf-panel-1st-2nd-gen/main")

**## 4.3.2 Kumbhakar (1990) 

timer clear 13
timer on 13
xtsf2g $spePWTTL if sample_panel, model(K1990)
timer off 13
timer list
// Efficiency
predict te_panel_PWT_K1990 if e(sample), te_bc

**## 4.3.4 Battese and Coelli (1992)

timer clear 14
timer on 14
xtsf2g $spePWTTL if sample_panel, model(BC1992)
timer off 14
timer list

// Efficiency
predict te_panel_PWT_BC1992 if e(sample), te_bc

**## 4.3.6 Lee and Schmidt (1993)

// predict after sfpanel in fels does not work with "if", 
// so need to be creative

// Step 1: Preserve the original dataset
preserve
// Step 2: Drop observations (keep only those we need)
drop if !sample_panel
// Step 3: Perform estimation
timer clear 15
timer on 15
sfpanel $spePWTTL if sample_panel, model(fels) // "if sample_panel" is not needed, but kept for consistence with the rest
timer off 15
timer list
// and obtain efficiency
predict TE_panel_PWT_LS_fels if sample_panel, jlms // "if sample_panel" is not needed, but kept for consistence with the rest
// Step 4: Save the temporary dataset
tempfile tymch_fajl
save `tymch_fajl'
// Step 5: Restore the original dataset
restore
// Step 6: Merge using both id and year
merge 1:1 id year using `tymch_fajl'
// Step 7: Clean up
drop _merge
// Step 8: Erase the temporary file
erase `tymch_fajl'


twoway (kdensity te_panel_PWT_K1990, lpattern(dot) lwidth(vthick) lcolor(green)) ///
	   (kdensity te_panel_PWT_BC1992, lpattern(dash) lwidth(medthick) lcolor(blue)) ///
	   (kdensity TE_panel_PWT_LS_fels, lpattern(shortdash) lwidth(medthick) lcolor(red)) ///
       (kdensity te_panel_PWT_CSS_FE, lpattern(solid) lwidth(thin) lcolor(black)), ///
       legend(label(1 "K1990") label(2 "BC1992") label(3 "LS93") label(4 "CSS90")) ///
       xlabel(, grid) ylabel(, grid) xtitle("Technical efficiency")
graph export "figs/te_panel_PWT_K1990_BC1992_LS93_CSS90.pdf", as(pdf) name("Graph") replace

**# Advanced SF models

**## 5.1.1 TFE

timer clear 16
timer on 16
sfpanel $spePWTTL if sample_panel, model(tfe) iterate(300)
timer off 16
timer list

// Efficiency
predict TE_panel_PWT_TFE if sample_panel, jlms

//## 5.1.2 TRE

//### halton, NR, R = 50

sfpanel $spePWTTL if sample_panel, model(tre) simtype(halton) nsimulations(50) base(2) difficult iterate(50) technique(nr)

//### halton, NR, R = 200

sfpanel $spePWTTL if sample_panel, model(tre) simtype(halton) nsimulations(200) base(2) difficult iterate(300) technique(nr)

// does not work

// try BFGS optimization technique

//### halton, BFGS, R = 200

timer clear 17
timer on 17
sfpanel $spePWTTL if sample_panel, model(tre) simtype(halton) nsimulations(200) base(2) difficult iterate(100) technique(bfgs) distribution(hnormal)
timer off 17
timer list

//### halton, NR, with starting values

// try supplying initial values to NR from BFGS

matrix init_b = e(b)
matrix list init_b

// To obtain starting values

local colnames : colnames init_b
display "`colnames'"

// In Stata matrices, you need to use the equation names (rownames/colnames with equation prefixes) or use coleq() to get the equation names.

// Get equation names
local coleq : coleq init_b
display "Equation names: `coleq'"

// Find columns where equation name is "Frontier"
local first_col = .
local last_col = .
local col_num = 1
foreach eq of local coleq {
    if "`eq'" == "Frontier" {
        if `first_col' == . local first_col = `col_num'
        local last_col = `col_num'
    }
    local col_num = `col_num' + 1
}

display "First Frontier column: `first_col'"
display "Last Frontier column: `last_col'"

matrix frontier_part = init_b[1..., `first_col'..`last_col']
matrix list frontier_part

// log of the inefficiency variance
matrix Usigma_part = init_b[1..., 7]
matrix list Usigma_part
// log of the noise variance
matrix Vsigma_part = init_b[1..., 8]
matrix list Vsigma_part

// run the regression

sfpanel $spePWTTL if sample_panel, model(tre) simtype(halton) nsimulations(200) base(2) difficult iterate(50) technique(nr) distribution(hnormal) svfrontier(frontier_part) svusigma(Usigma_part) svvsigma(Vsigma_part)

// does not work

// try uniform

//### runiform, NR, R = 50

timer clear 18
timer on 18
sfpanel $spePWTTL if sample_panel, model(tre) simtype(runiform) nsimulations(50) difficult iterate(150) difficult technique(nr)
timer off 18
timer list

//### runiform, NR, R = 250

// increase R for better integral approximation

timer clear 18
timer on 18
sfpanel $spePWTTL if sample_panel, model(tre) simtype(runiform) nsimulations(250) difficult iterate(300) technique(bfgs)
timer off 18
timer list

//### defaults

timer clear 18
timer on 18
sfpanel $spePWTTL if sample_panel, model(tre)
timer off 18
timer list

//### genhalton, NR, R = 50

timer clear 18
timer on 18
sfpanel $spePWTTL if sample_panel, model(tre) simtype(genhalton) nsimulations(50) difficult iterate(300) technique(nr) distribution(hnormal)
timer off 18
timer list

//### CD, halton, NR, R = 250

timer clear 20
timer on 20
sfpanel $spePWTCD if sample_panel, model(tre) simtype(halton) nsimulations(250) iterate(102) technique(nr) distribution(hnormal) nthreads(10)
timer off 20
timer list 20

// It took much longer but the result is consistent with when nsimulations(200) option is used

// Efficiency
capture drop TE_panel_PWT_TRE
predict TE_panel_PWT_TRE if sample_panel, jlms

twoway (kdensity TE_panel_PWT_TFE, lpattern(shortdash) lwidth(medthick) lcolor(red)) ///
	   (kdensity TE_panel_PWT_TRE, lpattern(dash) lwidth(medthick) lcolor(blue)), ///
       legend(label(1 "TFE") label(2 "TRE")) ///
       xlabel(, grid) ylabel(, grid) xtitle("Technical efficiency")
graph export "figs/te_panel_PWT_TFE_TRE.pdf", as(pdf) name("Graph") replace


preserve

collapse (min) TE_panel_PWT_TRE, by(country)
gsort TE_panel_PWT_TRE  // ascending sort

list country TE_panel_PWT_TRE in 1/10, sep(0)

restore

tabstat TE_panel_PWT_TRE if country == "Ireland", stat(min p10 p25 p50 p75 p90 max) format(%5.2f)
tabstat TE_panel_PWT_TRE if country == "Norway", stat(min p10 p25 p50 p75 p90 max) format(%5.2f)

sort TE_panel_PWT_TRE
list country year TE_panel_PWT_TRE in 1/10, sep(0)

sort id year




//## 5.2.1 Park, Sickles and Simar Models

//### PSS Type I

timer clear 22
timer on 22
xtsf3gpss1 $spePWTTL if sample_panel, gr0(0.1) gr1(1.0) gri(0.1) reps(99)
timer off 22
timer list

predict te_panel_PWT_PSS1 if e(sample), te

browse id year te_panel_PWT_PSS1 if sample_panel

// Since this is a time-invariant efficiency, keep values only in the last available observation

capture drop te_panel_PWT_PSS1_last_year
generate te_panel_PWT_PSS1_last_year = te_panel_PWT_PSS1 if year == year_last_available & sample_panel

histogram te_panel_PWT_PSS1_last_year

//###  PSS Type II

timer clear 23
timer on 23
xtsf3gpss2 $spePWTTL if sample_panel, gr0(0.1) gr1(1.0) gri(0.01) reps(99)
timer off 23
timer list

capture drop te_panel_PWT_PSS2*
predict te_panel_PWT_PSS2 if e(sample), te

browse id year te_panel_PWT_PSS2* if sample_panel
describe te_panel_PWT_PSS2*

// Since this is a time-invariant efficiency, keep values only in the last available observation

capture drop te_panel_PWT_PSS2_W_last_year
generate te_panel_PWT_PSS2_W_last_year = te_panel_PWT_PSS2_W if year == year_last_available & sample_panel

histogram te_panel_PWT_PSS2_W_last_year

capture drop te_panel_PWT_PSS2_G_last_year
generate te_panel_PWT_PSS2_G_last_year = te_panel_PWT_PSS2_G if year == year_last_available & sample_panel

histogram te_panel_PWT_PSS2_G_last_year

//###  PSS Type III

timer clear 24
timer on 24
xtsf3gpss3 $spePWTTL if sample_panel, gr0(0.1) gr1(1.0) gri(0.01) reps(99)
timer off 24
timer list

predict te_panel_PWT_PSS3 if e(sample), te

browse id year te_panel_PWT_PSS3 if sample_panel

// Since this is a time-invariant efficiency, keep values only in the last available observation

capture drop te_panel_PWT_PSS3_last_year
generate te_panel_PWT_PSS3_last_year = te_panel_PWT_PSS3 if year == year_last_available & sample_panel

histogram te_panel_PWT_PSS3_last_year

twoway (kdensity te_panel_PWT_PSS1_last_year, lpattern(dot) lwidth(vthick) lcolor(green)) ///
	   (kdensity te_panel_PWT_PSS2_W_last_year, lpattern(dash) lwidth(medthick) lcolor(blue)) ///
	   (kdensity te_panel_PWT_PSS2_G_last_year, lpattern(shortdash) lwidth(medthick) lcolor(red)) ///
       (kdensity te_panel_PWT_PSS3_last_year, lpattern(solid) lwidth(thin) lcolor(black)), ///
       legend(label(1 "PSS1") label(2 "PSS2_W") label(3 "PSS2_G") label(4 "PSS3")) ///
       xlabel(, grid) ylabel(, grid) xtitle("Technical efficiency")
graph export "figs/te_panel_PWT_PSSs.pdf", as(pdf) name("Graph") replace

timer list
// for comparison `99' measures time for
//  xtfrontier $spePWTTL if sample_panel, tvd
timer list 99

//## 5.3.1 The Kneip, Sickles and Song model

// KSS estimator when optimal the smoothing parameter is chosen on the [0.1 1.0] grid with interval of 0.001. In each grid point, dimentions 3 through 7 are checked.

timer clear 21
timer on 21
xtsf3gkss $spePWTTL if sample_panel, gr0(0.1) gr1(1.0) gri(0.001) li(3) ls(7) imean tmean level(95) cformat(%9.4f)
timer off 21
timer list

predict te_panel_PWT_KSS if e(sample), te

browse id year te_panel_PWT_KSS if sample_panel

histogram te_panel_PWT_KSS

twoway (kdensity te_panel_PWT_KSS, lpattern(dot) lwidth(vthick) lcolor(green)) ///
	   (kdensity te_panel_PWT_PSS1_last_year, lpattern(dash) lwidth(medthick) lcolor(blue)) ///
	   (kdensity te_panel_PWT_PSS2_W_last_year, lpattern(dash) lwidth(medthick) lcolor(green)) ///
	   (kdensity te_panel_PWT_PSS2_G_last_year, lpattern(shortdash) lwidth(medthick) lcolor(red)) ///
       (kdensity te_panel_PWT_PSS3_last_year, lpattern(solid) lwidth(thin) lcolor(black)), ///
       legend(label(1 "KSS") label(2 "PSS1") label(3 "PSS2_W") label(4 "PSS2_G") label(5 "PSS3")) ///
       xlabel(, grid) ylabel(, grid) xtitle("Technical efficiency")
graph export "figs/te_panel_PWT_KSS_PSSs.pdf", as(pdf) name("Graph") replace


**## 5.4.3 The 4-component model


// do "~/research/coding/stata/xtsf/xtsf_assist.do"

**### TL

timer clear 41
timer on 41
xtsf $spePWTTL if sample_panel, simtype(halton) haltonbase(3) basesapart(2) technique(nr) r(199) iter(102) model(gtreMSLE) initscaf(0.99) initscau(0.5) initscav(0.25)
timer off 41
timer list 41
display r(t41)/60 " minutes"

timer clear 42
timer on 42
xtsf $spePWTTL if sample_panel, simtype(halton) haltonbase(3) basesapart(2) technique(nr) r(199) iter(1020) model(gtreMSLE) initscaf(0.99) initscau(0.25) initscav(0.25)
timer off 42
timer list 42
display r(t42)/60 " minutes"

xtsf $spePWTTL if sample_panel, simtype(halton) haltonbase(2) basesapart(1) nthreads(10) technique(nr) r(199) iter(102) model(gtreMSLE)

xtsf $spePWTTL if sample_panel, simtype(halton) haltonbase(2) basesapart(1) nthreads(10) technique(bfgs) r(199) iter(102) model(gtreMSLE)
// error: "could not calculate numerical derivatives -- flat or discontinuous region encountered"

xtsf $spePWTTL if sample_panel, simtype(halton) haltonbase(2) basesapart(1) nthreads(10) technique(nr) r(49) iter(20) model(gtreMSLE) 
matrix init_theta = e(b)

xtsf $spePWTTL if sample_panel, simtype(halton) haltonbase(2) basesapart(1) nthreads(10) technique(nr) r(199) iter(100) model(gtreMSLE) from(init_theta)

timer list

**### CD

timer clear 40
timer on 40
xtsf $spePWTCD if sample_panel, simtype(halton) technique(nr) r(250) iter(102) model(gtreMSLE) nthreads(10)
timer off 40
timer list 40
display r(t40)/60 " minutes"

capture drop te_pers
predict te_pers if sample_panel, persistent

capture drop te_pers_initial
generate te_pers_initial = te_pers if year == year_last_available & sample_panel

summarize te_pers_initial

capture drop te_tran
predict te_tran if sample_panel, transient
capture drop fitted
predict fitted if sample_panel

summarize te_pers te_tran

hist te_pers_initial
hist te_tran

twoway (kdensity te_tran, lpattern(shortdash) lwidth(medthick) lcolor(red)) ///
	   (kdensity TE_panel_PWT_TRE, lpattern(dash) lwidth(medthick) lcolor(blue)), ///
       legend(label(1 "GTRE, transient") label(2 "TRE")) ///
       xlabel(, grid) ylabel(, grid) xtitle("Technical efficiency")
graph export "figs/te_panel_PWT_GTRE_TRE.pdf", as(pdf) name("Graph") replace

* 10 lowest transient

preserve

collapse (min) te_tran, by(country)
gsort te_tran  // ascending sort

list country te_tran in 1/10, sep(0)

restore

* 10 lowest persistent

preserve

collapse (min) te_pers, by(country)
gsort te_pers  // ascending sort

list country te_pers in 1/38, sep(0)

preserve

* 10 lowest overall

capture drop te_over
generate te_over = te_pers * te_tran if sample_panel

log close peus_pwt_txt
log close peus_pwt_smcl

// exit, clear

