"""
    function change_slack!(sys::System, new_slack_busname::String)

This function changes the current slack bus from the system data to the new slack bus and
returns the modified system.

#Arguments
- `Name`:                                   Description
-------------------------------------------------------------------------------------------
- `sys::System`:                            Power system in p.u. (from PowerSystems.jl)
- `new_slack_busname::String`:              Name of the bus to be new slack/"REF

"""
function change_slack!(sys::System, new_slack_busname::String)
    # ----------Get buses----------
    buses = get_components(Bus, sys)

    # ----------Find current slack----------
    has_slack = false
    for bus in buses
        if get_bustype(bus) == BusTypes.REF
            has_slack = true
            set_bustype!(bus, BusTypes.PV)
        end
    end

    # ----------Assign the new slack bus----------
    new_slack_bus = get_component(Bus, sys, new_slack_busname)
    set_bustype!(new_slack_bus, "REF")

    # ----------Warns if there was no slack bus in the original system---------
    if !has_slack
        @warn "There was no slack bus in the original system,
            however your selected slack has been assigned"
    end

    return(sys)
end
