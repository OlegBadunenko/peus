**# log

log using peus_banking_txt, replace name(peus_banking_txt) text
log using peus_banking_smcl, replace name(peus_banking_smcl) smcl


**# 2.2 Banking data

// cd "..."

use "ffiec_excerpt.dta", clear

tabulate year if year > 2009

generate double lnY1 = log(Y1)
generate double lnY2 = log(Y2)
generate double lnX1 = -log(X1)
generate double lnX2 = log(X2/X1)
generate double lnX3 = log(X3/X1)
generate double lnX4 = log(X4/X1)

generate double lnW2 = log(W2/W1)
generate double lnW3 = log(W3/W1)
generate double lnW4 = log(W4/W1)

global speBankTL "lnX1 (c.lnY1 c.lnY2 c.lnX2 c.lnX3 c.lnX4)##(c.lnY1 c.lnY2 c.lnX2 c.lnX3 c.lnX4)"

global significance_level = 0.05 // set significance level
global confidence_level = 1 - $significance_level // obtain confidence level
global critical_value = invnorm(1-$significance_level/2) // critical value at the chosen significance level
display "$critical_value"

save "ffiec_excerpt_final.dta", replace  /* Saving dataset with modifications */ 


**# 3.7 ALS

use "ffiec_excerpt_final.dta", clear   /* Calling dataset with modifications */


capture frontier $speBankTL if year == 2014, distribution(exponential)

frontier $speBankTL in 1/500, distribution(exponential)
frontier $speBankTL if year == 2014, distribution(exponential) from(e(b))

**## Interpretation of Elasticities


capture drop elast*
timer on 1
margins, dydx(lnY1 lnY2 lnX2 lnX3 lnX4) generate(elast_)
timer off 1
generate double elast_Y1 = -elast_1
generate double elast_Y2 = -elast_2
clonevar elast_X2 = elast_3
clonevar elast_X3 = elast_4
clonevar elast_X4 = elast_5
generate double elast_X1 = 1 - elast_X2 - elast_X3 - elast_X4
// generate double elast_X1 = 1 - elast_X2 - elast_X3
summarize elast_Y* elast_X*

capture drop rts
generate double rts = 1/(elast_Y1+elast_Y2)
summarize elast_Y* elast_X* rts

tabstat elast_Y* elast_X* rts, format(%10.3fc)  ///
	statistics(n min p10 p50 p90 max) columns(statistics)
	
	

**## RTS manually

* Extract coefficient names from e(b)
matrix b = e(b)
local allvars : colnames b

* Initialize locals
local dlnY1
local dlnY2

foreach var of local allvars {
    * lnY1 terms
    if strpos("`var'", "lnY1") {
        if strpos("`var'", "#") {
            local left = substr("`var'", 1, strpos("`var'", "#") - 1)
            local right = substr("`var'", strpos("`var'", "#") + 1, .)

            if "`left'" == "c.lnY1" & "`right'" == "c.lnY1" {
                local dlnY1 `dlnY1' + 2*_b[`var']*lnY1
            }
            else if "`left'" == "c.lnY1" {
                local other = subinstr("`right'", "c.", "", .)
                local dlnY1 `dlnY1' + _b[`var']*`other'
            }
            else if "`right'" == "c.lnY1" {
                local other = subinstr("`left'", "c.", "", .)
                local dlnY1 `dlnY1' + _b[`var']*`other'
            }
        }
        else if "`var'" == "lnY1" {
            local dlnY1 `dlnY1' + _b[`var']
        }
    }

    * lnY2 terms
    if strpos("`var'", "lnY2") {
        if strpos("`var'", "#") {
            local left = substr("`var'", 1, strpos("`var'", "#") - 1)
            local right = substr("`var'", strpos("`var'", "#") + 1, .)

            if "`left'" == "c.lnY2" & "`right'" == "c.lnY2" {
                local dlnY2 `dlnY2' + 2*_b[`var']*lnY2
            }
            else if "`left'" == "c.lnY2" {
                local other = subinstr("`right'", "c.", "", .)
                local dlnY2 `dlnY2' + _b[`var']*`other'
            }
            else if "`right'" == "c.lnY2" {
                local other = subinstr("`left'", "c.", "", .)
                local dlnY2 `dlnY2' + _b[`var']*`other'
            }
        }
        else if "`var'" == "lnY2" {
            local dlnY2 `dlnY2' + _b[`var']
        }
    }
}


* Display the results
display "Marginal effect of lnY1: `dlnY1'"
display "Marginal effect of lnY2: `dlnY2'"


* Temporarily store the expression
local temp1 = "`dlnY1'"
local temp2 = "`dlnY2'"

* Remove the first "+ " manually
if substr("`temp1'", 1, 2) == "+ " {
    local dlnY1 = substr("`temp1'", 3, .)
}
if substr("`temp2'", 1, 2) == "+ " {
    local dlnY2 = substr("`temp2'", 3, .)
}

* Display the results
display "Marginal effect of lnY1: `dlnY1'"
display "Marginal effect of lnY2: `dlnY2'"


generate elast_Y1_manual = -(`dlnY1') if e(sample)
generate elast_Y2_manual = -(`dlnY2') if e(sample)

local RTS_expr = "- 1 / ((`dlnY1') + (`dlnY2'))"

predictnl rts_manual = `RTS_expr' if e(sample), se(rts_se)

summarize elast_Y1_manual elast_Y1 elast_Y2_manual elast_Y2 rts_manual rts

generate rts_lb = rts - ${critical_value} * rts_se  if e(sample)
generate rts_ub = rts + ${critical_value} * rts_se if e(sample)
generate scale = "" if e(sample)

replace scale = "Economies of Scale" if rts_lb > 1 & e(sample)
replace scale = "Diseconomies of Scale" if rts_ub < 1 & e(sample)
replace scale = "Optimal Scale" if rts_lb < 1 & rts_ub > 1 & e(sample)

tabulate scale

erase "ffiec_excerpt_final.dta"

log close peus_banking_txt
log close peus_banking_smcl

*
