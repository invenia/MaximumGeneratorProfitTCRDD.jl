"""
    function d2f_PgPg_nonzeroslope(args...; kwargs...)

Calculates the second derivative of the total generation cost function for the generators
w.r.t. the active power output (Pg). Since the cost function for each generator is assumed
to be polinomial of the form: Gencost = αPg² + βPg + γ, the derivative is only calculated
for the generators with non zero slopes. Their second derivative is: 2α, for all the other
generators the second derivative is zero. Also, only self elements have a second derivative.
Note: a non zero slope generator will have the parameter α ≠ 0.

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
function d2f_PgPg_nonzeroslope(
    sys::System,
    res::PowerSimulations.OperationsProblemResults;
    dual_gen_tol::Float64 = 1e-1
    )
    # ----------Define elements----------
    gen_loc = 0
    gen_nonzero = 0
    d2f_PgPgnonzeroslope_array  = Array{Float64}(undef, 0)
    gens_thermal_nonzeroslope_names = Array{String}(undef, 0)
    gens_thermal_nonzeroslope_busnumbers = Array{Int64}(undef, 0)

    # ----------Get all thermal Generators----------
    gens_thermal = get_components(ThermalStandard, sys)
    all_PGenThermal = get_variables(res)[:P__ThermalStandard] #Optimised PGen

    # ----------Get dual variables from the OPF results----------
    dualPgub = get_duals(res)[:P_ub__ThermalStandard__RangeConstraint]
    dualPglb = get_duals(res)[:P_lb__ThermalStandard__RangeConstraint]

    # ----------Identify Non zero Slope Generators and calculate their derivative----------
    for gen_thermal in gens_thermal
        gen_loc = gen_loc +1
        if get_bustype(gen_thermal.bus) ≠ BusTypes.REF  #skips slack
            bindub = !isapprox(dualPgub[1, gen_loc], 0.0; atol = dual_gen_tol) #is binding?
            bindlb = !isapprox(dualPglb[1, gen_loc], 0.0; atol = dual_gen_tol) #is binding?
            if !bindub && !bindlb #skips binding Pg gens Dual = 0
                (α, β) = get_cost(get_variable(get_operation_cost(gen_thermal)))
                γ = get_fixed(get_operation_cost(gen_thermal))
                if α ≠ 0 # Only gens with α(Pg^2)
                    #Only self elements have second derivative
                    gen_nonzero = gen_nonzero + 1
                    resize!(d2f_PgPgnonzeroslope_array, gen_nonzero)
                    resize!(gens_thermal_nonzeroslope_names, gen_nonzero)
                    resize!(gens_thermal_nonzeroslope_busnumbers, gen_nonzero)
                    gen_thermal_nonzeroslope_name = gen_thermal.name
                    d2f_PgPgnonzeroslope_array[gen_nonzero] = 2*α
                    gens_thermal_nonzeroslope_names[gen_nonzero] =
                        gen_thermal_nonzeroslope_name
                    gens_thermal_nonzeroslope_busnumbers[gen_nonzero] =
                        gen_thermal.bus.number
                end
            end
        end
    end
    # ----------Matrix of information----------
    d2f_PgPgnonzeroslope_MatrixInfo = Array{Any}(undef, (gen_nonzero, 3))
    d2f_PgPgnonzeroslope  = Array{Float64}(undef, (gen_nonzero, 1))
    d2f_PgPgnonzeroslope_MatrixInfo[:, 1] = gens_thermal_nonzeroslope_names
    d2f_PgPgnonzeroslope_MatrixInfo[:, 2] = d2f_PgPgnonzeroslope_array
    d2f_PgPgnonzeroslope_MatrixInfo[:, 3] = gens_thermal_nonzeroslope_busnumbers
    #sort by bus to match with PTDF structure
    d2f_PgPgnonzeroslope_MatrixInfo =
        d2f_PgPgnonzeroslope_MatrixInfo[sortperm(d2f_PgPgnonzeroslope_MatrixInfo[:, 3]), :]

    # ----------Second Derivative Matrix----------
    d2f_PgPgnonzeroslope[:,1]  = d2f_PgPgnonzeroslope_MatrixInfo[:, 2]
    d2f_PgPgnonzeroslope_matrix = Diagonal(d2f_PgPgnonzeroslope[:, 1])

    return (d2f_PgPgnonzeroslope_matrix, d2f_PgPgnonzeroslope_MatrixInfo)
end
