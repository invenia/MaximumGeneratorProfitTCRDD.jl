# ----------Packages----------
using Cbc
using D3TypeTrees
using DataFrames
using Dates
using DataStructures
using GLPK
using Ipopt
using JuMP
using LinearAlgebra
using Plots
using PowerSimulations
using PowerSystems
using TimeSeries

# -------Package Constants-------
const PSY = PowerSystems
const PSI = PowerSimulations

# ----------Functions----------
# Power System Auxiliary Functions for TCRDD Algorithm
include(joinpath("./src/powersystemaux", "get_thermal_slack.jl"))
include(joinpath("./src/powersystemaux", "opf_PTDF.jl"))
include(joinpath("./src/powersystemaux", "assign_lines_index.jl"))
include(joinpath("./src/powersystemaux", "change_slack!.jl"))
include(joinpath("./src/powersystemaux", "get_binding_lines.jl"))
include(joinpath("./src/powersystemaux", "get_Pg_thermal_slack.jl"))
include(joinpath("./src/powersystemaux", "get_Pg_thermal_bindingPg.jl"))
include(joinpath("./src/powersystemaux", "get_Pg_thermal_constprice.jl"))
include(joinpath("./src/powersystemaux", "get_Pg_thermal_nonzeroslope.jl"))
include(joinpath("./src/powersystemaux", "get_PTDF_bindingLines.jl"))
include(joinpath("./src/powersystemaux", "get_PTDF_load.jl"))
include(joinpath("./src/powersystemaux", "get_PTDF_thermal_bindingPg.jl"))
include(joinpath("./src/powersystemaux", "get_PTDF_thermal_constprice.jl"))
include(joinpath("./src/powersystemaux", "get_PTDF_thermal_nonzeroslope.jl"))
include(joinpath("./src/powersystemaux", "get_PTDF_thermal_slack.jl"))
include(joinpath("./src/powersystemaux", "get_thermal_bindingPg.jl"))
include(joinpath("./src/powersystemaux", "get_thermal_nonzeroslope.jl"))
include(joinpath("./src/powersystemaux", "get_thermal_constprice.jl"))
# Functions for TCRDD Algorithm
include(joinpath("./src/algorithm", "f_TCRDD.jl"))
include(joinpath("./src/algorithm", "bid_argmax_profit.jl"))
include(joinpath("./src/algorithm", "compare_tan_inv_RDC.jl"))
include(joinpath("./src/algorithm", "bisection_loop.jl"))
include(joinpath("./src/algorithm", "d2f_PgPg_nonzeroslope.jl"))
include(joinpath("./src/algorithm", "residual_demand.jl"))
include(joinpath("./src/algorithm", "disp_plots.jl"))
# Main Functions
#include(joinpath("./src", "MaxGenProfit_tcrdd.jl"))

# ----------Test case----------
include(joinpath("./data", "case4_TCRDDpu.jl"))
sys = build_c_sys4_tcrd()

# ----------Selecting solver----------
solver = optimizer_with_attributes(Ipopt.Optimizer)
#solver = optimizer_with_attributes(GLPK.Optimizer)

# ----------Network representation----------
network = StandardPTDFModel
#network = DCOPF

bid0 = 0.65
dual_lines_tol = 1e-1
dual_gen_tol = 1e-1
segm_bid_argmax_profit = 50000
maxit_scr = 5
maxit_bi = 30
epsilon = 0.01 #tolerance bid_lo - bid_hi < epsilon
print_results = true
print_progress = true
print_plots = true
#Get Slack Generator component ,ID and name
(gen_thermal_slack,gen_thermal_slack_loc,gen_thermal_slack_name)=get_thermal_slack(sys)
set_active_power_limits!(gen_thermal_slack,(min = 0.0, max = 1.0))
# Main Functions
include(joinpath("./src", "MaxGenProfit_tcrdd.jl"))
(bid_opt_found, bid_opt, bid_lo, bid_hi, iter_scr, iter_bi)=MaxGenProfit_tcrdd(sys, bid0; 
dual_lines_tol, dual_gen_tol, segm_bid_argmax_profit, maxit_scr, maxit_bi, epsilon, 
print_results, print_progress, print_plots, network, solver)

#Short Pause to see output data
sleep(10)

div = 500
tcrdd_tol = 1e-3
gap = 25
# Main Plots
include(joinpath("./src", "plots_TCRDD.jl"))
set_active_power_limits!(gen_thermal_slack,(min = 0.0, max = 1.0))
plots_TCRDD(sys; div, network,solver, tcrdd_tol, gap, dual_lines_tol, dual_gen_tol)

