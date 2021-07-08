"""
    function residual_demand_virt!(
        sys::System,
        res::PowerSimulations.OperationsProblemResults,
        gen_virt_names,
        residualD_virt,
        iter_opf
    )

Calculates the residual demand of the virtual generators for a solved OPF case. The residual
demand is defined as the remaining demand to be satisfied by the sender generator while
knowing the power output of all the other generators [1]. It can be calculated as:

    residual = sum{Load[i], i in all nodes} - sum{Pg[j], j in all gens, j ≠ sender}

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
function residual_demand_virt!(
    sys::System,
    res::PowerSimulations.OperationsProblemResults,
    gen_virt_names::Array{String},
    residualD_virt::Matrix{Float64},
    iter_opf::Int64
    )

    # Define elements
    allPg_but_s = zeros(length(gen_virt_names))

    # Get all thermal generators
    gens_thermal = get_components(ThermalStandard, sys)
    all_PGenThermal = get_variables(res)[:P__ThermalStandard] #Optimised PGen

    # Save the active power output of all gens but the sender
    for (i, gen_virt_name) in enumerate(gen_virt_names)
        for gen_thermal in gens_thermal
            if get_name(gen_thermal) ≠ gen_virt_name
                allPg_but_s[i] = allPg_but_s[i] + all_PGenThermal[1, get_name(gen_thermal)]
            end
        end
    end

    # Get all loads of the system
    loads = get_components(PowerLoad, sys)
    # Calculate total active power load of the system
    total_Pload = 0.0
    for load in loads
        total_Pload = total_Pload + load.active_power
    end

    # Calculate the residual demand for the slack generator
    residualD_virt_tot = 0
    for (i, gen_virt_name) in enumerate(gen_virt_names)
        residualD_virt[iter_opf, i] = total_Pload - allPg_but_s[i]
        residualD_virt_tot = residualD_virt_tot + residualD_virt[iter_opf, i]
    end

    return residualD_virt, residualD_virt_tot
end
