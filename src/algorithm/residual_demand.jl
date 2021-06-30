"""
    function residual_demand(sys::System, res::PowerSimulations.OperationsProblemResults)

Calculates the residual demand of the slack generator for a solved OPF case. The residual
demand is defined as the remaining demand to be satisfied by the slack generator while
knowing the power output of all the other generators [1]. It can be calculated as:

    residual_slack = sum{Load[i], i in all nodes} - sum{Pg[j], j in all gens, j ≠ slack}

[1] J. Portela González, A. Muñoz San Roque, E. F. Sánchez-Úbeda, J. García-González and R.
    González Hombrados, "Residual Demand Curves for Modeling the Effect of Complex Offering
    Conditions on Day-Ahead Electricity Markets," in IEEE Transactions on Power Systems,
    vol. 32, no. 1, pp. 50-61, Jan. 2017, doi: 10.1109/TPWRS.2016.2552240.

#Arguments
- `sys::System`:                            Power system in p.u. (from PowerSystems.jl)
- `res::PowerSimulations.
    OperationsProblemResults`:              Results of the solved OPF for the system
                                             (from PowerSimulations.jl)

#Keywords
- `dual_lines_tol::Float64 = 1e-1`:         Tolerance to identify any binding lines
- `dual_gen_tol::Float64 = 1e-1`:           Tolerance to identify any binding generators

"""
function residual_demand(sys::System, res::PowerSimulations.OperationsProblemResults)

    # Define elements
    allPg_butslack = 0
    total_Pload = 0.0

    # Get all thermal generators
    gens_thermal = get_components(ThermalStandard, sys)
    all_PGenThermal = get_variables(res)[:P__ThermalStandard] #Optimised PGen

    # Get all loads of the system
    loads = get_components(PowerLoad,sys)

    # Save the active power output of all gens but the slack
    for gen_thermal in gens_thermal
        if get_bustype(gen_thermal.bus) ≠ BusTypes.REF
            allPg_butslack = allPg_butslack + all_PGenThermal[1, gen_thermal.name]
        end
    end

    # Calculate total active power load of the system
    for load in loads
        total_Pload = total_Pload + load.active_power
    end

    # Calculate the residual demand for the slack generator
    residual_slack = total_Pload - allPg_butslack

    return residual_slack
end
