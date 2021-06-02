"""
    function bisection_loop!(args...; kwargs)

Takes a a bid range [bid_lo, bid_hi] and returns the bid which maximises the profit of the
Generator at the slack bus using the Transmission Constrained Residual Demand Derivative
(TCRDD). This is the second part of the full algorithm.

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
- `bid_lo::Float64`:                        Lower Bid for the slack generator [pu]
- `bid_hi::Float64`:                        Higher Bid for the slack generator [pu]
- `Pmin_orig::Float64`:                     Active power minimum limit Slack gen [pu]
- `Pmax_orig::Float64`:                     Active power maximum limit Slack gen [pu]
- `stop::Bool`:                             Flag to stop the algorithm

# Keywords
- `Name`:                                   Description
-------------------------------------------------------------------------------------------
- `maxit_bi::Int64 = 30`:                   Maximum number of iterations for Bisection Loop
- `network::DataType = StandardPTDFModel`:  Network Representation of the Power System
- `solver= optimizer_with_attributes
    (Ipopt.Optimizer)`:                     Solver to be used for OPF
- `print_plots::Bool = true`:               Flag to print plots
- `segm_bid_argmax_profit::Int64 = 50000:   Segments to evaluate the approx profit function
- `epsilon::Float64 = 0.01`:                Convergence tolerance  bid_lo - bid_hi < epsilon
- `print_progress::Bool = true`:            Flag to print progress
- `dual_lines_tol::Float64 = 1e-1`:         Tolerance to identify any binding lines
- `dual_gen_tol::Float64 = 1e-1`:           Tolerance to identify any binding generators

"""
function bisection_loop!(
    sys::System,
    BaseMVA::Float64,
    bid_lo::Float64,
    bid_hi::Float64,
    Pmin_orig::Float64,
    Pmax_orig::Float64,
    stop::Bool;
    maxit_bi::Int64,
    network::DataType = StandardPTDFModel,
    solver = optimizer_with_attributes(Ipopt.Optimizer),
    print_plots::Bool = true,
    segm_bid_argmax_profit::Int64 = 50000,
    epsilon::Float64 = 0.01,
    print_progress::Bool = true,
    dual_lines_tol::Float64 = 1e-1,
    dual_gen_tol::Float64 = 1e-1
    )
    # ----------------------------------------
    # ------------Bisection Loop--------------
    # ----------------------------------------
    println("Bisection Loop")

    # ----------Initial conditions----------
    iter_bi = 0
    same_tan_inv_lo_hi = false
    intersect_tan_inv_lo_hi = false
    bid_opt_found = false
    bid_mid = 0.5*(bid_lo + bid_hi)
    bid_intersect = bid_mid
    bid_opt = bid_mid

    # ----------Get Slack Generator----------
    (gen_thermal_slack, gen_thermal_slack_id, gen_thermal_slack_name) =
        get_thermal_slack(sys)

    # ----------Algorithm Loops----------
    while (iter_bi <= maxit_bi && stop == false)
        iter_bi = iter_bi + 1
        # step 1 BL
        if abs(bid_hi - bid_lo) < epsilon
            bid_opt_found = true
            bid_opt = 0.5*(bid_lo + bid_hi)
            println("Local optimum found in", bid_opt)
            stop = true
            break
        # step 2 BL
        else
            # ----------Calculate bisection point bid_mid----------
            # Calculations when bid = bid_lo
            # Change active power Limits to Bidmin = Pmin_orig Bidmax = bid_lo
            set_active_power_limits!(gen_thermal_slack, (min = Pmin_orig, max = bid_lo))
            # Solve PTDF OPF
            (lmp_lo, res_lo) = opf_PTDF(sys; network, solver)
            # Calculate TCRDD
            tcrdd_slack_lo = f_TCRDD(sys, res_lo; dual_lines_tol, dual_gen_tol)
            # Evaluate Profit
            (profit_argmax_lo, bid_argmax_lo) = bid_argmax_profit(
                sys,
                res_lo,
                BaseMVA,
                lmp_lo,
                tcrdd_slack_lo,
                bid_lo,
                Pmin_orig,
                Pmax_orig;
                segm_bid_argmax_profit,
                print_plots
                )

            # Calculations when bid = bid_hi
            # Change active power Limits to Bidmin = Pmin_orig Bidmax = bid_hi
            set_active_power_limits!(gen_thermal_slack, (min = Pmin_orig, max = bid_hi))
            # Solve PTDF OPF
            (lmp_hi, res_hi) = opf_PTDF(sys; network, solver)
            # Calculate TCRDD
            tcrdd_slack_hi = f_TCRDD(sys, res_hi; dual_lines_tol, dual_gen_tol)
            # Evaluate Profit
            (profit_argmax_hi, bid_argmax_hi) = bid_argmax_profit(
                sys,
                res_hi,
                BaseMVA,
                lmp_hi,
                tcrdd_slack_hi,
                bid_hi,
                Pmin_orig,
                Pmax_orig;
                segm_bid_argmax_profit,
                print_plots
                )

            # Check if the inverse tangent of the RDC is the same for both functions
            comparison_res = compare_tan_inv_RDC(
                sys,
                BaseMVA,
                res_lo,
                res_hi,
                lmp_lo,
                lmp_hi,
                tcrdd_slack_lo,
                tcrdd_slack_hi,
                bid_lo,
                bid_hi,
                Pmin_orig,
                Pmax_orig;
                segm_bid_argmax_profit,
                epsilon,
                print_plots
                )
            # Unpack the results of the comparison
            (same_tan_inv_lo_hi, intersect_tan_inv_lo_hi, bid_intersect) = comparison_res

            # ----------Find bid_mid depending on the the case----------
            if same_tan_inv_lo_hi
                #tan_inv_RDC is the same for both hi and lo
                bid_mid = bid_argmax_lo
            elseif !intersect_tan_inv_lo_hi ||
                    ( intersect_tan_inv_lo_hi &&
                        (bid_intersect < bid_lo || bid_hi < bid_intersect) )
                #they dont intersect or intersect out of range, do traditional bisection
                bid_mid = 0.5*(bid_hi + bid_lo)
            else
                #Functions are different but they intersect within range
                #-----Determine profit maximiser range (Table 1 of reference [1])-----
                #Check where is the hump
                belong_bid_lo_intsct = false
                belong_bid_hi_intsct = false
                if (bid_lo <= bid_argmax_lo && bid_argmax_lo <= bid_intersect)
                    belong_bid_lo_intsct = true
                end
                if (bid_intersect <= bid_argmax_hi && bid_argmax_hi <= bid_hi)
                    belong_bid_hi_intsct = true
                end
                #Select bid_mid
                if !belong_bid_lo_intsct && !belong_bid_hi_intsct #no hump
                    bid_mid = bid_intersect
                elseif belong_bid_lo_intsct && !belong_bid_hi_intsct #left hump
                    bid_mid = bid_argmax_lo
                elseif !belong_bid_lo_intsct && belong_bid_hi_intsct #right hump
                    bid_mid = bid_argmax_hi
                elseif belong_bid_lo_intsct && belong_bid_hi_intsct #double hump
                    #Select the side based on profit_argmax
                    if profit_argmax_hi >= profit_argmax_lo
                        bid_mid = bid_argmax_hi
                    else
                        bid_mid = bid_argmax_lo
                    end
                end
            end
        end
        # Step 3 BL
        # Calculations when bid = bid_mid
        # Change active power Limits to Bidmin = Pmin_orig Bidmax = bid_mid
        set_active_power_limits!(gen_thermal_slack, (min = Pmin_orig, max = bid_mid))
        # Solve PTDF OPF
        (lmp_mid, res_mid) = opf_PTDF(sys; network, solver)
        # Calculate TCRDD
        tcrdd_slack_mid = f_TCRDD(sys, res_mid; dual_lines_tol, dual_gen_tol)
        # Evaluate Profit
        (profit_argmax_mid, bid_argmax_mid) = bid_argmax_profit(
            sys,
            res_mid,
            BaseMVA,
            lmp_mid,
            tcrdd_slack_mid,
            bid_mid,
            Pmin_orig,
            Pmax_orig;
            segm_bid_argmax_profit,
            print_plots
            )

        if intersect_tan_inv_lo_hi
            # Calculations when bid = bid_intersect
            # Change active power Limits to Bidmin = Pmin_orig Bidmax = bid_intersect
            set_active_power_limits!(
                gen_thermal_slack,
                (min = Pmin_orig, max = bid_intersect)
                )
            # Solve PTDF OPF
            (lmp_intersect, res_intersect) = opf_PTDF(sys; network, solver)
        end

        # Step 4 BL
        if bid_argmax_mid == bid_mid
            bid_opt_found = true
            bid_opt = bid_mid
            println("Local optimum found in", bid_opt)
            stop = true
            break
        # Step 5 BL
        elseif intersect_tan_inv_lo_hi && (bid_mid == bid_intersect) &&
            (lmp_mid == lmp_intersect)
            # Do an Incremental test
            if tcrdd_slack_mid == tcrdd_slack_lo
                bid_int_epsil = bid_intersect + epsilon
                # Calculations when bid = bid_int_epsil
                # Change active power Limits to Bidmin = Pmin_orig Bidmax = bid_int_epsil
                set_active_power_limits!(
                    gen_thermal_slack,
                    (min = Pmin_orig, max = bid_int_epsil)
                    )
                # Solve PTDF OPF
                (lmp_int_epsil, res_int_epsil) = opf_PTDF(sys; network, solver)
                # Calculate TCRDD
                tcrdd_slack_int_epsil = f_TCRDD(
                    sys,
                    res_int_epsil;
                    dual_lines_tol,
                    dual_gen_tol
                    )
                # Evaluate Profit
                (profit_argmax_int_epsil, bid_argmax_int_epsil) = bid_argmax_profit(
                    sys,
                    res_int_epsil,
                    BaseMVA,
                    lmp_int_epsil,
                    tcrdd_slack_int_epsil,
                    bid_int_epsil,
                    Pmin_orig,
                    Pmax_orig;
                    segm_bid_argmax_profit,
                    print_plots
                    )
                if bid_argmax_int_epsil <= bid_int_epsil
                    bid_opt_found = true
                    bid_opt = bid_intersect
                    println("Local optimum found in", bid_opt)
                    stop = true
                    break
                end
            elseif tcrdd_slack_mid == tcrdd_slack_hi
                bid_int_epsil = bid_intersect - epsilon
                # Calculations when bid = bid_int_epsil
                # Change active power Limits to Bidmin = Pmin_orig Bidmax = bid_int_epsil
                set_active_power_limits!(
                    gen_thermal_slack,
                    (min = Pmin_orig, max = bid_int_epsil)
                    )
                # Solve PTDF OPF
                (lmp_int_epsil, res_int_epsil) = opf_PTDF(sys; network, solver)
                # Calculate TCRDD
                tcrdd_slack_int_epsil = f_TCRDD(
                    sys,
                    res_int_epsil;
                    dual_lines_tol,
                    dual_gen_tol
                    )
                # Evaluate Profit
                (profit_argmax_int_epsil, bid_argmax_int_epsil) = bid_argmax_profit(
                    sys,
                    res_int_epsil,
                    BaseMVA,
                    lmp_int_epsil,
                    tcrdd_slack_int_epsil,
                    bid_int_epsil,
                    Pmin_orig,
                    Pmax_orig;
                    segm_bid_argmax_profit,
                    print_plots
                    )
                if bid_argmax_int_epsil >= bid_int_epsil
                    bid_opt_found = true
                    bid_opt = bid_intersect
                    println("Local optimum found in", bid_opt)
                    stop = true
                    break
                end
            end
        end
        # Step 6 BL
        #Traditional Bisection
        if bid_mid < bid_argmax_mid
            bid_lo = bid_mid
            # bid_hi remains the same
        else # bid_argmax_mid < bid_mid
            bid_hi = bid_mid
            # bid_lo remains the same
        end

        if print_progress
            a=println("Bisection Loop iter: ", iter_bi)
            b=println("Optimal bid found: ", bid_opt_found)
            c=println("Stop Flag: ", stop)
            d=println("Bidmid: ", bid_mid)
            e=println("Optimal Bid Value: ", bid_opt)
            f=println("Local optimum exists in: [ ",bid_lo," , ",bid_hi," ]")
            g=println("LMP aprox Intersect Flag: ", intersect_tan_inv_lo_hi)
            h=println("Bid Intersect: ", bid_intersect)
        end
    end

    return(stop, iter_bi, bid_opt_found, bid_opt, bid_mid)
end
