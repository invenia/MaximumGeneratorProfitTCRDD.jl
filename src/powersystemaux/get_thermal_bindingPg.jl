"""
    function get_thermal_bindingPg(args... ;kwargs...)

Identify generators which Active Power is binding (Skips Slack), returns the generators,
location in the vector of generators, and name.

# Arguments
- `sys::System`:                            Power system in p.u. (from PowerSystems.jl)
- `res::PowerSimulations.
    OperationsProblemResults`:              Results of the solved OPF for the system
                                             (from PowerSimulations.jl)

# Keywords
- `dual_gen_tol::Float64 = 1e-1`:           Tolerance to identify any binding generators

"""
function get_thermal_bindingPg(
    sys::System,
    res::PowerSimulations.OperationsProblemResults;
    dual_gen_tol::Float64
    )

    # Define elements
    gen_loc = 0
    gen_bindPg = 0 #number of gen binding (start of counter)
    gens_thermal_bindPg = Array{ThermalStandard}(undef, 0)
    gens_thermal_bindPg_id = Array{Int64}(undef, 0)
    gens_thermal_bindPg_name = Array{String}(undef, 0)

    # Get all thermal Generators
    gens_thermal = get_components(ThermalStandard, sys)

    # Get dual variables from the OPF results
    dualPgub = get_duals(res)[:P_ub__ThermalStandard__RangeConstraint]
    dualPglb = get_duals(res)[:P_lb__ThermalStandard__RangeConstraint]

    # Identify Generators and save their information
    for gen_thermal in gens_thermal
        gen_loc = gen_loc +1
        if get_bustype(gen_thermal.bus) ≠ BusTypes.REF  #skips slack
            bindub = !isapprox(dualPgub[1,gen_loc], 0.0; atol = dual_gen_tol) #is binding?
            bindlb = !isapprox(dualPglb[1,gen_loc], 0.0; atol = dual_gen_tol) #is binding?
            if  bindub || bindlb #if binding dual is !≈  0.0 then
                gen_bindPg = gen_bindPg +1
                resize!(gens_thermal_bindPg, gen_bindPg)
                resize!(gens_thermal_bindPg_id, gen_bindPg)
                resize!(gens_thermal_bindPg_name, gen_bindPg)
                gens_thermal_bindPg[gen_bindPg] =
                    get_component(ThermalStandard, sys, gen_thermal.name)
                gens_thermal_bindPg_id[gen_bindPg] = gen_loc
                gens_thermal_bindPg_name[gen_bindPg] = gen_thermal.name
            end
        end
    end

    return gens_thermal_bindPg, gens_thermal_bindPg_id, gens_thermal_bindPg_name
end
