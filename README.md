
<!-- README.md is generated from README.Rmd. Please edit that file -->

# planThis <img src="logo.png" align="right" width="120" />

<!-- badges: start -->

<!-- badges: end -->

The goal of planThis is to simplify time keeping in the EA. It uses
categorised outlook appointments to create time cards weighted against
free time and daily hours. Outputs are suitable for Oracle
implementation.

## Installation

You can install the development version of planThis from
[GitHub](https://github.com/) with:

``` r
# install.packages("devtools")
devtools::install_github("JonPayneEA/planThis")
```

## Example

This is a basic example which shows you how to use the tool. It requires
three documents for use;

  - A daily hours spreadsheet (*.xlsx*)  
  - Categories data (*.csv*)  
  - An exported outlook calendar (*.csv*)

### Daily hours

The daily hours needs your start time, end time and lunch hours.

Normal work days are set to `Standard`, with this 7.4 hours of work are
expected. A running total of flexi hours is calculated.

Additional options include;  
\- `Weekend` (*0 hrs*)  
\- `Bank Holiday` (*0 hrs*)  
\- `Sick` (*0 hrs*)  
\- `Sick Half` (*3.7 hrs*)  
\- `Leave` (*0 hrs*)  
\- `Leave Half` (*3.7 hrs*)  
\- `Flexi` (*7.4 hrs*)  
\- `Flexi Half` (*3.7 hrs*)

<img src="pics/dailyHours.PNG" align="centre" width="700" />

### Categories

Categories data are essential for linking appointments in outlook to a
time code.

Setting this up will be the most time consuming part of the process,
however it only need to be done once. In the below pictures the
`categories.csv` and outlook colour categories match up.

<div class="figure" style="text-align: center">

<img src="pics/categoriesCsv.PNG" alt="Allignment of categories.csv and colour categories in outlook" width="49%" height="20%" /><img src="pics/colourCats.PNG" alt="Allignment of categories.csv and colour categories in outlook" width="49%" height="20%" />

<p class="caption">

Allignment of categories.csv and colour categories in outlook

</p>

</div>

### Outlook calendar

Now the `categories.csv` and colour categories are set up you will need
to organise your outlook calendar.

Each appointment you wish to have included in time recording requires a
category.  
**Anything left blank will not be incorporated.**

You will need to export your calendar to use it in the tool, this takes
seconds to do.

> ***Calendar page on outlook*** ***\>\>*** ***file*** ***\>\>***
> ***Open & Export*** ***\>\>*** ***Import/Export*** ***\>\>***
> ***Export to a file*** ***\>\>*** ***Comma Separated Values***
> ***\>\>*** ***Under your email adress click calendar (pic below)***
> ***\>\>*** ***Insert Save location*** ***\>\>*** ***Export***
> ***\>\>*** ***Set Date Range***

<div class="figure" style="text-align: center">

<img src="pics/outlookExport1.png" alt="Outlook calendar export" width="49%" height="20%" /><img src="pics/outlookExport2.png" alt="Outlook calendar export" width="49%" height="20%" />

<p class="caption">

Outlook calendar export

</p>

</div>

## Running planThis

Following installation load the tool with:

``` r
library(planThis)
#> Warning: replacing previous import 'magrittr::extract' by 'tidyr::extract' when
#> loading 'planThis'
```

Set your file locations with;

``` r
path <- 'C:/Users/jpizzle/DeskyMcDeskFace/Time'
catags <- 'Categories_TCs.csv'
dailHours <- 'Daily_hours.xlsx'
outlC <- 'calendar_appoints3.csv'
weekS <- '2023-05-15'
tasks <- c('Cap Skills', 'FFIDP', 'Reactive Forecasting')
weightings <- c(1, 2, 1)
```

To create the time card use the `createTC()` function. In the case we
won’t export to the OTL form, using `export = FALSE`, and will instead
print the time card data into the console.

``` r
print(path)
#> [1] "C:/Users/jpayne05/Desktop/Time"
```

``` r
tCard <- createTC(file_path = path,
                  categories = catags,
                  daily = dailHours,
                  outCal = outlC,
                  week_start = weekS,
                  split = tasks,
                  weight = weightings,
                  export = FALSE)
print(tCard)
#> # A tibble: 8 x 11
#>   Code             Task  Type  hours~1   Mon   Tue   Wed   Thu   Fri   Sat   Sun
#>   <chr>            <chr> <chr> <chr>   <dbl> <dbl> <dbl> <dbl> <dbl> <dbl> <dbl>
#> 1 ENVABE           1     STAF~ ""        7.4   2.4  0      0     0       0     0
#> 2 ENVEGM5.1.1      990   STAF~ ""        0     0.5  0      0     0       0     0
#> 3 ENVHOABCPC120    03    STAF~ ""        0     0.9  2.68   1.7   1.8     0     0
#> 4 ENVIMR001016B00C CWEIY STAF~ ""        0     2.5  3.1    3.5   3.8     0     0
#> 5 ENVHOABCPC119    02    STAF~ ""        0     1.1  2.3    1.8   1.9     0     0
#> 6 ENVHOABCPC123    04    STAF~ ""        0     0    0      0.5   0       0     0
#> 7 ENVHOABCPC120    01    STAF~ ""        0     0    0      0.5   0       0     0
#> 8 ENVEGM5.16       010   STAF~ ""        0     0    0      0     0.5     0     0
#> # ... with abbreviated variable name 1: hoursType
```

When `export = TRUE` your OTL form will export into the `file_path`
location of the format OTL\_*`week_start`*. In the example below the
exported file is **OTL\_2023-05-15**

``` r
tCard <- createTC(file_path = path,
                  categories = catags,
                  daily = dailHours,
                  outCal = outlC,
                  week_start = weekS,
                  split = tasks,
                  weight = weightings,
                  export = TRUE)
```

<img src="pics/OTL.PNG" align="centre" width="700" />
