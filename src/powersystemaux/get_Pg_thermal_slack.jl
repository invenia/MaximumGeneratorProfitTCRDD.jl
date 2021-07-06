"""
    function get_Pg_thermal_slack(args ...)

Get Slack Generator, locate their buses and returns a matrix with their Name, Power output
and Bus number (sorted by Bus).


# Arguments
- `sys::System`:                            Power system in p.u. (from PowerSystems.jl)
- `res::PowerSimulations.
    OperationsProblemResults`:              Results of the solved OPF for the system
                                             (from PowerSimulations.jl)

"""
function get_Pg_thermal_slack(sys::System, res::PowerSimulations.OperationsProblemResults)

    # Define elements
    gen_loc = 0
    ngen_slack = 0 #number of gen slacks
    gen_thermal_slack_name = "Empty"
    gen_thermal_slack_busnumber = 0
    gens_thermal_slack_Pg = Array{Float64}(undef, 0)
    gens_thermal_slack_names = Array{String}(undef, 0)
    gens_thermal_slack_busnumbers = Array{Int64}(undef, 0)

    # Get all thermal Generators
    gens_thermal = get_components(ThermalStandard, sys)
    all_PGenThermal = get_variables(res)[:P__ThermalStandard] #Optimised PGen

    # Identify Slack Generators and save their information
    for gen_thermal in gens_thermal
        gen_loc = gen_loc +1
        if get_bustype(gen_thermal.bus)== BusTypes.REF
            ngen_slack = ngen_slack + 1;
            gen_thermal_slack_name = gen_thermal.name
            resize!(gens_thermal_slack_Pg, ngen_slack)
            resize!(gens_thermal_slack_names, ngen_slack)
            resize!(gens_thermal_slack_busnumbers, ngen_slack)
            gens_thermal_slack_Pg[ngen_slack] = all_PGenThermal[1, gen_thermal_slack_name]
            gens_thermal_slack_names[ngen_slack] = gen_thermal_slack_name
            gens_thermal_slack_busnumbers[ngen_slack] = gen_thermal.bus.number
        end
    end

    # Matrix of generators with their information sorted
    gens_thermal_slack_Matrix = Array{Any}(undef,(ngen_slack, 3))
    gens_thermal_slack_Matrix[:, 1] = gens_thermal_slack_names
    gens_thermal_slack_Matrix[:, 2] = gens_thermal_slack_Pg
    gens_thermal_slack_Matrix[:, 3] = gens_thermal_slack_busnumbers
    # sort by bus to match with PTDF structure
    gens_thermal_slack_Matrix[sortperm(gens_thermal_slack_Matrix[:, 3]), :]

    return gens_thermal_slack_Matrix
end
