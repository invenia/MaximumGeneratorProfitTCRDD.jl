function get_Pg_thermal_bindingPg(sys::System, res::PowerSimulations.OperationsProblemResults, dual_gen_tol::Float64)
    #Get Generators which P output after OPF is binding  (skips slack)
    #Then, retuns the generator output matrix
    #The columns are Gen Name, PowerOutput pu, Bus number
    gen_loc = 0 #enumerate function check it out
    ngen_bindPg = 0 #number of gen binding Pmax
    gens_thermal_bindPg_Pg = Array{Float64}(undef,0)
    gens_thermal_bindPg_names = Array{String}(undef,0)
    gens_thermal_bindPg_busnumbers = Array{Int64}(undef,0)
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
            if  bindub || bindlb #if binding dual is !≈  0.0 then 
                ngen_bindPg = ngen_bindPg +1
                gen_thermal_bindPg_name = gen_thermal.name 
                resize!(gens_thermal_bindPg_Pg,ngen_bindPg)
                resize!(gens_thermal_bindPg_names,ngen_bindPg)
                resize!(gens_thermal_bindPg_busnumbers,ngen_bindPg)
                gens_thermal_bindPg_Pg[ngen_bindPg] = all_PGenThermal[1, gen_thermal_bindPg_name]
                gens_thermal_bindPg_names[ngen_bindPg] = gen_thermal_bindPg_name
                gens_thermal_bindPg_busnumbers[ngen_bindPg] = gen_thermal.bus.number
            end
        end
    end
    gens_thermal_bindPg_Matrix = Array{Any}(undef,(ngen_bindPg,3));
    gens_thermal_bindPg_Matrix[:,1] = gens_thermal_bindPg_names;
    gens_thermal_bindPg_Matrix[:,2] = gens_thermal_bindPg_Pg;
    gens_thermal_bindPg_Matrix[:,3] = gens_thermal_bindPg_busnumbers;
    #sort by bus to match with PTDF structure
    gens_thermal_bindPg_Matrix[sortperm(gens_thermal_bindPg_Matrix[:, 3]), :]
    return (gens_thermal_bindPg_Matrix)
end