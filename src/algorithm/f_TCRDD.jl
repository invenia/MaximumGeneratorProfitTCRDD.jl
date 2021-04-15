function f_TCRDD(sys::System, res::PowerSimulations.OperationsProblemResults; 
    dual_lines_tol::Float64 = 1e-1, dual_gen_tol::Float64 = 1e-1)
    #Calculates TCRDD using PTDFs as in:
    #L. Xu, R. Baldick and Y. Sutjandra, "Bidding Into Electricity Markets: 
    #A Transmission-Constrained Residual Demand Derivative Approach," in IEEE
    # Transactions on Power Systems, vol. 26, no. 3, pp. 1380-1388, Aug. 2011,
    # doi: 10.1109/TPWRS.2010.2083702.
    #------------------------------

    #PTDF for binding Lines
    PTDF_matrix = PTDF(sys); #Calculate PTDF
    PTDF_binding_lines = get_PTDF_bindingLines(sys, res, PTDF_matrix; dual_lines_tol)
    nbind_lines = length(PTDF_binding_lines[:,1]) #number binding lines

    #PTDF Generators separation
    #PTDF Slack is zeros
    (gens_thermal_slack_busnumber, PTDFb_slack) = get_PTDF_thermal_slack(sys, PTDF_binding_lines)
    ngens_thermal_slack = length(gens_thermal_slack_busnumber)
    #PTDF Pg Binding Gens (Checked with Duals)
    (gens_thermal_bindPg_busnumber,PTDFb_bindingPg) = get_PTDF_thermal_bindingPg(sys,res, PTDF_binding_lines; dual_gen_tol)
    ngens_thermal_bindPg = length(gens_thermal_bindPg_busnumber)
    #PTDF Pmax Non Zero Slope
    (gens_thermal_nonzeroslope_busnumber,PTDFb_nonzeroslope) = get_PTDF_thermal_nonzeroslope(sys,res, PTDF_binding_lines; dual_gen_tol)
    ngens_thermal_nonzeroslope = length(gens_thermal_nonzeroslope_busnumber)
    #PTDF Pmax Non Constant Price
    (gens_thermal_constprice_busnumber,PTDFb_constprice) = get_PTDF_thermal_constprice(sys,res, PTDF_binding_lines; dual_gen_tol)
    ngens_thermal_constprice = length(gens_thermal_constprice_busnumber)
    #Load PTDF separation
    (PQ_buses, PTDF_PQLoad) = get_PTDF_load(sys, PTDF_binding_lines)
    
    #Obtaining vector of ones of size Slack, Pmax Pg, nonzeroslopes, constant price
    ones_slack = ones(ngens_thermal_slack);
    ones_bindPg = ones(ngens_thermal_bindPg);
    ones_nonzeroslope = ones(ngens_thermal_nonzeroslope);
    ones_constprice = ones(ngens_thermal_constprice);

    #build zeros matrices just for Ax=b
    zeros_nonzeroslope_constprice = zeros(ngens_thermal_nonzeroslope,ngens_thermal_constprice);
    zeros_constprice_nonzeroslope = zeros_nonzeroslope_constprice';
    zeros_constprice_constprice = zeros(ngens_thermal_constprice,ngens_thermal_constprice);
    zeros_lines_lines = zeros(nbind_lines,nbind_lines);
    zeros_lines = zeros(nbind_lines,1);
    
    #Calculation of the second derivative of the objective function w.r.t PgnonzeroslopePgnonzeroslope
    (d2f_PgPgnonzeroslope, d2f_PgPgnonzeroslope_MatrixInfo) = d2f_PgPg_nonzeroslope(sys, res, dual_gen_tol)
    
    #Build the system of equations depending on the case
    if nbind_lines ≠ 0  && ngens_thermal_constprice ≠ 0
        #build A x = b
        A = [d2f_PgPgnonzeroslope zeros_nonzeroslope_constprice (-(PTDFb_nonzeroslope'));
            zeros_constprice_nonzeroslope zeros_constprice_constprice -(PTDFb_constprice');
            PTDFb_nonzeroslope PTDFb_constprice zeros_lines_lines];
        b = [ones_nonzeroslope; ones_constprice; zeros_lines];
        #x = [dPgnonzeroslope_dlam dPgconstprice_dlam dmulines_dlam]; 
        
        #Solve the system using JuMP
        model_a = Model(GLPK.Optimizer)
        @variable(model_a, dPgnonzeroslope_dlam_a[1:ngens_thermal_nonzeroslope])
        @variable(model_a, dPgconstprice_dlam_a[1:ngens_thermal_constprice])
        @variable(model_a, dmubind_dlam_a[1:nbind_lines])
        
        @objective(model_a, Min, 5) #Minimise any objective

        @constraint(model_a,const_a, A* [dPgnonzeroslope_dlam_a ; dPgconstprice_dlam_a ; dmubind_dlam_a ] .== b)

        print(model_a)
        optimize!(model_a)

        println("Termination status : ", termination_status(model_a))
        println("Primal status      : ", primal_status(model_a))

        #obj_value = objective_value(model)
        dPgnonzeroslope_dlam_a_value = value.(dPgnonzeroslope_dlam_a)
        dPgconstprice_dlam_a_value = value.(dPgconstprice_dlam_a)
        dmubind_dlam_a_value = value.(dmubind_dlam_a)

        #Calculate the TCRDD 
        tcrdd_slack = -(ones_nonzeroslope')*dPgnonzeroslope_dlam_a_value - (ones_constprice')*dPgconstprice_dlam_a_value

    elseif nbind_lines ≠ 0  && ngens_thermal_constprice == 0
        #build A x = b
        A = [d2f_PgPgnonzeroslope (-(PTDFb_nonzeroslope'));
            PTDFb_nonzeroslope zeros_lines_lines];
        b = [ones_nonzeroslope; zeros_lines];
        #x = [dPgnonzeroslope_dlam dmulines_dlam];
        
        #Solve the system using JuMP
        model_b = Model(GLPK.Optimizer)
        @variable(model_b, dPgnonzeroslope_dlam_b[1:ngens_thermal_nonzeroslope])
        @variable(model_b, dmubind_dlam_b[1:nbind_lines])
        
        @objective(model_b, Min, 5) #Minimise any objective

        @constraint(model_b,const_b, A* [dPgnonzeroslope_dlam_b ; dmubind_dlam_b] .== b)

        print(model_b)
        optimize!(model_b)

        println("Termination status : ", termination_status(model_b))
        println("Primal status      : ", primal_status(model_b))

        #obj_value = objective_value(model)
        dPgnonzeroslope_dlam_b_value = value.(dPgnonzeroslope_dlam_b)
        dmubind_dlam_b_value = value.(dmubind_dlam_b)

        #Calculate the TCRDD 
        tcrdd_slack = -(ones_nonzeroslope')*dPgnonzeroslope_dlam_b_value

    elseif nbind_lines == 0 #&& ngens_thermal_constprice ≠ 0
        A = d2f_PgPgnonzeroslope;
        b = ones_nonzeroslope;
        #x = [dPgnonzeroslope_dlam];
        
        #Solve the system using JuMP
        model_d = Model(GLPK.Optimizer)
        @variable(model_d, dPgnonzeroslope_dlam_d[1:ngens_thermal_nonzeroslope])
        
        @objective(model_d, Min, 5) #Minimise any objective

        @constraint(model_d,const_d, A* dPgnonzeroslope_dlam_d .== b)

        print(model_d)
        optimize!(model_d)

        println("Termination status : ", termination_status(model_d))
        println("Primal status      : ", primal_status(model_d))

        #obj_value = objective_value(model)
        dPgnonzeroslope_dlam_d_value = value.(dPgnonzeroslope_dlam_d)

        #Calculate the TCRDD 
        tcrdd_slack = -(ones_nonzeroslope')*dPgnonzeroslope_dlam_d_value
                
    end
    return (tcrdd_slack)
end