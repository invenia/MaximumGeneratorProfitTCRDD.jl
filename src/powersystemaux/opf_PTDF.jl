"""
    function opf_PTDF(sys::System; kwargs...)

Solves the Optimal Power Flow (OPF) of a power system using the PTDF matrix and returns the
Locational Marginal Price (lmp) and the results of the optimisation (res).

#Arguments
- `sys::System`:                            Power system in p.u. (from PowerSystems.jl)

#Keywords
- `network::DataType = StandardPTDFModel`:  Network Representation of the Power System
- `solver= optimizer_with_attributes
    (Ipopt.Optimizer)`:                     Solver to be used for OPF
"""
function opf_PTDF(
    sys::System;
    network::DataType = StandardPTDFModel,
    solver = optimizer_with_attributes(Ipopt.Optimizer)
    )
    # Solve the OPF and calculates the lmp

    # Branch representation
    branches = Dict{Symbol,DeviceModel}(
        :L => DeviceModel(Line, StaticLine),
        :ML => DeviceModel(MonitoredLine, StaticLine),
    )
    # Devices representation
    devices = Dict(
        :Generators => DeviceModel(ThermalStandard, ThermalDispatch),
        :Ren => DeviceModel(RenewableDispatch, RenewableFullDispatch),
        :HydroROR => DeviceModel(HydroDispatch, FixedOutput),
        :RenFx => DeviceModel(RenewableFix, FixedOutput),
        :Loads => DeviceModel(PowerLoad, StaticPowerLoad),
    )
    # Services representation
    services = Dict(
        :ReserveUp => ServiceModel(VariableReserve{ReserveUp}, RangeReserve),
        :ReserveDown => ServiceModel(VariableReserve{ReserveDown}, RangeReserve),
    )

    # Select Template for Optimisation problem
    template_opt = OperationsProblemTemplate(network, devices, branches, services)

    # Calculate PTDF
    PTDF_matrix = PTDF(sys)

    #Save the information to the Operations Problem
    problem = OperationsProblem(
        GenericOpProblem,
        template_opt,
        sys,
        horizon = 1,
        #use_forecast_data = false,
        optimizer = solver,
        balance_slack_variables = true,
        constraint_duals = [:CopperPlateBalance, :network_flow,
        :P_ub__ThermalStandard__RangeConstraint, :P_lb__ThermalStandard__RangeConstraint],
        PTDF = PTDF_matrix,
    )
    # Solve optimisation problem
    res = solve!(problem)

    # Computing final LMP by subtracting the duals (μ) of network_flow constraint ...
    # multiplied by the PTDF matrix from the dual (λ) of CopperPlateBalance constraint.

    # Convert the results from DataFrame to Array for ease of use.
    λ = convert(Array, res.dual_values[:CopperPlateBalance])
    μ = convert(Array, res.dual_values[:network_flow])

    # Calculate congestion component of the LMP as a product of μ and the PTDF matrix.
    buses = get_components(Bus, sys)
    congestion_lmp = Dict()
    for bus in buses
        congestion_lmp[get_name(bus)] = μ * PTDF_matrix[:, get_number(bus)]
    end
    congestion_lmp = DataFrame(congestion_lmp)

    # Get the LMP for each node in a lossless DC-OPF using the PTDF formulation.
    # resize!(lmp,counter);
    lmp = λ .- congestion_lmp

    return lmp, res
end
