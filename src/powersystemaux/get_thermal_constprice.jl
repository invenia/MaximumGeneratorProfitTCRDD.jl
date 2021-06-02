"""
    function get_thermal_constprice(args...; kwargs...)

Identify generators which cost function is a constant price, locate their buses and returns
the generators, location in the vector of generators, and name. Skips Slack generators,
generators which Active Power is binding and generators with non zero slope. Note: For a
quadratic cost function of the form: αPg²+ βPg + γ, a constant price generator will have the
parameter α == 0.

# Arguments
- `Name`:                                   Description
-------------------------------------------------------------------------------------------
- `sys::System`:                            Power system in p.u. (from PowerSystems.jl)
- `res::PowerSimulations.
    OperationsProblemResults`:              Results of the solved OPF for the system
                                             (from PowerSimulations.jl)

# Keywords
- `Name`:                                   Description
-------------------------------------------------------------------------------------------
- `dual_gen_tol::Float64 = 1e-1`:           Tolerance to identify any binding generators
"""
function get_thermal_constprice(
    sys::System,
    res::PowerSimulations.OperationsProblemResults,
    dual_gen_tol::Float64
    )

    # ----------Define elements----------
    gen_loc = 0
    gen_bindPg = 0
    gen_constprice = 0
    gens_thermal_constantprice = Array{Any}(undef, 0)
    gens_thermal_constantprice_id = Array{Int64}(undef, 0)
    gens_thermal_constantprice_name = Array{String}(undef, 0)

    # ----------Get all thermal Generators----------
    gens_thermal = get_components(ThermalStandard, sys)

    # ----------Get dual variables from the OPF results----------
    dualPgub = get_duals(res)[:P_ub__ThermalStandard__RangeConstraint]
    dualPglb = get_duals(res)[:P_lb__ThermalStandard__RangeConstraint]

    # ----------Identify Generators and save their information----------
    for gen_thermal in gens_thermal
        gen_loc = gen_loc +1
        if get_bustype(gen_thermal.bus) ≠ BusTypes.REF  #skips slack
            bindub = !isapprox(dualPgub[1,gen_loc], 0.0; atol = dual_gen_tol) #is binding?
            bindlb = !isapprox(dualPglb[1,gen_loc], 0.0; atol = dual_gen_tol) #is binding?
            if !bindub && !bindlb #skips binding Pg gens Dual = 0
                (α, β) = get_cost(get_variable(get_operation_cost(gen_thermal)))
                γ = get_fixed(get_operation_cost(gen_thermal))
                if α == 0 && (β ≠ 0 || γ ≠ 0)#skips non zero slope
                    gen_constprice = gen_constprice +1
                    resize!(gens_thermal_constantprice, gen_constprice)
                    resize!(gens_thermal_constantprice_id, gen_constprice)
                    resize!(gens_thermal_constantprice_name, gen_constprice)
                    gens_thermal_constantprice[gen_constprice] =
                        get_component(ThermalStandard, sys, gen_thermal.name)
                    gens_thermal_constantprice_id[gen_constprice] = gen_loc
                    gens_thermal_constantprice_name[gen_constprice] = gen_thermal.name
                end
            end
        end
    end

    return (
        gens_thermal_constantprice,
        gens_thermal_constantprice_id,
        gens_thermal_constantprice_name
        )
end
