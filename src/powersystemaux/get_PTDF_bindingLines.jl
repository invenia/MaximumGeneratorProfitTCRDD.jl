"""
    function get_PTDF_bindingLines(args...; kwargs...)

Takes the full PTDF matrix of the system and only selects the rows that correspond to the
binding lines of a solved OPF case. It returns the parsed PTDF Matrix. To determine if a
branch are binding, the dual variables from the OPF are compared against a tolerance.

#Arguments
- `sys::System`:                            Power system in p.u. (from PowerSystems.jl)
- `res::PowerSimulations.
    OperationsProblemResults`:              Results of the solved OPF for the system
                                             (from PowerSimulations.jl)
- `PTDF_matrix::Any`:                       PTDF matrix as a direct output from
                                            PTDF_matrix = PTDF(sys), see PowerSystems.jl

# Keywords
- `dual_lines_tol::Float64 = 1e-1`:         Tolerance to identify any binding lines

# Throws
- `ERROR`:                                  PTDF_matrix has no field data. The argument must
                                            be a direct output from PTDF_matrix = PTDF(sys)
                                            see PowerSystems.jl
"""
function get_PTDF_bindingLines(
    sys::System,
    res::PowerSimulations.OperationsProblemResults,
    PTDF_matrix ::Any;
    dual_lines_tol::Float64 = 1e-1
    )
    # Return the PTDF matrix binding by lines
    # Locate binding lines and return corresponding PTDF binding matrix
    bind_lines = get_binding_lines(sys, res; dual_lines_tol)
    bind_lines_names = bind_lines[:,1]
    bind_lines_numbers =  bind_lines[:,2]
    PTDF_binding_lines = PTDF_matrix.data[bind_lines_numbers,:]
    return PTDF_binding_lines
end
