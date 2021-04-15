function get_PTDF_thermal_bindingPg(sys::System, 
    res::PowerSimulations.OperationsProblemResults, PTDF_matrix ::Array;
    dual_gen_tol::Float64 = 1e-1)
    #Get Generators which P output after OPF are equal to Pmax  (skips slack)
    #Locate their buses and return corresponding PTDF matrix 
    gen_loc = 0 #enumerate function check it out
    gen_bindPg = 0
    gens_thermal_bindPg_busnumber = Array{Int64}(undef,0)
    gens_thermal_bindPg_name = Array{String}(undef,0)
    (nl,nb)=size(PTDF_matrix)
    PTDF_bindingPg = Array{Float64}(undef,(nl,0))
    gens_thermal = get_components(ThermalStandard, sys)
    dualPgub = get_duals(res)[:P_ub__ThermalStandard__RangeConstraint]
    dualPglb = get_duals(res)[:P_lb__ThermalStandard__RangeConstraint]
    for gen_thermal in gens_thermal
        gen_loc = gen_loc +1
        if get_bustype(gen_thermal.bus) ≠ BusTypes.REF  #skips slack
            bindub = !isapprox(dualPgub[1,gen_loc],0.0; atol = dual_gen_tol) #is binding true/false?
            bindlb = !isapprox(dualPglb[1,gen_loc],0.0; atol = dual_gen_tol) #is binding true/false?
            #println("UB: ", bindub,"LB: ", bindlb)
            if  bindub || bindlb #if binding dual is !≈  0.0 then 
                gen_bindPg = gen_bindPg +1
                resize!(gens_thermal_bindPg_name,gen_bindPg)
                resize!(gens_thermal_bindPg_busnumber,gen_bindPg)
                gens_thermal_bindPg_name[gen_bindPg] = gen_thermal.name
                gens_thermal_bindPg_busnumber[gen_bindPg] = gen_thermal.bus.number
                #println(gens_thermal_bindPg_name[gen_bindPg],"Bus: ", gens_thermal_bindPg_busnumber[gen_bindPg])
            end
        end
    end
    if gens_thermal_bindPg_busnumber == Any[]
        PTDF_bindingPg = Array{Float64}(undef,(nl,0))
    else
        sort!(gens_thermal_bindPg_busnumber)
        PTDF_bindingPg = PTDF_matrix[:,gens_thermal_bindPg_busnumber]
    end
    return (gens_thermal_bindPg_busnumber,PTDF_bindingPg)
end