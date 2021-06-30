"""
    function get_PTDF_thermal_bindingPg(args... ;kwargs...)

Identify generators which Active Power is binding (Skips Slack), locate their buses and
return the corresponding PTDF matrix

# Arguments
- `sys::System`:                            Power system in p.u. (from PowerSystems.jl)
- `res::PowerSimulations.
    OperationsProblemResults`:              Results of the solved OPF for the system
                                             (from PowerSimulations.jl)
- `PTDF_matrix::Any`:                       PTDF matrix as a direct output from
                                            PTDF_matrix = PTDF(sys), see PowerSystems.jl

# Keywords
- `dual_gen_tol::Float64 = 1e-1`:           Tolerance to identify any binding generators

# Throws
- `ERROR`:                                  PTDF_matrix has no field data. The argument must
                                            be a direct output from PTDF_matrix = PTDF(sys)
                                            see PowerSystems.jl
"""
function get_PTDF_thermal_bindingPg(
    sys::System,
    res::PowerSimulations.OperationsProblemResults,
    PTDF_matrix ::Array;
    dual_gen_tol::Float64 = 1e-1
    )
    # Define elements
    gen_loc = 0
    gen_bindPg = 0 #number of gen binding (start of counter)
    gens_thermal_bindPg_busnumber = Array{Int64}(undef,0)
    gens_thermal_bindPg_name = Array{String}(undef,0)
    (nl,nb)=size(PTDF_matrix)
    PTDF_bindingPg = Array{Float64}(undef,(nl,0))

    # Get all thermal Generators
    gens_thermal = get_components(ThermalStandard, sys)

    # Get dual variables from the OPF results
    dualPgub = get_duals(res)[:P_ub__ThermalStandard__RangeConstraint]
    dualPglb = get_duals(res)[:P_lb__ThermalStandard__RangeConstraint]

    # Identify Generators and Locate their Buses
    for gen_thermal in gens_thermal
        gen_loc = gen_loc +1
        if get_bustype(gen_thermal.bus) ≠ BusTypes.REF  #skips slack
            bindub = !isapprox(dualPgub[1,gen_loc],0.0; atol = dual_gen_tol) #is binding?
            bindlb = !isapprox(dualPglb[1,gen_loc],0.0; atol = dual_gen_tol) #is binding?
            if  bindub || bindlb #if binding dual is !≈  0.0 then
                gen_bindPg = gen_bindPg +1
                resize!(gens_thermal_bindPg_name,gen_bindPg)
                resize!(gens_thermal_bindPg_busnumber,gen_bindPg)
                gens_thermal_bindPg_name[gen_bindPg] = gen_thermal.name
                gens_thermal_bindPg_busnumber[gen_bindPg] = gen_thermal.bus.number
            end
        end
    end

    # Parse the PTDF matrix
    if gens_thermal_bindPg_busnumber == Any[]
        PTDF_bindingPg = Array{Float64}(undef,(nl,0))
    else
        sort!(gens_thermal_bindPg_busnumber)
        PTDF_bindingPg = PTDF_matrix[:,gens_thermal_bindPg_busnumber]
    end

    return gens_thermal_bindPg_busnumber, PTDF_bindingPg
end
