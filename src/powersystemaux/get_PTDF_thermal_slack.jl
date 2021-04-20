"""
    function get_PTDF_thermal_slack(sys::System, PTDF_matrix ::Any)

Get Slack Generator, locate its bus and return the corresponding PTDF matrix

# Arguments
- `Name`:                                   Description
-------------------------------------------------------------------------------------------
- `sys::System`:                            Power system in p.u. (from PowerSystems.jl)
- `PTDF_matrix::Any`:                       PTDF matrix as a direct output from
                                            PTDF_matrix = PTDF(sys), see PowerSystems.jl

# Throws
- `Name`:                                   Description
-------------------------------------------------------------------------------------------
- `ERROR`:                                  PTDF_matrix has no field data. The argument must
                                            be a direct output from PTDF_matrix = PTDF(sys)
                                            see PowerSystems.jl

"""
function get_PTDF_thermal_slack(sys::System, PTDF_matrix::Any)
    # Get Slack Generator
    gslack = get_thermal_slack(sys)
    (gen_thermal_slack,gen_thermal_slack_loc,gen_thermal_slack_name) = gslack
    # Save slack bus number
    gen_thermal_slack_busnumber = gen_thermal_slack.bus.number
    # Parse the PTDF matrix to only have the slack bus
    PTDF_slack = PTDF_matrix[:,gen_thermal_slack_busnumber]

    return (gen_thermal_slack_busnumber, PTDF_slack)
end
