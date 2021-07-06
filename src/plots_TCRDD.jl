"""
    function plots_TCRDD(sys::System; kwargs...)

Runs loops of OPFs and plots a series of graphs to facilitate the analisys of the
Transmission Constrained Residual Demand Derivative (TCRDD) approach to maximise the slack
generator profit vs the actual behaviour of the system under different ammounts of bids.

Detailed description: The function runs a series of Optimal Power Flows (OPFs) for a series
of bids which range from the minimum (Pmin) power of the slack generator to the maximum
power of the slack generator (Pmax) for a set number of samples. Then for each sample the
values of the Profit, Cost, LMP, TCRDD, Residual demand and Binding Lines are calculated and
plotted. The TCRDD algorithm is taken from [1]. Conceptually with the TCRDD is possible to
create an approximation of the profit function. The Plot of the approximated profit function
is designed to take the initial solved OPF point, and create the approximated profit
function. This approximation will not be recalculated unless the value of the TCRDD changes.
The parameter "gap" allows you to force a reaproximation of the profit function for every
"gap" ammount of iterations. This helps the user to see how good or bad is the approximation
for a specific OPF point.


[1] L. Xu, R. Baldick and Y. Sutjandra, "Bidding Into Electricity Markets:
    A Transmission-Constrained Residual Demand Derivative Approach," in IEEE
    Transactions on Power Systems, vol. 26, no. 3, pp. 1380-1388, Aug. 2011,
    doi: 10.1109/TPWRS.2010.2083702.

#Arguments
- `sys::System`                             Power system in p.u. (from PowerSystems.jl)

#Keywords
- `div::Int64 = 1000`                       Number of divisions (samples) from Pmin to Pmax
- `network::DataType = StandardPTDFModel`   Network Representation of the Power System
- `solver= optimizer_with_attributes
    (Ipopt.Optimizer)`                      Solver to be used for OPF
- `tcrdd_tol::Float64 = 1e-3`               Tolerance to identify a change in the tcrdd
- `gap::Int64 = 50`                         Gap to force a recalculation of the tcrdd
- `dual_lines_tol::Float64 = 1e-1`          Value to identify any binding lines
- `dual_gen_tol::Float64 = 1e-1`            Value to identify any binding generators
- `examplecase4::Bool = false`              If running Case 4 example, provide an extra plot
"""
function plots_TCRDD(
    sys::System;
    div::Int64 = 1000,
    network::DataType = StandardPTDFModel,
    solver = optimizer_with_attributes(Ipopt.Optimizer),
    tcrdd_tol::Float64 = 1e-3,
    gap::Int64 = 50,
    dual_lines_tol::Float64 = 1e-1,
    dual_gen_tol::Float64 = 1e-1,
    examplecase4::Bool = false
    )

    # Getting Slack Generator and Bus
    # Get Slack Generator component, ID and name
    gen_thermal_slack, gen_thermal_slack_id, gen_thermal_slack_name = get_thermal_slack(sys)
    bus_slack = gen_thermal_slack.bus
    bus_slack_name = bus_slack.name
    # Get Slack Generator Costs gen_cost = αPg² + βPg + γ
    α, β = get_cost(get_variable(get_operation_cost(gen_thermal_slack)))
    γ = get_fixed(get_operation_cost(gen_thermal_slack))
    # Get System Power Base
    BaseMVA = sys.units_settings.base_value

    # Defining Plot limits
    # Get Active Power Limits
    Pmin_orig, Pmax_orig = get_active_power_limits(gen_thermal_slack)
    # Define divisions and get step
    Bidmin = Pmin_orig
    Bidmax = Pmax_orig
    step = (Bidmax - Bidmin)/div

    # Dimentionalize Arrays for Plots
    bids = Array{Float64}(undef, div+1)
    Pg_slack = Array{Float64}(undef, div+1)
    residualD_slack_Pg = Array{Float64}(undef, div+1)
    gen_profit = Array{Float64}(undef, div+1)
    gen_profit_tcrdd = Array{Float64}(undef, div+1)
    gen_profit_noCost = Array{Float64}(undef, div+1)
    gen_profit_tcrdd_noCost = Array{Float64}(undef, div+1)
    gen_cost_slack = Array{Float64}(undef, div+1)
    lmp_slack = Array{Float64}(undef, div+1)
    lmp_slack_apx_tcrdd = Array{Float64}(undef, div+1)
    tcrdd = Array{Float64}(undef, div+1)
    nbind_lines = Array{Int64}(undef, div+1)
    # TCRDD plot settings
    same_tcrdd = false
    gap_count = 0
    tcrdd0 = 0
    lmp_slack0 = 0
    Pg_slack0 = 0

    # Only for Case 4 example (needs to be declared even if empty to avoid conflicts)
    branch1_3= Array{Float64}(undef, div+1)

    # Initial Conditions
    iter_opf = 0
    # Run Loops of OPF
    for bid in Bidmin:step:Bidmax #minimum bid to maximum bid
        # Increment iterations
        iter_opf = iter_opf + 1
        # Save bid
        bids[iter_opf] = bid

        # Set the bid as the maximum power for OPF
        set_active_power_limits!(gen_thermal_slack, (min = Bidmin, max = bid))
        # Solve PTDF OPF
        lmp, res = opf_PTDF(sys; network, solver)
        # Calculate TCRDD
        tcrdd[iter_opf] = f_TCRDD(sys, res; dual_lines_tol, dual_gen_tol)

        # Getting optimised generation Outputs
        all_PGenThermal = get_variables(res)[:P__ThermalStandard]
        Pg_slack[iter_opf] = all_PGenThermal[1, gen_thermal_slack_name]
        # Calculate Residual demand
        residualD_slack_Pg[iter_opf] = residual_demand(sys, res)
        # lmp slackbus
        lmp_slack[iter_opf] = lmp[1, bus_slack_name]

        # Calculate cost of slack generator [$/hr] gen_cost = αPg² + βPg + γ
        gen_cost_slack[iter_opf] =
            α*(Pg_slack[iter_opf]*BaseMVA)^2 + β*(Pg_slack[iter_opf]*BaseMVA) + γ

        # Clear price
        clearprice = lmp_slack[iter_opf] * Pg_slack[iter_opf] * BaseMVA

        # Calculating Gen Profit of Slack bus
        gen_profit[iter_opf] = clearprice - gen_cost_slack[iter_opf]
        gen_profit_noCost[iter_opf] = clearprice

        # Number of Binding Lines
        bind_lines = get_binding_lines(sys, res; dual_lines_tol)
        nbind_lines[iter_opf] = length(bind_lines[:, 1])

        # Only for Case 4 example
        if examplecase4
            # Saving Loadability of branch 1-3
            branch1_3[iter_opf] = res.variable_values[:Fp__Line][1, "Line1"]
        end

        # Gen Profit TCRDD
        # Check if TCRDD is has changed within a tolerance
        if iter_opf > 1
            A_tcrdd = abs(tcrdd[iter_opf] - tcrdd[iter_opf - 1])
            if A_tcrdd < tcrdd_tol
                same_tcrdd = true
            else
                same_tcrdd = false
            end
        end

        if iter_opf == 1
            # Calculate the values for the approximation
            tcrdd0 = tcrdd[iter_opf]/(BaseMVA^2)
            lmp_slack0 = lmp_slack[iter_opf]
            Pg_slack0 = Pg_slack[iter_opf]
            # Evaluate the approximation for the current Pg_slack
            lmp_slack_apx_tcrdd[iter_opf] =
                ( (1/tcrdd0) * (Pg_slack[iter_opf] - Pg_slack0) ) + lmp_slack0
            clearprice_apx_tcrdd =
                lmp_slack_apx_tcrdd[iter_opf] * Pg_slack[iter_opf] * BaseMVA
            gen_profit_tcrdd[iter_opf] = clearprice_apx_tcrdd - gen_cost_slack[iter_opf]
            gen_profit_tcrdd_noCost[iter_opf] = clearprice_apx_tcrdd
            gap_count = 1

        elseif iter_opf > 1 && same_tcrdd
            # Don't recalculte the approximation, just evaluate it for the current Pg_slack
            gap_count = gap_count +1;
            if gap_count < gap
                lmp_slack_apx_tcrdd[iter_opf] =
                    ( (1/tcrdd0) * (Pg_slack[iter_opf] - Pg_slack0) ) + lmp_slack0
                clearprice_apx_tcrdd =
                    lmp_slack_apx_tcrdd[iter_opf] * Pg_slack[iter_opf] * BaseMVA
                gen_profit_tcrdd[iter_opf] = clearprice_apx_tcrdd - gen_cost_slack[iter_opf]
                gen_profit_tcrdd_noCost[iter_opf] = clearprice_apx_tcrdd
            else
                # The TCRDD is the same, but the gap has been reached,
                # So force a re-calculation of the values for the approximation
                tcrdd0 = tcrdd[iter_opf]/(BaseMVA^2);
                lmp_slack0 = lmp_slack[iter_opf];
                Pg_slack0 = Pg_slack[iter_opf];
                # Evaluate the approximation for the current Pg_slack
                lmp_slack_apx_tcrdd[iter_opf] =
                    ( (1/tcrdd0) * (Pg_slack[iter_opf] - Pg_slack0) ) + lmp_slack0
                clearprice_apx_tcrdd =
                    lmp_slack_apx_tcrdd[iter_opf] * Pg_slack[iter_opf] * BaseMVA
                gen_profit_tcrdd[iter_opf] = clearprice_apx_tcrdd - gen_cost_slack[iter_opf]
                gen_profit_tcrdd_noCost[iter_opf] = clearprice_apx_tcrdd
                # Restart the gap count
                gap_count = 0
            end

        elseif iter_opf > 1 && !same_tcrdd
            # The TCRDD changed, so re-calculate the values for the approximation
            tcrdd0 = tcrdd[iter_opf]/(BaseMVA^2)
            lmp_slack0 = lmp_slack[iter_opf]
            Pg_slack0 = Pg_slack[iter_opf]
            # Evaluate the approximation for the current Pg_slack
            lmp_slack_apx_tcrdd[iter_opf] =
                ( (1/tcrdd0) * (Pg_slack[iter_opf] - Pg_slack0) ) + lmp_slack0
            clearprice_apx_tcrdd =
                lmp_slack_apx_tcrdd[iter_opf] * Pg_slack[iter_opf] * BaseMVA
            gen_profit_tcrdd[iter_opf] = clearprice_apx_tcrdd - gen_cost_slack[iter_opf]
            gen_profit_tcrdd_noCost[iter_opf] = clearprice_apx_tcrdd
            # Restart the gap count
            gap_count = 0
        end
    end

    # Display Plots
    disp_plots(
        bids,
        gen_profit,
        gen_profit_tcrdd,
        gen_profit_noCost,
        gen_profit_tcrdd_noCost,
        gen_cost_slack,
        Pg_slack,
        lmp_slack,
        lmp_slack_apx_tcrdd,
        residualD_slack_Pg,
        tcrdd,
        nbind_lines,
        div;
        examplecase4,
        branch1_3,
        )

    return (nothing)
end
