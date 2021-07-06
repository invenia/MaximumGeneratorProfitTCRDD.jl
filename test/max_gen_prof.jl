@testset "Maximum Gen Profit function" begin
    sys = c_sys_case4()
    bid0 = 0.3
    @test maxGenProfit_tcrdd(sys, bid0) == (true, 0.60892, 0.3, 1.0, 1, 1)
end
