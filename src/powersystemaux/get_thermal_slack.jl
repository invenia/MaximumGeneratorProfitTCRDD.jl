"""
    function get_thermal_slack(sys::System)

Gets the slack generator from a system and returns the generator, location in the vector
of generators, and name.

# Arguments
- `Name`:                                   Description
-------------------------------------------------------------------------------------------
- `sys::System`:                            Power system in p.u. (from PowerSystems.jl)

# Throws
- `Name`:                                   Description
-------------------------------------------------------------------------------------------
- `NotFoundError`:                          No Slack bus found in the system
"""
function get_thermal_slack(sys::System)
    # ----------Define elements----------
    gen_loc = 0
    ngen_slack = 0 #number of gen slacks
    has_slack = false
    gen_thermal_slack = 0
    gen_thermal_slack_loc = 0
    gen_thermal_slack_name = "Empty"

    # ----------Get all thermal Generators----------
    gens_thermal = get_components(ThermalStandard, sys)

    # ----------Identify Slack Generator and save its information----------
    for gen_thermal in gens_thermal
        gen_loc = gen_loc +1
        if get_bustype(gen_thermal.bus)== BusTypes.REF
            has_slack = true
            gen_thermal_slack = gen_thermal
            gen_thermal_slack_loc = gen_loc
            gen_thermal_slack_name = gen_thermal.name
        end
    end
    if !has_slack
        error("NotFoundError: No Slack found in the system")
    end
    # ----------Get the Slack Generator----------
    gen_thermal_slack = get_component(ThermalStandard,sys,gen_thermal_slack_name)

    return (gen_thermal_slack,gen_thermal_slack_loc,gen_thermal_slack_name)
end
