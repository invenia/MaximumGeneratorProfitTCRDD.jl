"""
    function get_thermal_slack(sys::System)

Gets the Gen  

"""
function get_thermal_slack(sys::System)
    #Get Slack Generator 
    #gen_thermal_slack = get_components(ThermalGen, sys, x-> get_bustype(get_bus(x)) == BusTypes.REF)
    gen_loc = 0
    ngen_slack = 0 #number of gen slacks
    gen_thermal_slack = 0
    gen_thermal_slack_id = 0
    gen_thermal_slack_name = "Empty"
    gens_thermal = get_components(ThermalStandard, sys)
        for gen_thermal in gens_thermal
            gen_loc = gen_loc +1
            if get_bustype(gen_thermal.bus)== BusTypes.REF
            #println("I found the slack in ", gen_thermal.bus)
            #println("I found the slack in ", gen_thermal.name)
            gen_thermal_slack = gen_thermal
            gen_thermal_slack_id = gen_loc
            gen_thermal_slack_name = gen_thermal.name
            end
        end
    gen_thermal_slack = get_component(ThermalStandard,sys,gen_thermal_slack_name)
    return (gen_thermal_slack,gen_thermal_slack_id,gen_thermal_slack_name)
end