function get_PTDF_thermal_slack(sys::System, PTDF_matrix ::Any)
    #Get Slack Generator, locate its bus and return corresponding PTDF matrix
    gen_slack = 0
    gens_thermal_slack_name = Array{String}(undef,0)
    gen_thermal_slack_busnumber = Array{Int64}(undef,0)
    gens_thermal = get_components(ThermalStandard, sys)
    for gen_thermal in gens_thermal
        if get_bustype(gen_thermal.bus)== BusTypes.REF
            gen_slack = gen_slack + 1
            resize!(gens_thermal_slack_name, gen_slack)
            resize!(gen_thermal_slack_busnumber,gen_slack)
            gens_thermal_slack_name[gen_slack] = gen_thermal.name
            gen_thermal_slack_busnumber[gen_slack] = gen_thermal.bus.number
        end
    end
    PTDF_slack = PTDF_matrix[:,gen_thermal_slack_busnumber]
    return (gen_thermal_slack_busnumber, PTDF_slack)
end