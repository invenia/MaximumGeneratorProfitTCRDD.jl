function get_thermal_nonzeroslope(sys::System, res::PowerSimulations.OperationsProblemResults, dual_gen_tol::Float64)
    #Get Generators which have non zero solpes in the cost function (skips slack and Gens binding)
    gen_loc = 0
    gen_bindPg = 0
    gen_nonzero = 0
    gens_thermal_nonzeroslope = Array{Any}(undef,0)
    gens_thermal_nonzeroslope_id = Array{Int64}(undef,0)
    gens_thermal_nonzeroslope_name = Array{String}(undef,0)
    gens_thermal = get_components(ThermalStandard, sys)
    dualPgub = get_duals(res)[:P_ub__ThermalStandard__RangeConstraint]
    dualPglb = get_duals(res)[:P_lb__ThermalStandard__RangeConstraint]
    for gen_thermal in gens_thermal
        gen_loc = gen_loc +1
        if get_bustype(gen_thermal.bus) ≠ BusTypes.REF  #skips slack
            bindub = !isapprox(dualPgub[1,gen_loc],0.0; atol = dual_gen_tol) #is binding true/false?
            bindlb = !isapprox(dualPglb[1,gen_loc],0.0; atol = dual_gen_tol) #is binding true/false?
            if !bindub && !bindlb #skips binding Pg gens Dual = 0 
                gen_bindPg = gen_bindPg +1
                gen_thermal_ABcost = get_cost(get_variable(get_operation_cost(gen_thermal)))
                gen_thermal_Ccost = get_fixed(get_operation_cost(gen_thermal))
                if gen_thermal_ABcost[1] ≠ 0  # Only gens with either A(Pg^2)
                    gen_nonzero = gen_nonzero +1
                    resize!(gens_thermal_nonzeroslope,gen_nonzero)
                    resize!(gens_thermal_nonzeroslope_id,gen_nonzero)
                    resize!(gens_thermal_nonzeroslope_name,gen_nonzero)
                    gens_thermal_nonzeroslope[gen_nonzero] = get_component(ThermalStandard,sys,gen_thermal.name)
                    gens_thermal_nonzeroslope_id[gen_nonzero] = gen_loc
                    gens_thermal_nonzeroslope_name[gen_nonzero] = gen_thermal.name
                end
            end
        end
    end
    return (gens_thermal_nonzeroslope,gens_thermal_nonzeroslope_id,gens_thermal_nonzeroslope_name)
end