"""
    function bid_argmax_virt_profit(args...; kwargs)

Calculates the bid that returns the maximum profit of the slack bus based on an aproximation
of the profit function which is calculated using the Transmission Constrained Residual
Demand Derivative (TCRDD). A plot of this approximation can be displayed.

Detailed description: The algorithm considers the Locational Marginal Price (LMP) for a
determined bid in the slack generator which matches to a single point of the real profit
function. Then, using the TCRDD of that specific point, an approximation of the real profit
function is build. The function then evaluates the aproximated function from the minimum
active power (Pmin) to the maximum active power (Pmax) of the slack generator. The bid that
provides the maximum profit is returned.

# Arguments
- `sys::System`:                            Power system in p.u. (from PowerSystems.jl)
- `res::PowerSimulations.
    OperationsProblemResults`:              Results of the solved OPF for the system
                                             (from PowerSimulations.jl)
- `BaseMVA::Float64`:                       Apparent Power Base for the system [MVA]
- `lmp::DataFrame`:                         LMP of all buses of the system
- `tcrdd::Array{Float64, 1}`:               TCRDD [pu] for all Virtual Gens
- `weights::Array{Float64, 1}`:             weights for all Virtual Gens
- `bid0::Float64`:                          Bid for the Virtual Participant [pu]
- `bidMax::Float64`:                        Maximum Bid for the Virtual Participant [pu]
- `bidMin::Float64`:                        Minimum Bid for the Virtual Participant [pu]

# Keywords
- `segm_bid_argmax_profit::Int64 = 50000:   Segments to evaluate the approx profit function
- `print_plots::Bool = true`:               Flag to print plots

"""
function bid_argmax_virt_profit(
    sys::System,
    res::PowerSimulations.OperationsProblemResults,
    BaseMVA::Float64 ,
    lmp::DataFrame,
    tcrdd::Array{Float64, 1},
    weights::Array{Float64, 1},
    gen_virt_names::Array{String, 1},
    bid0::Float64,
    bidMax::Float64,
    bidMin::Float64;
    segm_bid_argmax_profit::Int64 = 50000,
    print_plots::Bool = true
    )

    # Get Optimised Pg of slack
    all_PGenThermal = get_variables(res)[:P__ThermalStandard] #Optimised PGen

    # Correct tcrdd pu using the MVA base
    tcrdd = tcrdd./(BaseMVA^2)

    # Calculate profits for all segments of Pg using the tcrdd
    segment = 0
    bids = Array{Float64}(undef,segm_bid_argmax_profit + 1)
    profits = Array{Float64}(undef,segm_bid_argmax_profit + 1)
    tan_inv_RDC = Array{Float64}(undef, length(gen_virt_names))
    gens_virt = Array{ThermalStandard}(undef, length(gen_virt_names))
    step = (bidMax-bidMin)/segm_bid_argmax_profit
    for bid in bidMin:step:bidMax
        segment = segment + 1
        bids[segment] = bid
        profits[segment] = 0
        for (i, gen_virt_name) in enumerate(gen_virt_names)
            bid_s = bid*weights[i]
            gens_virt[i] = get_component(ThermalStandard, sys, gen_virt_name)
            α, β = get_cost(get_variable(get_operation_cost(gens_virt[i])))
            γ = get_fixed(get_operation_cost(gens_virt[i]))
            gen_cost = α*(bid_s^2)*(BaseMVA^2) + β*bid_s*BaseMVA + γ
            Pg_s = all_PGenThermal[1, gen_virt_name]
            bus_s_name = get_name(get_bus(gens_virt[i]))
            lmp_s = lmp[1,bus_s_name]
            tan_inv_RDC[i] = (((1/tcrdd[i])*(bid_s-Pg_s)) + lmp_s)
            profits[segment] = profits[segment] + (tan_inv_RDC[i]*bid_s*BaseMVA - gen_cost)
        end
    end
    profit_argmax, segment_profit_argmax = findmax(profits)
    bid_argmax = bids[segment_profit_argmax]
    if print_plots == true
        plotly()
        p = plot(bids,
            profits,
            title = "Approximated Profit function at bid: $bid0",
            label = ["Profit(bid, $bid0"],
            legend = :bottomright,
            xlim = [0, bidMax],
            ylim = [0, profit_argmax]
        );
        xlabel!("bids/Pg(pu)");
        ylabel!("profit(\$/hr)")
        display(p)
    end

    return profit_argmax, bid_argmax
end
