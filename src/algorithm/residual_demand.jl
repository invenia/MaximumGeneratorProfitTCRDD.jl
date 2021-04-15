function residual_demand(sys::System, res::PowerSimulations.OperationsProblemResults)
    #Calculate residual demand for a solved OPF case 
    allPg_butslack = 0
    gens_thermal = get_components(ThermalStandard, sys)
    all_PGenThermal = get_variables(res)[:P__ThermalStandard] #Optimised PGen
    for gen_thermal in gens_thermal
        if get_bustype(gen_thermal.bus) ≠ BusTypes.REF
            allPg_butslack = allPg_butslack + all_PGenThermal[1,gen_thermal.name]
        end
    end
    total_Pload = 0.0
    loads = get_components(PowerLoad,sys);
    for load in loads
        total_Pload = total_Pload + load.active_power
    end
    residual_slack = total_Pload - allPg_butslack
    return (residual_slack)
end
