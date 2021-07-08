"""
    function add_virtual_gens!(
        sys::System,
        sender_buses_names::Array{String, 1},
        weights::Array{Float64, 1},
        bidMin::Float64,
        bidMax::Float64,
        )

Adds Virtual Generators to the system in the selected nodes.

# Arguments
- `sys::System`:                            Power system in p.u. (from PowerSystems.jl)
- `sender_buses_names::Array`:              Names of the buses to bid on
- `weights::Array`:                         Weights for each bus to bid
- `bidMax::Float64`:                        Max bid for the Virtual Participant in p.u.
- `bidMin::Float64`:                        Min bid for the Virtual Participant in p.u.

"""
function add_virtual_gens!(
    sys::System,
    sender_buses_names::Array{String, 1},
    weights::Array{Float64, 1},
    bidMin::Float64,
    bidMax::Float64,
    )

    sender_buses = Array{Bus}(undef, length(sender_buses_names))
    gen_virt = Array{ThermalStandard}(undef, length(sender_buses_names))
    gen_virt_names = Array{String}(undef, length(sender_buses_names))
    devices = []
    for (i, bus_name) in enumerate(sender_buses_names)
        sender_buses[i] = get_component(Bus, sys, bus_name)
        # Add Virtual Generator
        gen_virt[i] = ThermalStandard(nothing)
        gen_virt[i].bus = sender_buses[i]
        gen_virt_names[i] = "GenVirt" * string(i)
        gen_virt[i].name = gen_virt_names[i]
        gen_virt[i].available = true
        gen_virt[i].status = true
        gen_virt[i].active_power = bidMax*weights[i]*0.5
        gen_virt[i].reactive_power = 0.0
        gen_virt[i].active_power_limits = (min = bidMin*weights[i], max = bidMax*weights[i])
        gen_virt[i].reactive_power_limits = (min = 0.0, max = 0.0)
        gen_virt[i].rating = bidMax*weights[i]
        gen_virt[i].base_power = 100
        add_component!(sys, gen_virt[i])
        push!(devices, gen_virt[i])
        gen_virt_names[i] = gen_virt[i].name
    end

    return sys, gen_virt, gen_virt_names
end
