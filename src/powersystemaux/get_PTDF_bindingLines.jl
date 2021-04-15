function get_PTDF_bindingLines(sys::System, res::PowerSimulations.OperationsProblemResults,
    PTDF_matrix ::Any; dual_lines_tol::Float64 = 1e-1)
    #Return the PTDF matrix binding by lines
    #Locate binding lines and return corresponding PTDF binding matrix 
    bind_lines = get_binding_lines(sys, res; dual_lines_tol)
    bind_lines_names = bind_lines[:,1]
    bind_lines_numbers =  bind_lines[:,2]
    PTDF_binding_lines = PTDF_matrix.data[bind_lines_numbers,:]
    return (PTDF_binding_lines)
end   
