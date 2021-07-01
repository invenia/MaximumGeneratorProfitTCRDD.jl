"""
    function compare_tan_inv_RDC(args...; kwargs)

Compare the inverse tangent of the residual demand curve functions for both bid boundaries
(Lower bid "bid_lo" and higher bid "bid_hi"). Then it returns if the functions are the same,
if they intersect, and if yes, the point where they intersect. The comparison is done by
evaluating both functions from the Slack generator minimum active power (Pmin) to the
maximum active power (Pmax) according to its operational limits. The functions work as an
approximation of the LMP for a certain range, and they are calculated using the Transmission
Constrained Residual Demand Derivative (TCRDD) [1].

[1] L. Xu, R. Baldick and Y. Sutjandra, "Bidding Into Electricity Markets:
    A Transmission-Constrained Residual Demand Derivative Approach," in IEEE
    Transactions on Power Systems, vol. 26, no. 3, pp. 1380-1388, Aug. 2011,
    doi: 10.1109/TPWRS.2010.2083702.

# Arguments
- `sys::System`:                            Power system in p.u. (from PowerSystems.jl)
- `BaseMVA::Float64`:                       Apparent Power Base for the system [MVA]
- `lmp_lo::DataFrame`:                      LMP of all buses of the system (lower bid)
- `lmp_hi::DataFrame`:                      LMP of all buses of the system (higher bid)
- `tcrdd_slack_lo::Float64`:                TCRDD [pu]  (lower bid)
- `tcrdd_slack_hi::Float64`:                TCRDD [pu]  (higher bid)
- `bid_lo::Float64`:                        Lower Bid for the slack generator [pu]
- `bid_hi::Float64`:                        Higher Bid for the slack generator [pu]
- `Pmin_orig::Float64`:                     Active power minimum limit Slack gen [pu]
- `Pmax_orig::Float64`:                     Active power maximum limit Slack gen [pu]

# Keywords
- `segm_bid_argmax_profit::Int64 = 50000:   Segments to evaluate the approx profit function
- `epsilon::Float64 = 0.01`:                Tolerance to identify if they intersect and/or
                                             if they are the same function.
- `print_plots::Bool = true`:               Flag to print plots

# Throws
- `NotFoundError`:                          No Slack bus found in the system
"""
function compare_tan_inv_RDC(
    sys::System,
    BaseMVA::Float64,
    res_lo::PowerSimulations.OperationsProblemResults,
    res_hi::PowerSimulations.OperationsProblemResults,
    lmp_lo::DataFrame,
    lmp_hi::DataFrame,
    tcrdd_slack_lo::Float64,
    tcrdd_slack_hi::Float64,
    bid_lo::Float64,
    bid_hi::Float64,
    Pmin_orig::Float64,
    Pmax_orig::Float64;
    segm_bid_argmax_profit::Int64 = 50000,
    epsilon::Float64 = 0.01,
    print_plots::Bool = true
    )

    # Get slack bus
    bus_slack_name = "Empty"
    has_slack = false
    buses = get_components(Bus, sys)
    for bus in buses
        if get_bustype(bus) == BusTypes.REF
            has_slack = true
            bus_slack_name = bus.name
        end
    end

    # Storage the lmp of the slack bus
    if has_slack
        lmp_slack_lo = lmp_lo[1, bus_slack_name]
        lmp_slack_hi = lmp_hi[1, bus_slack_name]
    else
        error("NotFoundError: No Slack found in the system")
    end

    # Get Slack Generator component ,ID and name
    (gen_thermal_slack,gen_thermal_slack_id,gen_thermal_slack_name)=get_thermal_slack(sys)

    # Get Optimised Pg of slack lo and hi
    all_PGenThermal_lo = get_variables(res_lo)[:P__ThermalStandard] #Optimised PGen
    Pg_slack_lo = all_PGenThermal_lo[1, gen_thermal_slack_name]
    all_PGenThermal_hi = get_variables(res_hi)[:P__ThermalStandard] #Optimised PGen
    Pg_slack_hi = all_PGenThermal_hi[1, gen_thermal_slack_name]
    # Correct tcrdd pu using BaseMVA
    tcrdd_slack_hi = tcrdd_slack_hi/(BaseMVA^2)
    tcrdd_slack_lo = tcrdd_slack_lo/(BaseMVA^2)

    #----------Evaluate both functions for all segments of Pg using the tcrdd----------
    segment = 0
    segm_div = segm_bid_argmax_profit
    bids = Array{Float64}(undef,segm_div + 1)
    tan_inv_RDC_lo = Array{Float64}(undef, segm_div + 1)
    tan_inv_RDC_hi = Array{Float64}(undef, segm_div + 1)
    dif_tans = Array{Float64}(undef, segm_div+1)
    same_tan_inv_lo_hi_num = ones(segm_div + 1, 1) #false 0, true 1
    intersect_tan_inv_lo_hi_num = zeros(segm_div + 1, 1) #false 0, true 1
    step = (Pmax_orig - Pmin_orig)/segm_div

    for Pg in Pmin_orig:step:Pmax_orig
        segment = segment + 1
        tan_inv_RDC_lo[segment] = (((1/tcrdd_slack_lo)*(Pg-Pg_slack_lo)) + lmp_slack_lo)
        tan_inv_RDC_hi[segment] = (((1/tcrdd_slack_hi)*(Pg-Pg_slack_hi)) + lmp_slack_hi)
        bids[segment] = Pg
        dif_tans[segment] = abs(tan_inv_RDC_hi[segment] - tan_inv_RDC_lo[segment])
        # Same function? or #Intersect
        if dif_tans[segment] > (epsilon*BaseMVA)
            same_tan_inv_lo_hi_num[segment] = 0.0
        else
            intersect_tan_inv_lo_hi_num[segment] = 1.0
        end
    end

    # Flag if they are the same function
    if sum(same_tan_inv_lo_hi_num) == segm_div + 1.0
        same_tan_inv_lo_hi = true
    else
        same_tan_inv_lo_hi = false
    end

    # Flag if they intersect
    if sum(intersect_tan_inv_lo_hi_num) ≠ 0.0
        intersect_tan_inv_lo_hi = true
    else
        intersect_tan_inv_lo_hi = false
    end

    # Find where do they intersect if they do
    (int_flag, segm_intersect) = findmax(intersect_tan_inv_lo_hi_num)
    bid_intersect = bids[segm_intersect]

    # Plot both functions
    if print_plots == true
        tan_inv_RDC = Array{Float64}(undef,(segment,2))
        tan_inv_RDC[:, 1] = tan_inv_RDC_lo
        tan_inv_RDC[:, 2] = tan_inv_RDC_hi
        plotly()
        p=plot(bids,tan_inv_RDC, title = "bids vs lmp_aprox_TCRDD",
            label = ["lmp_apx_lo" "lmp_apx_hi"], legend = :bottomright);
        xlabel!("bids(pu)");
        ylabel!("lmp")
        display(p)
    end

    return same_tan_inv_lo_hi, intersect_tan_inv_lo_hi, bid_intersect
end
