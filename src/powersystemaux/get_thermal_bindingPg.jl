function get_thermal_bindingPg(sys::System, res::PowerSimulations.OperationsProblemResults, dual_gen_tol::Float64)
    #Get Generators which P output after OPF are equal to Pmax or Pmin (skips slack)
    #gen_thermal_slack = get_components(ThermalGen, sys, x-> get_bustype(get_bus(x)) == BusTypes.REF)
    gen_loc = 0 #enumerate function check it out
    gen_bindPg = 0
    gens_thermal_bindPg = Array{ThermalStandard}(undef,0)
    gens_thermal_bindPg_id = Array{Int64}(undef,0)
    gens_thermal_bindPg_name = Array{String}(undef,0)
    gens_thermal = get_components(ThermalStandard, sys)
    dualPgub = get_duals(res)[:P_ub__ThermalStandard__RangeConstraint]
    dualPglb = get_duals(res)[:P_lb__ThermalStandard__RangeConstraint]
    for gen_thermal in gens_thermal
        gen_loc = gen_loc +1
        if get_bustype(gen_thermal.bus) ≠ BusTypes.REF  #skips slack
            bindub = !isapprox(dualPgub[1,gen_loc],0.0; atol = dual_gen_tol) #is binding true/false?
            bindlb = !isapprox(dualPglb[1,gen_loc],0.0; atol = dual_gen_tol) #is binding true/false?
            if  bindub || bindlb #if binding dual is !≈  0.0 then 
                gen_bindPg = gen_bindPg +1
                resize!(gens_thermal_bindPg,gen_bindPg)
                resize!(gens_thermal_bindPg_id,gen_bindPg)
                resize!(gens_thermal_bindPg_name,gen_bindPg)
                gens_thermal_bindPg[gen_bindPg] = get_component(ThermalStandard,sys,gen_thermal.name)
                gens_thermal_bindPg_id[gen_bindPg] = gen_loc
                gens_thermal_bindPg_name[gen_bindPg] = gen_thermal.name
            end
        end
    end
    return (gens_thermal_bindPg,gens_thermal_bindPg_id,gens_thermal_bindPg_name)
end