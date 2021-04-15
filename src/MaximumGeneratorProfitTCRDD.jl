module MaximumGeneratorProfitTCRDD

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
include("powersystemaux/assign_lines_index.jl")
include("powersystemaux/change_slack!.jl")
include("powersystemaux/get_binding_lines.jl")
include("powersystemaux/get_Pg_thermal_slack.jl")
include("powersystemaux/get_Pg_thermal_bindingPg.jl")
include("powersystemaux/get_Pg_thermal_constprice.jl")
include("powersystemaux/get_Pg_thermal_nonzeroslope.jl")
include("powersystemaux/get_PTDF_bindingLines.jl")
include("powersystemaux/get_PTDF_load.jl")
include("powersystemaux/get_PTDF_thermal_bindingPg.jl")
include("powersystemaux/get_PTDF_thermal_constprice.jl")
include("powersystemaux/get_PTDF_thermal_nonzeroslope.jl")
include("powersystemaux/get_PTDF_thermal_slack.jl")
include("powersystemaux/get_thermal_slack.jl")
include("powersystemaux/get_thermal_bindingPg.jl")
include("powersystemaux/get_thermal_nonzeroslope.jl")
include("powersystemaux/get_thermal_constprice.jl")
include("powersystemaux/opf_PTDF.jl")

# Functions for TCRDD Algorithm
include("algorithm/f_TCRDD.jl")
include("algorithm/bid_argmax_profit.jl")
include("algorithm/compare_tan_inv_RDC.jl")
include("algorithm/bisection_loop.jl")
include("algorithm/d2f_PgPg_nonzeroslope.jl")
include("algorithm/residual_demand.jl")

# Main Functions 
include("maxGenProfit_tcrdd.jl")
include("plots_TCRDD.jl")

# Type

# Accessor functions
export get_binding_lines
export get_Pg_thermal_slack
export get_Pg_thermal_bindingPg
export get_Pg_thermal_constprice
export get_Pg_thermal_nonzeroslope
export get_PTDF_bindingLines
export get_PTDF_load
export get_PTDF_thermal_bindingPg
export get_PTDF_thermal_constprice
export get_PTDF_thermal_nonzeroslope
export get_PTDF_thermal_slack
export get_thermal_bindingPg
export get_thermal_nonzeroslope
export get_thermal_constprice

# Useful Calculation Functions
export change_slack!
export residual_demand

# Main Functions
export maxGenProfit_tcrdd
export plots_TCRDD

end
