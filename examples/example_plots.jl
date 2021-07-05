"""
Example of how to runs loops of OPFs and plots a series of graphs to facilitate the analisys
of the Transmission Constrained Residual Demand Derivative (TCRDD) approach using the
package MaximumGeneratorProfitTCRDD. The plots allow the user to visualize the actual
behaviour of the system under different ammounts of bids vs the system with approximations
for the calculation of the profit function. The TCRDD algorithm is taken from [1].

[1] L. Xu, R. Baldick and Y. Sutjandra, "Bidding Into Electricity Markets:
    A Transmission-Constrained Residual Demand Derivative Approach," in IEEE
    Transactions on Power Systems, vol. 26, no. 3, pp. 1380-1388, Aug. 2011,
    doi: 10.1109/TPWRS.2010.2083702.
"""
# Packages
using DataFrames
using Dates
using DataStructures
using Ipopt
using MaximumGeneratorProfitTCRDD
using PowerSystems
using PowerSimulations
using Test
using TimeSeries

# Build Test Case
include("data/example_case4/buildup_case4.jl")
include("data/example_case4/c_sys_case4.jl")
sys = c_sys_case4()

# Settings
# Number of OPF points to plot the profit function
div = 500
# Network representation
network = StandardPTDFModel
# Solver for OPF
solver = optimizer_with_attributes(Ipopt.Optimizer)
# Tolerance to identify a change in the TCRDD
tcrdd_tol = 1e-3
# Gap to force a recalculation of the TCRDD
gap = div #No forced recalculation
# Tolerance to identify binding constraints
dual_lines_tol = 1e-1
dual_gen_tol = 1e-1
# Flag to get an extra plot for Example Case 4
examplecase4 = true

# Run and plot the OPF Loops
plots_TCRDD(
    sys;
    div,
    network,
    solver,
    tcrdd_tol,
    gap,
    dual_lines_tol,
    dual_gen_tol,
    examplecase4
)
