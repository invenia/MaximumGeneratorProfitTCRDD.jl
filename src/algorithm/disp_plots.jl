"""
    function disp_plots(args...; kwargs)

This function plots the output results from "plots_TCRDD.jl"

#Arguments
- `bids::Array{Float64, 1}`                     Bids
- `gen_profit::Array{Float64, 1}`               Generator Profit
- `gen_profit_tcrdd::Array{Float64, 1}`         Approximated Generator Profit
- `gen_profit_noCost::Array{Float64, 1}`        Generator Profit no Cost
- `gen_profit_tcrdd_noCost::Array{Float64, 1}`  Approximated Generator Profit no Cost
- `gen_cost_slack::Array{Float64, 1}`           Slack Generator Cost
- `Pg_slack::Array{Float64, 1}`                 Slack Generator Active Power Output
- `lmp_slack::Array{Float64, 1}`                Slack Bus LMP
- `lmp_slack_apx_tcrdd::Array{Float64, 1}`      Slack Bus Approximated LMP
- `residualD_slack_Pg::Array{Float64, 1}`       Slack Generator Residual Demand
- `tcrdd::Array{Float64, 1}`                    Transmission Constrained Residual Demand
- `nbind_lines::Array{Int64, 1}`                Number of binding lines
- `div::Int64`                                  Number of divisions for the samples


#Keywords
- `examplecase4::Bool = false`                  If Case 4 example, provide an extra plot
- `branch1_3::Array{Float64, 1}`                Active Power Flow for Branch (Bus1 to Bus3)

"""
function disp_plots(
    bids::Array{Float64, 1},
    gen_profit::Array{Float64, 1},
    gen_profit_tcrdd::Array{Float64, 1},
    gen_profit_noCost::Array{Float64, 1},
    gen_profit_tcrdd_noCost::Array{Float64, 1},
    gen_cost_slack::Array{Float64, 1},
    Pg_slack::Array{Float64, 1},
    lmp_slack::Array{Float64, 1},
    lmp_slack_apx_tcrdd::Array{Float64, 1},
    residualD_slack_Pg::Array{Float64, 1},
    tcrdd::Array{Float64, 1},
    nbind_lines::Array{Int64, 1},
    div::Int64;
    examplecase4::Bool = false,
    branch1_3::Array{Float64, 1}
    )
    # Plot using Plotly
    plotly()

    # Slack Generator Profit
    gen_profit_both = Array{Float64}(undef, (div + 1, 2));
    gen_profit_both[:, 1] = gen_profit;
    gen_profit_both[:, 2] = gen_profit_tcrdd;
    plot(bids, gen_profit_both , title = "Generator Profit",
        label = ["Profit Function Real" "Profit Function Aprox TCRDD"], legend = :topleft);
    xlabel!("Bid q(pu)");
    a = ylabel!("profit(\$/hr)")
    display(a)

    # Slack Generator Profit No Cost
    gen_profit_both_noCost = Array{Float64}(undef, (div + 1, 2));
    gen_profit_both_noCost[:, 1] = gen_profit_noCost;
    gen_profit_both_noCost[:, 2] = gen_profit_tcrdd_noCost;
    plot(bids, gen_profit_both_noCost , title = "Generator Profit no Cost",
        label = ["Profit Function Real_noCost" "Profit Function Aprox TCRDD_noCost"],
        legend = :bottomright);
    xlabel!("Bid q(pu)");
    a = ylabel!("profit(\$/hr)")
    display(a)

    # Slack Generator Cost
    plot(bids, gen_cost_slack, title = "Generator Cost",
        label = ["Cost Function Real" "Cost Function TCRDD"], legend = :bottomright);
    xlabel!("Bid q(pu)");
    a = ylabel!("Cost(\$/hr)")
    display(a)

    # Slack Generator Active Power Output
    plot(bids, Pg_slack, title = "Dispatched vs Bid on Slack",
        label = ["Dispatched vs Bid Slack"], legend = :bottomright);
    xlabel!("Bid q(pu)");
    a = ylabel!("P Gen (pu)")
    display(a)

    # Slack Bus LMP
    lmp_both = Array{Float64}(undef,(div + 1, 2));
    lmp_both[:, 1] = lmp_slack;
    lmp_both[:, 2] = lmp_slack_apx_tcrdd;
    plot(bids, lmp_both, title = "LMPs of slack vs bids",
        label = ["LMP Real" "LMP approx TCRDD"], legend = :topright);
    xlabel!("Bid q(pu)");
    a = ylabel!("LMP (\$/hrpu)")
    display(a)

    # Residual Demand Curve
    plot(bids, residualD_slack_Pg, title = " Residual Demand Curve vs Bids",
        label = ["RDC"], legend = :topright);
    xlabel!("Bid q(pu)");
    a = ylabel!("RDC (pu)")
    display(a)

    # TCRDD
    plot(bids, tcrdd ,title = "TCRDD vs bids",
        label = ["TCRDD vs Bid Slack"], legend = :bottomright);
    xlabel!("Bid q(pu)");
    a = ylabel!("TCRDD (pu)")
    display(a)

    # RDC & TCRDD vs Bid
    rdc_tcrdd = Array{Float64}(undef,(div + 1, 2));
    rdc_tcrdd[:, 1] = residualD_slack_Pg;
    rdc_tcrdd[:, 2] = tcrdd;
    plot(bids, rdc_tcrdd, title = "RDC & TCRDD vs Bid",
        label = ["RDC" "TCRDD"], legend = :topright);
    xlabel!("Bid q(pu)");
    a = ylabel!("RDC & TCRDD")
    display(a)

    # Residual Demand Curve vs LMP
    plot(lmp_slack, residualD_slack_Pg, title = " Residual Demand Curve vs LMP",
        label = ["RDC"], legend = :topright);
    xlabel!("LMP (\$/hrpu)");
    a = ylabel!("RDC (pu)")
    display(a)

    # TCRDD vs LMP Slack
    plot(lmp_slack, tcrdd, title = "TCRDD vs LMP", label = ["TCRDD vs LMP Slack"],
        legend = :bottomright);
    xlabel!("LMP (\$/hrpu)");
    a = ylabel!("TCRDD (pu)")
    display(a)


    # RDC & TCRDD vs LMP Slack
    rdc_tcrdd = Array{Float64}(undef,(div + 1, 2));
    rdc_tcrdd[:, 1] = residualD_slack_Pg;
    rdc_tcrdd[:, 2] = tcrdd;
    plot(lmp_slack, rdc_tcrdd, title = "RDC & TCRDD vs LMP",
        label = ["RDC" "TCRDD"], legend = :topright);
    xlabel!("LMP (\$/hrpu)");
    a = ylabel!("RDC & TCRDD")
    display(a)

    # Number of Binding lines
    plot(bids, nbind_lines, title = "Number of Binding lines", label = ["Binding Lines"],
        legend = :bottomright);
    xlabel!("Bid q(pu)");
    a = ylabel!("Number binding lines")
    display(a)

    if examplecase4
        # Only for example case4 Pf branch Bus1 to Bus3
        plot(bids, branch1_3, title = "Pf branch Bus1 to Bus3",
            label = ["Pf line 1 to 3"], legend = :bottomright);
        xlabel!("Bid q(pu)");
        a = ylabel!("Active Power Flow Pf (pu)")
        display(a)
    end
end
