"""
Example of how to obtain the bid which maximises the profit of the Generator at the slack
bus using the Package MaximumGeneratorProfitTCRDD. The Algorithm is based on the
Transmission Constrained Residual Demand Derivative (TCRDD) [1].

[1] L. Xu, R. Baldick and Y. Sutjandra, "Bidding Into Electricity Markets:
    A Transmission-Constrained Residual Demand Derivative Approach," in IEEE
    Transactions on Power Systems, vol. 26, no. 3, pp. 1380-1388, Aug. 2011,
    doi: 10.1109/TPWRS.2010.2083702.
"""
# Packages
using Ipopt
using MaximumGeneratorProfitTCRDD
using PowerSystems
using PowerSimulations

# Build Test Case
sys = MaximumGeneratorProfitTCRDD.c_sys_case4()

# Settings
# Solver for OPF
solver = optimizer_with_attributes(Ipopt.Optimizer)
# Network representation
network = StandardPTDFModel
# Tolerance to identify binding constraints
dual_lines_tol = 1e-1
dual_gen_tol = 1e-1
# Segments to evaluate approximated profit function
segm_bid_argmax_profit = 50000
# Maximum iterations for Screening and Bisection Loops
maxit_scr = 3
maxit_bi = 5
# Convergence Tolerance between bids in [pu]
epsilon = 0.01 #tolerance bid_lo - bid_hi < epsilon
# Flags
print_results = true
print_progress = true
print_plots = true

# Initial Bid
bid0 = 0.3

# Maximize Generator Profit
bid_opt_found, bid_opt, bid_lo, bid_hi, iter_scr, iter_bi = maxGenProfit_tcrdd(
    sys,
    bid0;
    dual_lines_tol,
    dual_gen_tol,
    segm_bid_argmax_profit,
    maxit_scr,
    maxit_bi,
    epsilon,
    print_results,
    print_progress,
    print_plots,
    network,
    solver
    )
