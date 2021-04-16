"""
    function get_binding_lines(args...; kwargs...)

Finds the binding lines of a power system which has been solved by OPF, and reorders them in
accordance with their assigned index.

#Arguments
- `Name`:                                   Description
-------------------------------------------------------------------------------------------
- `sys::System`:                            Power system in p.u. (from PowerSystems.jl)
- `res::PowerSimulations.
    OperationsProblemResults`:              Results of the solved OPF for the system
                                             (from PowerSimulations.jl)

# Keywords
- `Name`:                                   Description
-------------------------------------------------------------------------------------------
- `dual_lines_tol::Float64 = 1e-1`:         Tolerance to identify any binding lines

"""
function get_binding_lines(
    sys::System,
    res::PowerSimulations.OperationsProblemResults;
    dual_lines_tol::Float64 = 1e-1
    )
    #Get all lines
    lines = get_components(Line, sys)

    #Gets lines with index
    (all_lines, all_lines_sorted) = assign_lines_index(lines)

    #Get components of the binding lines
    dual_lines = get_duals(res)[:network_flow]
    numberof_bind_lines = 0
    bind_lines_numbers = Array{Int64}(undef, 0)
    bind_lines_names = Array{String}(undef, 0)
    line_count = 0
    for line in lines
        line_count = line_count + 1
        line_name=line.name
        if !isapprox(dual_lines[1,line_name], 0.0; atol = dual_lines_tol)
            #if dual is different from 0.0 the line is binding
            numberof_bind_lines = numberof_bind_lines + 1
            resize!(bind_lines_numbers, numberof_bind_lines)
            resize!(bind_lines_names, numberof_bind_lines)
            bind_lines_numbers[numberof_bind_lines] = all_lines[line_count,2]
            bind_lines_names[numberof_bind_lines] = line.name
        end
    end
    bind_lines = Array{Any}(undef,(numberof_bind_lines, 2))
    bind_lines[:, 1] = bind_lines_names
    bind_lines[:, 2] = bind_lines_numbers
    bind_lines = bind_lines[sortperm(bind_lines[:, 1]), :]
    return (bind_lines)
end
