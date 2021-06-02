# ---------- Build up functions ----------
"""
    function filter_kwargs(; kwargs...)

Gets and filters keyword arguments to build the example system for case 4
"""
function filter_kwargs(; kwargs...)
    system_kwargs = filter(x -> in(first(x), PSY.SYSTEM_KWARGS), kwargs)
    return (system_kwargs)
end

# ---------- Buses of the System ----------
"""
    function nodes4_tcrd()

Returns the data with the information of the buses of the example system case 4
"""
function nodes4_tcrd()
    nodes4 = [
        Bus(
            1,
            "Bus 1",
            "REF",
            0.0,
            1.0,
            (min = 0.9, max = 1.1),
            220,
            nothing,
            nothing),
        Bus(
            2,
            "Bus 2",
            "PV",
            0.0,
            1.0,
            (min = 0.9, max = 1.1),
            220,
            nothing,
            nothing,
        ),
        Bus(
            3,
            "Bus 3",
            "PV",
            0.0,
            1.0,
            (min = 0.9, max = 1.1),
            220,
            nothing,
            nothing,
        ),
        Bus(
            4,
            "Bus 4",
            "PV",
            0.0,
            1.0,
            (min = 0.9, max = 1.1),
            220,
            nothing,
            nothing,
        ),
    ]
    return (nodes4)
end

# ---------- Lines of the System ----------
"""
    function branches4_tcrd(nodes4_tcrd)

Returns the data with the information of the Lines of the system for the example case 4

# Arguments
- `Name`:                                   Description
-------------------------------------------------------------------------------------------
- `nodes4_tcrd`:                            Array with the information of the buses of
                                            the example system case 4
"""
function branches4_tcrd(nodes4_tcrd)
    branches4 = [
        Line(
            "Line1",
            true,
            0.0,
            0.0,
            Arc(from = nodes4_tcrd[1], to = nodes4_tcrd[2]),
            0.0,
            0.1,
            (from = 0.0, to = 0.0),
            0.20,
            1.0,
        ),
        Line(
            "Line2",
            true,
            0.0,
            0.0,
            Arc(from = nodes4_tcrd[1], to = nodes4_tcrd[3]),
            0.0,
            0.1,
            (from = 0.0, to = 0.0),
            2.0,
            1.0,
        ),
        Line(
            "Line3",
            true,
            0.0,
            0.0,
            Arc(from = nodes4_tcrd[2], to = nodes4_tcrd[3]),
            0.0,
            0.1,
            (from = 0.0, to = 0.0),
            2.0,
            1.0,
        ),
        Line(
            "Line4",
            true,
            0.0,
            0.0,
            Arc(from = nodes4_tcrd[2], to = nodes4_tcrd[4]),
            0.0,
            0.1,
            (from = 0.0, to = 0.0),
            2.0,
            1.0,
        ),
        Line(
            "Line5",
            true,
            0.0,
            0.0,
            Arc(from = nodes4_tcrd[3], to = nodes4_tcrd[4]),
            0.0,
            0.1,
            (from = 0.0, to = 0.0),
            2.0,
            1.0,
        ),
    ]
    return (branches4)
end

# ---------- Thermal Generators of the System ----------
"""
    function thermal_generators4_tcrd(nodes4_tcrd)

Returns the data with the information of the thermal generators of the system for the
example case 4

# Arguments
- `Name`:                                   Description
-------------------------------------------------------------------------------------------
- `nodes4_tcrd`:                            Array with the information of the buses of
                                            the example system case 4
"""
function thermal_generators4_tcrd(nodes4_tcrd)
    thermal4 = [
        ThermalStandard(
            name = "GBus1",
            available = true,
            status = true,
            bus = nodes4_tcrd[1],
            active_power = 0.50,
            reactive_power = 0.10,
            rating = 0.500,
            prime_mover = PrimeMovers.ST,
            fuel = ThermalFuels.COAL,
            active_power_limits = (min = 0.0, max = 1.0),
            reactive_power_limits = (min = -0.25, max = 0.25),
            time_limits = nothing,
            ramp_limits = nothing,
            operation_cost = ThreePartCost((0.175000, 10.0000), 0.0, 0.0, 0.0),
            base_power = 100.0,
        ), #operation_cost = ThreePartCost((0.175000, 10.0000), 0.0, 0.0, 0.0),
        #operation_cost = ThreePartCost((0.000, 0.0000), 0.0, 0.0, 0.0),
        ThermalStandard(
            name = "GBus2",
            available = true,
            status = true,
            bus = nodes4_tcrd[2],
            active_power = 0.50,
            reactive_power = 0.10,
            rating = 0.500,
            prime_mover = PrimeMovers.ST,
            fuel = ThermalFuels.COAL,
            active_power_limits = (min = 0.0, max = 0.50),
            reactive_power_limits = (min = -0.25, max = 0.25),
            time_limits = nothing,
            ramp_limits = nothing,
            operation_cost = ThreePartCost((0.497000, 10.0000), 0.0, 0.0, 0.0),
            base_power = 100.0,
        ),
        #operation_cost = ThreePartCost((0.497000, 10.0000), 0.0, 0.0, 0.0),
        ThermalStandard(
            name = "GBus3",
            available = true,
            status = true,
            bus = nodes4_tcrd[3],
            active_power = 0.50,
            reactive_power = 0.10,
            rating = 2.00,
            prime_mover = PrimeMovers.ST,
            fuel = ThermalFuels.COAL,
            active_power_limits = (min = 0.0, max = 2.00),
            reactive_power_limits = (min = -1.00, max = 1.00),
            time_limits = nothing,
            ramp_limits = nothing,
            operation_cost = ThreePartCost((0.260000, 20.000), 0.0, 0.0, 0.0),
            base_power = 100.0,
        ),
        #operation_cost = ThreePartCost((0.260000, 20.000), 0.0, 0.0, 0.0),
        ThermalStandard(
            name = "GBus4",
            available = true,
            status = true,
            bus = nodes4_tcrd[4],
            active_power = 0.50,
            reactive_power = 0.10,
            rating = 2.00,
            prime_mover = PrimeMovers.ST,
            fuel = ThermalFuels.COAL,
            active_power_limits = (min = 0.0, max = 2.00),
            reactive_power_limits = (min = -1.00, max = 1.00),
            time_limits = nothing,
            ramp_limits = nothing,
            operation_cost = ThreePartCost((0.325000, 20.000), 0.0, 0.0, 0.0),
            base_power = 100.0,
        ),
        #operation_cost = ThreePartCost((0.325000, 20.000), 0.0, 0.0, 0.0),
    ]
    return (thermal4)
end

# ---------- Loads of the System ----------
"""
    function loads4_tcrd(nodes4_tcrd)

Returns the data with the information of the Loads of the system for the example case 4

# Arguments
- `Name`:                                   Description
-------------------------------------------------------------------------------------------
- `nodes4_tcrd`:                            Array with the information of the buses of
                                            the example system case 4
"""
function loads4_tcrd(nodes4_tcrd)
    loads4 = [
        PowerLoad(
            "Bus3",
            true,
            nodes4_tcrd[3],
            LoadModels.ConstantPower,
            1.0,
            0.0,
            100.0,
            1.0,
            0.0,
        ),
        PowerLoad(
            "Bus4",
            true,
            nodes4_tcrd[4],
            LoadModels.ConstantPower,
            1.0,
            0.0,
            100.0,
            1.0,
            0.0,
        ),
    ]
    return (loads4)
end
