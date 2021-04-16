
"""
    function MaxGenProfit_tcrdd(sys::System, bid0::Float64; kwargs...)

Returns the bid which maximises the profit of the Generator at the slack bus using
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
- `Name`:                                   Description
-------------------------------------------------------------------------------------------
- `sys::System`:                            Power system in p.u. (from PowerSystems.jl)
- `bid0::Float64`:                          Initial bid for the Slack Generator in p.u.

# Keywords
- `Name`:                                   Description
-------------------------------------------------------------------------------------------
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
- `Name`:                                   Description
-------------------------------------------------------------------------------------------
- `ArgError`:                               Initial Bid (bid0) must be within Pmin and Pmax
                                            of the slack generator.

"""
function MaxGenProfit_tcrdd(
    sys::System,
    bid0::Float64;
    dual_lines_tol::Float64 = 1e-1,
    dual_gen_tol::Float64 = 1e-1,
    segm_bid_argmax_profit::Int64 = 50000,
    maxit_scr::Int64 = 5,
    maxit_bi::Int64 = 30,
    epsilon::Float64 = 0.01,
    print_results::Bool =true,
    print_progress::Bool=true,
    print_plots::Bool = true,
    network::DataType = StandardPTDFModel,
    solver = optimizer_with_attributes(Ipopt.Optimizer)
    )

    # ----------------------------------------
    # ----------Local Screening Loop----------
    # ----------------------------------------

    # step 1 LSL
    # ----------Set Bid for OPF----------
    #Get Slack Generator component ,ID and name
    (gen_thermal_slack,gen_thermal_slack_id,gen_thermal_slack_name)=get_thermal_slack(sys)
    #Get Original Active Power Limits
    (Pmin_orig, Pmax_orig) = get_active_power_limits(gen_thermal_slack)
    #Verify that initial Bid is withinbounds
    if bid0 < Pmin_orig || bid0 > Pmax_orig
        error("ArgError: Initial Bid (bid0) must be within Pmin: ",Pmin_orig,
            " and Pmax: ",Pmax_orig, " for ", gen_thermal_slack_name)
    end
    #Change active power Limits to Bidmin = Pmin_orig Bidmax = bid0
    set_active_power_limits!(gen_thermal_slack, (min = Pmin_orig, max = bid0))

    # step 2 LSL
    # ----------Solve PTDF OPF----------
    (lmp0, res0) = opf_PTDF(sys; network, solver)
    BaseMVA = res0.base_power

    # ----------Calculate TCRDD----------
    tcrdd_slack0 = f_TCRDD(sys, res0; dual_lines_tol, dual_gen_tol)

    # ----------Evaluate Profit----------
    (profit_argmax0, bid_argmax0) = bid_argmax_profit(
        sys,
        BaseMVA,
        lmp0,
        tcrdd_slack0,
        bid0,
        Pmin_orig,
        Pmax_orig;
        segm_bid_argmax_profit,
        print_plots
    )

    # ----------Local Screening----------
    #Initial conditions
    bid_opt_found = false
    bid_opt = bid0
    bid1 = bid0
    bid_mid = bid0
    bid_lo = Pmin_orig
    bid_hi = Pmax_orig
    stop = false
    iter_scr = 0
    iter_bi = 0
    # step 3 LSL
    if bid_argmax0 == bid0
        bid_opt_found = true
        bid_opt = bid0
        println("Local optimum found in: ",bid_opt)
    elseif bid0 == Pmax_orig && bid_argmax0 > Pmax_orig
        bid_opt_found = true
        bid_opt = bid0
        println("Local optimum found in: ",bid_opt)
    elseif bid0 == Pmin_orig && bid_argmax0 < Pmin_orig
        bid_opt_found = true
        bid_opt = bid0
        println("Local optimum found in: ",bid_opt)
    else
        # step 4 LSL
        while (iter_scr <= maxit_scr && stop == false)
            iter_scr = iter_scr + 1
            if iter_scr > 1 #only if we need to recalculate because we are still searching
                #Change active power Limits to Bidmin = Pmin_orig Bidmax = bid0
                set_active_power_limits!(gen_thermal_slack, (min = Pmin_orig, max = bid0))
                # Solve PTDF OPF
                (lmp0, res0) = opf_PTDF(sys; network, solver)
                # Calculate TCRDD
                tcrdd_slack0 = f_TCRDD(sys, res0; dual_lines_tol, dual_gen_tol)
                # Evaluate Profit
                (profit_argmax0, bid_argmax0) = bid_argmax_profit(
                    sys,
                    BaseMVA,
                    lmp0,
                    tcrdd_slack0,
                    bid0, Pmin_orig,
                    Pmax_orig;
                    segm_bid_argmax_profit,
                    print_plots
                )
            end
            if bid_argmax0 > bid0
                bid1 = min(bid_argmax0, Pmax_orig)
            else
                bid1 = max(bid_argmax0, Pmin_orig)
            end
            # Change active power Limits to Bidmin = Pmin_orig Bidmax = bid1
            set_active_power_limits!(gen_thermal_slack,(min = Pmin_orig, max = bid1))
            # Solve PTDF OPF
            (lmp1, res1) = opf_PTDF(sys; network, solver)
            # Calculate TCRDD
            tcrdd_slack1 = f_TCRDD(sys, res1; dual_lines_tol, dual_gen_tol)
            # Evaluate Profit
            (profit_argmax1, bid_argmax1) = bid_argmax_profit(
                sys,
                BaseMVA,
                lmp1,
                tcrdd_slack1,
                bid1,
                Pmin_orig,
                Pmax_orig;
                segm_bid_argmax_profit,
                print_plots
            )
            # step 5 LSL
            if bid_argmax1 == bid1
                bid_opt_found = true
                bid_opt = bid1
                println("Local optimum found in: ",bid_opt)
                stop = true
                break
            elseif bid1 == Pmax_orig && bid_argmax1 > Pmax_orig
                bid_opt_found = true
                bid_opt = bid1
                println("Local optimum found in: ",bid_opt)
                stop = true
                break
            elseif bid1 == Pmin_orig && bid_argmax1 < Pmin_orig
                bid_opt_found = true
                bid_opt = bid1
                println("Local optimum found in: ",bid_opt)
                stop = true
                break
                # step 6 LSL
            elseif ((bid_argmax1-bid1)*(bid_argmax0-bid0)) < 0
                bid_lo = min(bid0, bid1)
                bid_hi = max(bid0, bid1)
                println("Local optimum exists in: [ ",bid_lo," , ",bid_hi," ]")
                # ----------------------------------
                # ----------Bisection Loop----------
                # ----------------------------------
                (stop, iter_bi, bid_opt_found, bid_opt, bid_mid) = bisection_loop(
                    sys,
                    BaseMVA,
                    bid_lo,
                    bid_hi,
                    Pmin_orig,
                    Pmax_orig,
                    bid_opt_found,
                    stop;
                    maxit_bi,
                    network,
                    solver,
                    print_plots,
                    segm_bid_argmax_profit,
                    epsilon,
                    print_progress
                )
                break
            else
                println("Still Searching... Screening Loop iteration: ",iter_scr)
                bid0 = bid1
            end
        end
    end
    # ----------Print Results----------
    if print_results
        a=println("Found Optimal Bid: ", bid_opt_found)
        b=println("Optimal Bid Value: ", bid_opt)
        c=println("Local optimum exists in: [ ",bid_lo," , ",bid_hi," ]")
        d=println("Screening Loop iter: ", iter_scr)
        e=println("Bisection Loop iter: ", iter_bi)
    end
    return(bid_opt_found, bid_opt, bid_lo, bid_hi, iter_scr, iter_bi)
end
