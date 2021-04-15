function get_PTDF_load(sys::System, PTDF_matrix ::Array)
    #Finds the PQnodes and obtains the PTDF matrix for those nodes
    #Get components of the Bus
    buses = get_components(Bus, sys)
    numberof_PQnodes = 0
    (nl,nb)=size(PTDF_matrix)
    PQ_buses = Array{Int64}(undef,0)
    lines = get_components(Line, sys)
    PTDF_PQLoad = Array{Float64}(undef,(nl,0))
    for bus in buses
        if get_bustype(bus) == BusTypes.PQ
            numberof_PQnodes = numberof_PQnodes + 1
            resize!(PQ_buses, numberof_PQnodes)
            PQ_buses[numberof_PQnodes] = bus.number
        end
    end
    if numberof_PQnodes == 0
        PTDF_PQLoad = Array{Float64}(undef,(nl,0))
    else
        sort!(PQ_buses)
        PTDF_PQLoad = PTDF_matrix[:,PQ_buses]
    end
    return(PQ_buses, PTDF_PQLoad)
end