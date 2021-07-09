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
function plots_virtTCRDD(
    sys::System,
    sender_buses_names::Array{String},
    weights::Array{String},
    bidMin::Float64,
    bidMax::Float64;
    div::Int64 = 1000,
    network::DataType = StandardPTDFModel,
    solver = optimizer_with_attributes(Ipopt.Optimizer),
    tcrdd_tol::Float64 = 1e-3,
    gap::Int64 = 50,
    dual_lines_tol::Float64 = 1e-1,
    dual_gen_tol::Float64 = 1e-1,
    )

    # Getting Slack Generator and Reference Bus
    # Get Slack Generator component, ID and name
    gen_thermal_slack, gen_thermal_slack_id, gen_thermal_slack_name = MaximumGeneratorProfitTCRDD.get_thermal_slack(sys)
    bus_slack = gen_thermal_slack.bus
    bus_slack_name = bus_slack.name
    # Get System Power Base
    BaseMVA = sys.units_settings.base_value

    # Defining Plot limits
    div = 100
    step = (bidMax - bidMin)/div

    #number of sender buses
    ns = length(sender_buses_names)

    # Dimentionalize Arrays for Plots
    bids = Array{Float64}(undef, div+1)
    Pg_s = Array{Float64}(undef, div+1, ns)
    Pg_s0 = Array{Float64}(undef, div+1, ns)
    residualD_virt = zeros(div+1, ns)
    residualD_virt_tot = zeros(div+1)
    virt_profit_s = zeros(div+1, ns)
    virt_profit_s_noCost = zeros(div+1, ns)
    virt_profit_tot = Array{Float64}(undef, div+1)
    virt_cost_s = Array{Float64}(undef, div+1, ns)
    clearprice = zeros(div+1, ns)
    lmp_s = Array{Float64}(undef, div+1, ns)
    lmp_s0 = Array{Float64}(undef, div+1, ns)
    lmp_s_apx_tcrdd = Array{Float64}(undef, div+1, ns)
    tcrdd = zeros(div+1, ns)
    tcrdd0 = zeros(div+1, ns)
    virt_profit_s_tcrdd = zeros(div+1, ns)
    virt_profit_s_noCost_tcrdd = zeros(div+1, ns)
    virt_profit_tot_tcrdd = Array{Float64}(undef, div+1)
    clearprice_tcrdd = zeros(div+1, ns)

    #virt_profit_tcrdd = Array{Float64}(undef, div+1)
    #virt_profit_noCost = Array{Float64}(undef, div+1)
    #virt_profit_tcrdd_noCost = Array{Float64}(undef, div+1)

    #tcrdd = Array{Float64}(undef, div+1, ns)
    #nbind_lines = Array{Int64}(undef, div+1)

    # TCRDD plot settings
    #same_tcrdd = false
    #gap_count = 0
    #tcrdd0 = 0
    #lmp_s0 = 0
    #Pg_s0 = 0

    # Add Virtual Generators
    sys, gen_virt, gen_virt_names = MaximumGeneratorProfitTCRDD.add_virtual_gens!(
        sys,
        sender_buses_names,
        weights,
        bidMin,
        bidMax,
    )

    # Initial Conditions
    iter_opf = 0
    # Run Loops of OPF
    bid = 1.0 #just for tests
    for bid in bidMin:step:bidMax #minimum bid to maximum bid
        # Increment iterations
        iter_opf = iter_opf + 1
        # Save bid
        bids[iter_opf] = bid
        # Set the weighted bid as the maximum power for OPF
        for (i, gen_virt_name) in enumerate(gen_virt_names)
            gen_virt = get_component(ThermalStandard, sys, gen_virt_name)
            set_active_power_limits!(gen_virt, (min = bidMin, max = bid*weights[i]))
        end
        # Solve PTDF OPF
        lmp, res = MaximumGeneratorProfitTCRDD.opf_PTDF(sys; network, solver)
        # Saving LMPs of the Bidding Buses
        for (i, bus_name) in enumerate(sender_buses_names)
            lmp_s[iter_opf, i] = lmp[1, bus_name]
        end
        # Getting optimised generation Outputs
        all_PGenThermal = get_variables(res)[:P__ThermalStandard]

        # Calculate Residual demand
        residualD_virt, residualD_virt_tot = MaximumGeneratorProfitTCRDD.residual_demand_virt!(
            sys,
            res,
            gen_virt_names,
            residualD_virt,
            iter_opf
        )

        # Calculate Residual demand
        residualD_virt, residualD_virt_tot = MaximumGeneratorProfitTCRDD.residual_demand_virt!(
            sys,
            res,
            gen_virt_names,
            residualD_virt,
            iter_opf
        )

        # Calculate Profit and cost of each virtual gen
        for (i, gen_virt_name) in enumerate(gen_virt_names)
            gen_virt = get_component(ThermalStandard, sys, gen_virt_name)
            Pg_s[iter_opf, i] = all_PGenThermal[1, gen_virt_name]
            # Calculate cost [$/hr] virt_cost = αPg² + βPg + γ
            α, β = get_cost(get_variable(get_operation_cost(gen_virt)))
            γ = get_fixed(get_operation_cost(gen_virt))
            virt_cost_s[iter_opf, i] =
                α*(Pg_s[iter_opf, i]*BaseMVA)^2 + β*(Pg_s[iter_opf, i]*BaseMVA) + γ
            # Clear price
            clearprice[iter_opf, i] = lmp_s[iter_opf, i] * Pg_s[iter_opf, i] * BaseMVA
            # Profit
            virt_profit_s[iter_opf, i] = clearprice[iter_opf, i] - virt_cost_s[iter_opf, i]
            virt_profit_s_noCost[iter_opf, i] = clearprice[iter_opf, i]
            virt_profit_tot[iter_opf] = virt_profit_tot[iter_opf] + virt_profit_s[iter_opf, i]
        end

        # Calculate TCRDDs
        for (i, bus_name) in enumerate(sender_buses_names)
            MaximumGeneratorProfitTCRDD.change_slack!(sys, bus_name)
            tcrdd[iter_opf, i] = MaximumGeneratorProfitTCRDD.f_TCRDD(sys, res; dual_lines_tol, dual_gen_tol)
        end
        # Return original slack
        MaximumGeneratorProfitTCRDD.change_slack!(sys, bus_slack_name)

        # Calculate Profit and cost of each virtual gen using TCRDD
        for (i, gen_virt_name) in enumerate(gen_virt_names)
            tcrdd0[iter_opf, i] = tcrdd[iter_opf, i]/(BaseMVA^2)
            lmp_s0[iter_opf, i] = lmp_s[iter_opf, i]
            Pg_s0[iter_opf, i] = Pg_s[iter_opf, i]
            gen_virt = get_component(ThermalStandard, sys, gen_virt_name)
            Pg_s[iter_opf, i] = all_PGenThermal[1, gen_virt_name]
            # Clear price
            lmp_s_apx_tcrdd[iter_opf, i] =
                ( (1/tcrdd0[iter_opf, i]) * (Pg_s[iter_opf, i] - Pg_s0[iter_opf, i]) ) + lmp_s0[iter_opf, i]
            clearprice_tcrdd[iter_opf, i] = lmp_s_apx_tcrdd[iter_opf, i] * Pg_s[iter_opf, i] * BaseMVA
            # Profit
            virt_profit_s_tcrdd[iter_opf, i] = clearprice_tcrdd[iter_opf, i] - virt_cost_s[iter_opf, i]
            virt_profit_s_noCost_tcrdd[iter_opf, i] = clearprice_tcrdd[iter_opf, i]
            virt_profit_tot_tcrdd[iter_opf] = virt_profit_tot_tcrdd[iter_opf] + virt_profit_s_tcrdd[iter_opf, i]
        end

    end #for end

    # Display Plots
    disp_plots_virt(
        bids,
        gen_profit_s,
        gen_profit_s_tcrdd,
        gen_profit_s_noCost,
        gen_profit_s_tcrdd_noCost,
        virt_cost_slack,
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
