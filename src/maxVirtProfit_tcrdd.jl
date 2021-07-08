using Base: ThreadSynchronizer, __throw_rational_argerror_typemin
"""
    function maxVirtProfit_tcrdd(
        sys::System,
        bid0::Float64,
        bidMax::Float64,
        bidMin::Float64,
        sender_buses_names::Array,
        weights::Array;
        kwargs...
    )

Returns the bid which maximises the profit of the set of weighted Generators at using
the Transmission Constrained Residual Demand Derivative (TCRDD).

Detailed description: The algorithm is composed by two parts, (1) the Local Screening Loop
(LSL) and (2) the Bisection Loop (BL). The screening loop uses the initial bid0 and creates
an aproximation of the profit function. Using this aproximation, it identifies the range
[bid lower (bid_lo) and bid higher (bid_hi)] in which the bid that maximises the generator
profit could be. Once the lower and upper bid range are identified, the bisection loop will
find try to find if the approximations of the lower and upper bid intersect at some point.
If they do, the intersection bid is used to find a closer upper and lower range, or identi-
fy if the optimum has been found. If they dont intersect then, traditional bisection is done
until the bid that maximises the generators profit is found [1].

[1] L. Xu, R. Baldick and Y. Sutjandra, "Bidding Into Electricity Markets:
    A Transmission-Constrained Residual Demand Derivative Approach," in IEEE
    Transactions on Power Systems, vol. 26, no. 3, pp. 1380-1388, Aug. 2011,
    doi: 10.1109/TPWRS.2010.2083702.

# Arguments
- `sys::System`:                            Power system in p.u. (from PowerSystems.jl)
- `bid0::Float64`:                          Initial bid for the Virtual Participant in p.u.
- `bidMax::Float64`:                        Max bid for the Virtual Participant in p.u.
- `bidMin::Float64`:                        Min bid for the Virtual Participant in p.u.
- `sender_buses_names::Array`:              Names of the buses to bid on
- `weights::Array`:                         Weights for each bus to bid

# Keywords
- `dual_lines_tol::Float64 = 1e-1`:         Tolerance to identify any binding lines
- `dual_gen_tol::Float64 = 1e-1`:           Tolerance to identify any binding generators
- `segm_bid_argmax_profit::Int64 = 50000:   Segments to evaluate the approx profit function
- `maxit_scr::Int64 = 5`:                   Maximum number of iterations for Screening Loop
- `maxit_bi::Int64 = 30`:                   Maximum number of iterations for Bisection Loop
- `epsilon::Float64 = 0.01`:                Convergence tolerance  bid_lo - bid_hi < epsilon
- `print_results::Bool = true`:             Flag to print results
- `print_progress::Bool = true`:            Flag to print progress
- `print_plots::Bool = true`:               Flag to print plots
- `network::DataType = StandardPTDFModel`:  Network Representation of the Power System
- `solver= optimizer_with_attributes
    (Ipopt.Optimizer)`:                     Solver to be used for OPF

# Throws
- `ArgError`:                               Initial Bid (bid0) must be within Pmin and Pmax
                                            of the slack generator.

"""
function maxVirtProfit_tcrdd(
    sys::System,
    bid0::Float64,
    bidMax::Float64,
    bidMin::Float64,
    sender_buses_names::Array{String},
    weights::Array{Float64};
    dual_lines_tol::Float64 = 1e-1,
    dual_gen_tol::Float64 = 1e-1,
    segm_bid_argmax_profit::Int64 = 50000,
    maxit_scr::Int64 = 5,
    maxit_bi::Int64 = 30,
    epsilon::Float64 = 0.01,
    print_results::Bool =true,
    print_progress::Bool=false,
    print_plots::Bool = false,
    network::DataType = StandardPTDFModel,
    solver = optimizer_with_attributes(Ipopt.Optimizer)
    )

    # Local Screening Loop

    # step 1 LSL
    # Set Bid for OPF
    # Add Virtual Generators
    sys, gen_virt, gen_virt_names = add_virtual_gens!(
        sys,
        sender_buses_names,
        weights,
        bidMin,
        bidMax,
    )

    # Change active power Limits to Bidmin = bidMin Bidmax = bid0*weight
    for (i, gen_virt_name) in enumerate(gen_virt_names)
        gen_virt = get_component(ThermalStandard, sys, gen_virt_name)
        set_active_power_limits!(gen_virt, (min = bidMin, max = bid0*weights[i]))
    end

    # step 2 LSL
    # Solve PTDF OPF
    lmp0, res0 = opf_PTDF(sys; network, solver)
    BaseMVA = res0.base_power

    # Get Slack Generator
    gen_slack_orig, gen_slack_orig_id, gen_slack_orig_name = get_thermal_slack(sys)
    bus_slack_orig = get_name(get_bus(gen_slack_orig))

    # Calculate TCRDDs
    tcrdd0 = Array{Float64}(undef, length(sender_buses_names))
    for (i, bus_name) in enumerate(sender_buses_names)
        change_slack!(sys, bus_name)
        tcrdd0[i] = f_TCRDD(sys, res0; dual_lines_tol, dual_gen_tol)
    end
    # Return original slack
    change_slack!(sys, bus_slack_orig)

    # Evaluate Profit
    profit_argmax0, bid_argmax0 = bid_argmax_virt_profit(
        sys,
        res0,
        BaseMVA,
        lmp0,
        tcrdd0,
        weights,
        gen_virt_names,
        bid0,
        bidMax,
        bidMin;
        segm_bid_argmax_profit,
        print_plots
    )

    # Local Screening
    # Initial conditions
    bid_opt_found = false
    bid_opt = bid0
    bid1 = bid0
    bid_mid = bid0
    bid_lo = bidMin
    bid_hi = bidMax
    stop = false
    iter_scr = 0
    iter_bi = 0
    # step 3 LSL
    if bid_argmax0 == bid0
        bid_opt_found = true
        bid_opt = bid0
        println("Local optimum found in: ", bid_opt)
    elseif bid0 == bidMax && bid_argmax0 > bidMax
        bid_opt_found = true
        bid_opt = bid0
        println("Local optimum found in: ", bid_opt)
    elseif bid0 == bidMin && bid_argmax0 < bidMin
        bid_opt_found = true
        bid_opt = bid0
        println("Local optimum found in: ", bid_opt)
    else
        # step 4 LSL
        while (iter_scr <= maxit_scr && stop == false)
            iter_scr = iter_scr + 1
            if iter_scr > 1 # only if we need to recalculate because we are still searching
                # Change active power Limits to Bidmin = bidMin Bidmax = bid0*weight
                for (i, gen_virt_name) in enumerate(gen_virt_names)
                    gen_virt = get_component(ThermalStandard, sys, gen_virt_name)
                    set_active_power_limits!(gen_virt, (min = bidMin, max = bid0*weights[i]))
                end
                # Solve PTDF OPF
                lmp0, res0 = opf_PTDF(sys; network, solver)
                # Calculate TCRDDs
                tcrdd0 = Array{Float64}(undef, length(sender_buses_names))
                for (i, bus_name) in enumerate(sender_buses_names)
                    change_slack!(sys, bus_name)
                    tcrdd0[i] = f_TCRDD(sys, res0; dual_lines_tol, dual_gen_tol)
                end
                # Return original slack
                change_slack!(sys, bus_slack_orig)
                # Evaluate Profit
                profit_argmax0, bid_argmax0 = bid_argmax_virt_profit(
                    sys,
                    res0,
                    BaseMVA,
                    lmp0,
                    tcrdd0,
                    weights,
                    gen_virt_names,
                    bid0,
                    bidMax,
                    bidMin;
                    segm_bid_argmax_profit,
                    print_plots
                )
            end
            if bid_argmax0 > bid0
                bid1 = min(bid_argmax0, bidMax)
            else
                bid1 = max(bid_argmax0, bidMin)
            end
            # Change active power Limits to Bidmin = bidMin Bidmax = bid1*weight
            for (i, gen_virt_name) in enumerate(gen_virt_names)
                gen_virt = get_component(ThermalStandard, sys, gen_virt_name)
                set_active_power_limits!(gen_virt, (min = bidMin, max = bid1*weights[i]))
            end
            # Solve PTDF OPF
            lmp1, res1 = opf_PTDF(sys; network, solver)
            # Calculate TCRDDs
            tcrdd1 = Array{Float64}(undef, length(sender_buses_names))
            for (i, bus_name) in enumerate(sender_buses_names)
                change_slack!(sys, bus_name)
                tcrdd1[i] = f_TCRDD(sys, res1; dual_lines_tol, dual_gen_tol)
            end
            # Return original slack
            change_slack!(sys, bus_slack_orig)
            # Evaluate Profit
            profit_argmax1, bid_argmax1 = bid_argmax_virt_profit(
                sys,
                res1,
                BaseMVA,
                lmp1,
                tcrdd1,
                weights,
                gen_virt_names,
                bid1,
                bidMax,
                bidMin;
                segm_bid_argmax_profit,
                print_plots
            )
            # step 5 LSL
            if bid_argmax1 == bid1
                bid_opt_found = true
                bid_opt = bid1
                println("Local optimum found in: ", bid_opt)
                stop = true
                break
            elseif bid1 == bidMax && bid_argmax1 > bidMax
                bid_opt_found = true
                bid_opt = bid1
                println("Local optimum found in: ", bid_opt)
                stop = true
                break
            elseif bid1 == bidMin && bid_argmax1 < bidMin
                bid_opt_found = true
                bid_opt = bid1
                println("Local optimum found in: ", bid_opt)
                stop = true
                break
                # step 6 LSL
            elseif ((bid_argmax1-bid1)*(bid_argmax0-bid0)) < 0
                bid_lo = min(bid0, bid1)
                bid_hi = max(bid0, bid1)
                println("Local optimum exists in: [ ",bid_lo," , ",bid_hi," ]")
                # Bisection Loop
                #=
                stop, iter_bi, bid_opt_found, bid_opt, bid_mid = bisection_loop!(
                    sys,
                    BaseMVA,
                    bid_lo,
                    bid_hi,
                    Pmin_orig,
                    Pmax_orig,
                    stop;
                    maxit_bi,
                    network,
                    solver,
                    print_plots,
                    segm_bid_argmax_profit,
                    epsilon,
                    print_progress,
                    dual_lines_tol,
                    dual_gen_tol
                )
                =#
                break
            else
                println("Still Searching... Screening Loop iteration: ",iter_scr)
                bid0 = bid1
            end
        end
    end
    # Print Results
    if print_results
        println(" ")
        println("----------Maximum Profit TCRDD Results----------")
        println("Found Optimal Bid: ", bid_opt_found)
        println("Optimal Bid Value: ", bid_opt)
        println("Local optimum exists in: [ ",bid_lo," , ",bid_hi," ]")
        println("Screening Loop iter: ", iter_scr)
        println("Bisection Loop iter: ", iter_bi)
        println("------------------------------------------------")
    end

    # Return original slack
    change_slack!(sys, bus_slack_orig)

    return bid_opt_found, bid_opt, bid_lo, bid_hi, iter_scr, iter_bi
end
