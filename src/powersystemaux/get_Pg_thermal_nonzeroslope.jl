"""
    function get_Pg_thermal_nonzeroslope(args...; kargs...)

Identify generators which cost function has a non zero slope, locate their buses and returns
a matrix with their Name, Power output and Bus number (sorted by Bus). Skips Slack
generators, generators which Active Power is binding and Generators with constant price.
Note: For a quadratic cost function of the form: αPg²+ βPg + γ, a non zero slope generator
will have the parameter α ≠ 0.

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
function get_Pg_thermal_nonzeroslope(
    sys::System,
    res::PowerSimulations.OperationsProblemResults;
    dual_gen_tol::Float64
    )
    # ----------Define elements----------
    gen_loc = 0
    gen_nonzero = 0 #number of generators with non zero slope (counter starter)
    gens_thermal_nonzeroslope_Pg = Array{Float64}(undef, 0)
    gens_thermal_nonzeroslope_names = Array{String}(undef, 0)
    gens_thermal_nonzeroslope_busnumbers = Array{Int64}(undef, 0)

    # ----------Get all thermal Generators----------
    gens_thermal = get_components(ThermalStandard, sys)
    all_PGenThermal = get_variables(res)[:P__ThermalStandard] #Optimised PGen

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
                if α ≠ 0 # Only gens with α(Pg^2)
                    gen_nonzero = gen_nonzero +1
                    gen_thermal_nonzeroslope_name = gen_thermal.name
                    resize!(gens_thermal_nonzeroslope_Pg, gen_nonzero)
                    resize!(gens_thermal_nonzeroslope_names, gen_nonzero)
                    resize!(gens_thermal_nonzeroslope_busnumbers, gen_nonzero)
                    gens_thermal_nonzeroslope_Pg[gen_nonzero] =
                        all_PGenThermal[1, gen_thermal_nonzeroslope_name]
                    gens_thermal_nonzeroslope_names[gen_nonzero] =
                        gen_thermal_nonzeroslope_name
                    gens_thermal_nonzeroslope_busnumbers[gen_nonzero] =
                        gen_thermal.bus.number
                end
            end
        end
    end

    # ----------Matrix of generators with their information sorted----------
    gens_thermal_nonzeroslope_Matrix = Array{Any}(undef,(gen_nonzero, 3))
    gens_thermal_nonzeroslope_Matrix[:, 1] = gens_thermal_nonzeroslope_names
    gens_thermal_nonzeroslope_Matrix[:, 2] = gens_thermal_nonzeroslope_Pg
    gens_thermal_nonzeroslope_Matrix[:, 3] = gens_thermal_nonzeroslope_busnumbers
    #sort by bus to match with PTDF structure
    gens_thermal_nonzeroslope_Matrix =
       gens_thermal_nonzeroslope_Matrix[sortperm(gens_thermal_nonzeroslope_Matrix[:, 3]), :]

    return (gens_thermal_nonzeroslope_Matrix)
end
