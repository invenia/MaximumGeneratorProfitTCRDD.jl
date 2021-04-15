function d2f_PgPg_nonzeroslope(sys::System, res::PowerSimulations.OperationsProblemResults, dual_gen_tol::Float64)
    #Get Generators which have non zero solpes in the cost function (skips slack and Gens with Pmax binding)
    #Then, calculatrs the second derivative of the cost function
    #Asumption Cost function for each Generators is expressed as a polinomial function of the form:
    # f_nonzeroslope  =  sum (Cost_i(Pg_i)) for all i gens with non zero slope cost
    # Cost = A(Pg)^2 +  B(Pg) +  C
    # d2f_PgPgnonzeroslope  = sum (2A_i) for all i gens with non zero slope cost
    gen_loc = 0
    gen_nonzero = 0
    d2f_PgPgnonzeroslope_array  = Array{Float64}(undef,0)
    gens_thermal_nonzeroslope_names = Array{String}(undef,0)
    gens_thermal_nonzeroslope_busnumbers = Array{Int64}(undef,0)
    gens_thermal = get_components(ThermalStandard, sys)
    all_PGenThermal = get_variables(res)[:P__ThermalStandard] #Optimised PGen
    all_PGenThermal_array = convert(Array, all_PGenThermal)
    dualPgub = get_duals(res)[:P_ub__ThermalStandard__RangeConstraint]
    dualPglb = get_duals(res)[:P_lb__ThermalStandard__RangeConstraint]
    res.dual_values[:P_ub__ThermalStandard__RangeConstraint]
    for gen_thermal in gens_thermal
        gen_loc = gen_loc +1
        if get_bustype(gen_thermal.bus) ≠ BusTypes.REF  #skips slack
            bindub = !isapprox(dualPgub[1,gen_loc],0.0; atol = dual_gen_tol) #is binding true/false?
            bindlb = !isapprox(dualPglb[1,gen_loc],0.0; atol = dual_gen_tol) #is binding true/false?
            if !bindub && !bindlb #skips binding Pg gens Dual = 0
                gen_thermal_ABcost = get_cost(get_variable(get_operation_cost(gen_thermal)))
                gen_thermal_Ccost = get_fixed(get_operation_cost(gen_thermal))
                if gen_thermal_ABcost[1] ≠ 0 # Only gens with either A(Pg^2)
                    #Only self elements have second derivative
                    #PgiPgi = 2*Ai, PgiPgj = 0 
                    gen_nonzero = gen_nonzero + 1
                    resize!(d2f_PgPgnonzeroslope_array,gen_nonzero)
                    resize!(gens_thermal_nonzeroslope_names,gen_nonzero)
                    resize!(gens_thermal_nonzeroslope_busnumbers,gen_nonzero)
                    gen_thermal_nonzeroslope_name = gen_thermal.name
                    d2f_PgPgnonzeroslope_array[gen_nonzero] = 2*gen_thermal_ABcost[1]
                    gens_thermal_nonzeroslope_names[gen_nonzero] = gen_thermal_nonzeroslope_name
                    gens_thermal_nonzeroslope_busnumbers[gen_nonzero] = gen_thermal.bus.number
                end
            end
        end
    end
    d2f_PgPgnonzeroslope_MatrixInfo = Array{Any}(undef,(gen_nonzero,3))
    d2f_PgPgnonzeroslope  = Array{Float64}(undef,(gen_nonzero,1))
    d2f_PgPgnonzeroslope_MatrixInfo[:,1] = gens_thermal_nonzeroslope_names
    d2f_PgPgnonzeroslope_MatrixInfo[:,2] = d2f_PgPgnonzeroslope_array
    d2f_PgPgnonzeroslope_MatrixInfo[:,3] = gens_thermal_nonzeroslope_busnumbers
    #sort by bus to match with PTDF structure
    d2f_PgPgnonzeroslope_MatrixInfo = d2f_PgPgnonzeroslope_MatrixInfo[sortperm(d2f_PgPgnonzeroslope_MatrixInfo[:, 3]), :]
    d2f_PgPgnonzeroslope[:,1]  = d2f_PgPgnonzeroslope_MatrixInfo[:,2]
    d2f_PgPgnonzeroslope_matrix = Diagonal(d2f_PgPgnonzeroslope[:,1])
    return (d2f_PgPgnonzeroslope_matrix, d2f_PgPgnonzeroslope_MatrixInfo)    
end