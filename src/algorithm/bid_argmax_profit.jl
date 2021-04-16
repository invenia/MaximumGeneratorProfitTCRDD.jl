"""
    function bid_argmax_profit(args...; kwargs)

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
- `Name`:                                   Description
-------------------------------------------------------------------------------------------
- `sys::System`:                            Power system in p.u. (from PowerSystems.jl)
- `BaseMVA::Float64`:                       Apparent Power Base for the system [MVA]
- `lmp::DataFrame`:                         LMP of all buses of the system
- `tcrdd_slack::Float64`:                   TCRDD [pu]
- `bid::Float64`:                           Bid for the slack generator [pu]
- `Pmin_orig::Float64`:                     Active power minimum limit [pu]
- `Pmax_orig::Float64`:                     Active power maximum limit [pu]

# Keywords
- `Name`:                                   Description
-------------------------------------------------------------------------------------------
- `segm_bid_argmax_profit::Int64 = 50000:   Segments to evaluate the approx profit function
- `print_plots::Bool = true`:               Flag to print plots

# Throws
- `Name`:                                   Description
-------------------------------------------------------------------------------------------
- `NotFoundError`:                          No Slack bus found in the system
"""
function bid_argmax_profit(
    sys::System,
    BaseMVA::Float64 ,
    lmp::DataFrame,
    tcrdd_slack::Float64,
    bid::Float64,
    Pmin_orig::Float64,
    Pmax_orig::Float64;
    segm_bid_argmax_profit::Int64 = 50000,
    print_plots::Bool = true
    )
    #Calculate the bid with argmax in a function that gets evaluated.
    #------------------------------
    bus_slack_name = "Empty"
    has_slack = false
    #Find slackbus
    buses = get_components(Bus, sys)
    for bus in buses
        if get_bustype(bus) == BusTypes.REF
            has_slack = true
            bus_slack_name = bus.name
        end
    end
    #storage the lmp of the slack bus
    if has_slack
        lmp_slack = lmp[1,bus_slack_name]
    else
        error("NotFoundError: No Slack found in the system")
    end

    #Get Slack Generator component ,ID and name
    (gen_thermal_slack,gen_thermal_slack_id,gen_thermal_slack_name)=get_thermal_slack(sys);

    #Get Slack Generator Costs gen_cost = αPg² + βPg + γ
    (α, β) = get_cost(get_variable(get_operation_cost(gen_thermal_slack)))
    γ = get_fixed(get_operation_cost(gen_thermal_slack))

    #Correct tcrdd pu using the MVA base
    tcrdd_slack = tcrdd_slack/(BaseMVA^2)

    #Calculate profits for all segments of Pg using the tcrdd
    segment = 0
    bids = Array{Float64}(undef,segm_bid_argmax_profit+1);
    profits = Array{Float64}(undef,segm_bid_argmax_profit+1);
    step = (Pmax_orig-Pmin_orig)/segm_bid_argmax_profit;
    for Pg in Pmin_orig:step:Pmax_orig
        segment = segment + 1
        #calculate the lmp aproximation using tcrdd
        tan_inv_RDC = (((1/tcrdd_slack)*(Pg-bid)) + lmp_slack)
        gen_cost =  α*(Pg^2)*(BaseMVA^2) + β*Pg*BaseMVA + γ
        bids[segment] = Pg
        profits[segment] = (tan_inv_RDC*Pg - gen_cost)
    end
    if print_plots == true
        plotly()
        p=plot(bids, profits,title = "Approximated Profit function at bid0",
            label = ["Profit(bid, bid0"], legend = :bottomright);
        xlabel!("bids/Pg(pu)");
        ylabel!("Profit")
        display(p)
    end
    (profit_argmax, segment_profit_argmax) = findmax(profits)
    bid_argmax = bids[segment_profit_argmax]
    return (profit_argmax, bid_argmax)
end
