@testset "Maximum Virtual Profit function" begin
    sys_118 = c_sys_case118()
    #sys_4 = c_sys_case4()

    sys = deepcopy(sys_118)

    bid0 = 50.0
    bidMin = 0.0
    bidMax = 100.0
    sender_buses_names = [
        "Sporn     V2";
        "TannrsCk  V1";
        "ClinchRv  V2";
        "Breed     V1"
    ]
    weights = [
        0.50;
        0.25;
        0.15;
        0.10
    ]
    dual_lines_tol = 1e-1
    dual_gen_tol = 1e-1
    segm_bid_argmax_profit = 50000
    maxit_scr = 5
    maxit_bi = 30
    epsilon = 0.01
    print_results = true
    print_progress = false
    print_plots = false
    network = StandardPTDFModel
    solver = optimizer_with_attributes(Ipopt.Optimizer)

    MaximumGeneratorProfitTCRDD.maxVirtProfit_tcrdd(
        sys,
        bid0,
        bidMax,
        bidMin,
        sender_buses_names,
        weights
    )

    @test maxVirtProfit_tcrdd(
        sys,
        bid0,
        bidMax,
        bidMin,
        sender_buses_names,
        weights
    ) == (true, 0.60892, 0.3, 1.0, 1, 1)
end
