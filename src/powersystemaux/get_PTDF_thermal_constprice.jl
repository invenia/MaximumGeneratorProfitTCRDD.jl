function get_PTDF_thermal_constprice(sys::System, res::PowerSimulations.OperationsProblemResults, PTDF_matrix ::Array;
    dual_gen_tol::Float64 = 1e-1)
    #Get Generators which dont have non constant slopes but have a constant price (skips slack and Gens with Pg binding)
    #Locate their buses and return corresponding PTDF matrix    gen_loc = 0
    gen_loc = 0
    gen_constprice = 0
    gens_thermal_constantprice_busnumber = Array{Int64}(undef,0)
    (nl,nb)=size(PTDF_matrix)
    PTDF_constantprice = Array{Float64}(undef,(nl,0))
    gens_thermal = get_components(ThermalStandard, sys)
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
                if gen_thermal_ABcost[1] == 0 && (gen_thermal_ABcost[2] ≠ 0 || gen_thermal_Ccost ≠ 0)#skips non zero slope
                    gen_constprice = gen_constprice +1
                    resize!(gens_thermal_constantprice_busnumber,gen_constprice)
                    gens_thermal_constantprice_busnumber[gen_constprice] = gen_thermal.bus.number
                end
            end
        end
    end
    if gens_thermal_constantprice_busnumber == Any[]
        PTDF_constantprice = Array{Float64}(undef,(nl,0))
    else
        sort!(gens_thermal_constantprice_busnumber)
        PTDF_constantprice = PTDF_matrix[:,gens_thermal_constantprice_busnumber]
    end
    return (gens_thermal_constantprice_busnumber,PTDF_constantprice)
end