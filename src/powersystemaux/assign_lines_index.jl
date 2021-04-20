"""
    function assign_lines_index(lines)

Finds the binding lines of a power system which has been solved by OPF, and reorders them in
accordance with their assigned index.

#Arguments
- `Name`:                       Description
-------------------------------------------------------------------------------------------
- `lines`:                      lines as a direct output from
                                lines = get_components(Line, sys), see PowerSystems.jl

# Throws
- `Name`:                       Description
-------------------------------------------------------------------------------------------
- `ERROR`:                      lines has no field name. The argument must be a direct
                                output from lines = get_components(Line, sys),
                                see PowerSystems.jl

"""
function assign_lines_index(lines)
    #Get lines names and sort them
    all_lines = Array{Any}(undef,(length(lines),2))
    line_count = 0
    for line in lines
        line_count = line_count + 1
        all_lines[line_count,1] = line.name
    end

    all_lines_sorted = Array{Any}(undef,(length(lines), 2))
    all_lines_sorted[:, 1] = sort(all_lines[:, 1])
    all_lines_sorted[:, 2] = [1:length(lines);]
    #Assign Index number to unsorted lines
    for ul = 1 : length(lines) #unsorted lines
        for sl = 1 : length(lines) #sorted lines
            if all_lines_sorted[sl, 1] == all_lines[ul, 1]
                all_lines[ul, 2] = all_lines_sorted[sl, 2]
            end
        end
    end

    return (all_lines, all_lines_sorted)
end
