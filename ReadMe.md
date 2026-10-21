The replication package contains the following files. 

# Codes

* One for replicating the the `PWT` data study (`2share_pwt.do`). 
* The other one is for replicating the the `US Bank` data study (`2share_banking.do`). 

# Data

The first one uses the `pwt1001.dta` data, which is also available at https://www.rug.nl/ggdc/productivity/pwt/pwt-releases/pwt1001. 

The second one uses the `ffiec_excerpt.dta` data file.

# The user-written commands

The above do-files use user-written commands

## sfpanel

sfpanel (Belotti et al., 2013, stata-journal), which can be installed by typing in Stata

net sj 15-4 st0315_2
net install st0315_2

## xtsf1g, xtsf2g

(https://olegbadunenko.github.io/sf-panel-1st-2nd-gen/)

can be installed by typing

github install OlegBadunenko/sf-panel-1st-2nd-gen

## xtsf3gpss1, xtsf3gpss2, xtsf3gpss3, and xtsf3gkss

(https://olegbadunenko.github.io/sf-panel-3rd-gen/)

can be installed by typing

github install OlegBadunenko/sf-panel-3rd-gen

## xtsf

(https://olegbadunenko.github.io/sf-panel/)

can be installed by typing

github install OlegBadunenko/sf-panel

The `xtsf` command uses the C-compiled plugin and is available for Linux, Windows and Mac (both Arc and Intel). It used multiple processors (all on GitHub).

