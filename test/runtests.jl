using DataFrames
using Dates
using DataStructures
using Ipopt
using MaximumGeneratorProfitTCRDD
using PowerSystems
using PowerSimulations
using Test
using TimeSeries

#  Package Constants
const PSY = PowerSystems
const PSI = PowerSimulations

@testset "MaximumGeneratorProfitTCRDD.jl" begin
    # Settings for testset
    include("../examples/data/example_case4/buildup_case4.jl")
    include("../examples/data/example_case4/c_sys_case4.jl")
    include("max_gen_prof.jl")
end
