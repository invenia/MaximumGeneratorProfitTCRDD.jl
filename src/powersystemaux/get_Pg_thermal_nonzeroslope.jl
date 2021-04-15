function get_Pg_thermal_nonzeroslope(sys::System, res::PowerSimulations.OperationsProblemResults, dual_gen_tol::Float64)
    #Get Generators which have non zero solpes in the cost function (skips slack and Gens with Pmax binding)
    #Then, retuns the generator output matrix
    #The columns are Gen Name, PowerOutput pu, Bus number
    gen_loc = 0
    gen_nonzero = 0
    gens_thermal_nonzeroslope_Pg = Array{Float64}(undef,0)
    gens_thermal_nonzeroslope_names = Array{String}(undef,0)
    gens_thermal_nonzeroslope_busnumbers = Array{Int64}(undef,0)
    gens_thermal = get_components(ThermalStandard, sys)
    all_PGenThermal = get_variables(res)[:P__ThermalStandard] #Optimised PGen
    all_PGenThermal_array = convert(Array, all_PGenThermal)
    dualPgub = get_duals(res)[:P_ub__ThermalStandard__RangeConstraint]
    dualPglb = get_duals(res)[:P_lb__ThermalStandard__RangeConstraint]
    for gen_thermal in gens_thermal
        gen_loc = gen_loc +1
        if get_bustype(gen_thermal.bus) ≠ BusTypes.REF  #skips slack
            bindub = !isapprox(dualPgub[1,gen_loc],0.0; atol = dual_gen_tol) #is binding true/false?
            bindlb = !isapprox(dualPglb[1,gen_loc],0.0; atol = dual_gen_tol) #is binding true/false?
            if !bindub && !bindlb #skips binding Pg gens Dual = 0
                gen_thermal_ABcost = get_cost(get_variable(get_operation_cost(gen_thermal)))
                gen_thermal_Ccost = get_fixed(get_operation_cost(gen_thermal))
                if gen_thermal_ABcost[1] ≠ 0 # Only gens with either A(Pg^2)
                    gen_nonzero = gen_nonzero +1
                    gen_thermal_nonzeroslope_name = gen_thermal.name
                    resize!(gens_thermal_nonzeroslope_Pg,gen_nonzero)
                    resize!(gens_thermal_nonzeroslope_names,gen_nonzero)
                    resize!(gens_thermal_nonzeroslope_busnumbers,gen_nonzero)
                    gens_thermal_nonzeroslope_Pg[gen_nonzero] = all_PGenThermal[1, gen_thermal_nonzeroslope_name]
                    gens_thermal_nonzeroslope_names[gen_nonzero] = gen_thermal_nonzeroslope_name
                    gens_thermal_nonzeroslope_busnumbers[gen_nonzero] = gen_thermal.bus.number
                end
            end
        end
    end
    gens_thermal_nonzeroslope_Matrix = Array{Any}(undef,(gen_nonzero,3))
    gens_thermal_nonzeroslope_Matrix[:,1] = gens_thermal_nonzeroslope_names
    gens_thermal_nonzeroslope_Matrix[:,2] = gens_thermal_nonzeroslope_Pg
    gens_thermal_nonzeroslope_Matrix[:,3] = gens_thermal_nonzeroslope_busnumbers
    #sort by bus to match with PTDF structure
    gens_thermal_nonzeroslope_Matrix = gens_thermal_nonzeroslope_Matrix[sortperm(gens_thermal_nonzeroslope_Matrix[:, 3]), :]
    return (gens_thermal_nonzeroslope_Matrix)
end