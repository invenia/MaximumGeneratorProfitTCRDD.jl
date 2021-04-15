function get_Pg_thermal_constprice(sys::System, res::PowerSimulations.OperationsProblemResults;
    dual_gen_tol::Float64 = 1e-1)
    #Get Generators which dont have non constant slopes but have a constant price
    #Then, retuns the generator output matrix
    #The columns are Gen Name, PowerOutput pu, Bus number
    gen_loc = 0
    gen_constprice = 0
    gens_thermal_constprice_Pg = Array{Float64}(undef,0)
    gens_thermal_constprice_names = Array{String}(undef,0)
    gens_thermal_constprice_busnumbers = Array{Int64}(undef,0)
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
                gen_thermal_slack_Ccost = get_fixed(get_operation_cost(gen_thermal))
                gen_thermal_Ccost = get_fixed(get_operation_cost(gen_thermal))
                if gen_thermal_ABcost[1] == 0 && (gen_thermal_ABcost[2] ≠ 0 || gen_thermal_Ccost ≠ 0)#skips non zero slope
                    #skips non zero slope and select only constant price
                    gen_constprice = gen_constprice +1
                    gen_thermal_constprice_name = gen_thermal.name
                    resize!(gens_thermal_constprice_Pg,gen_constprice)
                    resize!(gens_thermal_constprice_names,gen_constprice)
                    resize!(gens_thermal_constprice_busnumbers,gen_constprice)
                    gens_thermal_constprice_Pg[gen_constprice] = all_PGenThermal[1, gen_thermal_constprice_name]
                    gens_thermal_constprice_names[gen_constprice] = gen_thermal_constprice_name
                    gens_thermal_constprice_busnumbers[gen_constprice] = gen_thermal.bus.number
                end
            end
        end
    end
    gens_thermal_constprice_Matrix = Array{Any}(undef,(gen_constprice,3))
    gens_thermal_constprice_Matrix[:,1] = gens_thermal_constprice_names
    gens_thermal_constprice_Matrix[:,2] = gens_thermal_constprice_Pg
    gens_thermal_constprice_Matrix[:,3] = gens_thermal_constprice_busnumbers
    #sort by bus to match with PTDF structure
    gens_thermal_constprice_Matrix = gens_thermal_constprice_Matrix[sortperm(gens_thermal_constprice_Matrix[:, 3]), :]
    return (gens_thermal_constprice_Matrix)
end