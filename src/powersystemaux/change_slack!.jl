function change_slack!(sys::System, new_slack_busname::String)
    #This function changes the current slack bus from the system data to the new slack bus and returns the modified system
    #Inputs
    #sys = System Data 
    #new_slack_busname = Name of the bus to be new slack/"REF"
    #Outputs
    #sys = Modified system with new slack

    #Example:
    #sys=change_slack!(sys,"Bus 1")

    #Get components of the Bus
    buses = get_components(Bus, sys)
    has_slack = false
    for bus in buses
        if get_bustype(bus) == BusTypes.REF
            has_slack = true
            set_bustype!(bus, BusTypes.PV)
        end
    end
    
    #Assign the new slack bus
    new_slack_bus = get_component(Bus, sys, new_slack_busname)
    set_bustype!(new_slack_bus, "REF")

    #Warns if there was no slack bus in the original system
    if !has_slack
        @warn "There was no slack bus in the original system, however your selected slack has been assigned"
    end

    #Return the system
    return(sys)
end