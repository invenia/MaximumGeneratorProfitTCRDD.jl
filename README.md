# MaximumGeneratorProfitTCRDD

The package allows the user to find the bid which maximises the profit of the Generator at
the slack bus using the Transmission Constrained Residual Demand Derivative (TCRDD).

Two Main Functions compose the package, (A) maxGenProfit_tcrdd and (B) plots_TCRDD. 
Function A finds the bid which maximises the profit, and function B creates a series of 
plots to facilitate the analisys of the algorithm.

### The Algorithm

The algorithm is composed by two parts, (1) the Local Screening Loop (LSL) and (2) the 
Bisection Loop (BL). The screening loop uses the initial bid0 and creates an aproximation
of the profit function. Using this aproximation, it identifies the range [bid lower 
(bid_lo) and bid higher (bid_hi)] in which the bid that maximises the generator profit 
could be. Once the lower and upper bid range are identified, the bisection loop will find 
try to find if the approximations of the lower and upper bid intersect at some point. If 
they do, the intersection bid is used to find a closer upper and lower range, or identify 
if the optimum has been found. If they dont intersect then, traditional bisection is done 
until the bid that maximises the generators profit is found [1].

### References
[1] L. Xu, R. Baldick and Y. Sutjandra, "Bidding Into Electricity Markets:
    A Transmission-Constrained Residual Demand Derivative Approach," in IEEE
    Transactions on Power Systems, vol. 26, no. 3, pp. 1380-1388, Aug. 2011,
    doi: 10.1109/TPWRS.2010.2083702.
