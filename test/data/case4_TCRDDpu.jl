using TimeSeries
using Dates
using D3TypeTrees
using DataFrames
using DataStructures
using PowerSystems

dates = collect(
    DateTime("1/1/2024  0:00:00", "d/m/y  H:M:S"):Hour(1):DateTime(
        "1/1/2024  23:00:00",
        "d/m/y  H:M:S",
    ),
)

nodes4_tcrd() = [
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
branches4_tcrd(nodes4_tcrd) = [
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

thermal_generators4_tcrd(nodes4_tcrd) = [
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
    ),
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
]

#time series per zone
loadz1_ts = ones(Float64, 24)

loads4_tcrd(nodes4_tcrd) = [
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

timeseries_DA4_tcrd = [
    TimeArray(dates, loadz1_ts),
    TimeArray(dates, loadz1_ts),
];

function filter_kwargs(; kwargs...)
    system_kwargs = filter(x -> in(first(x), PSY.SYSTEM_KWARGS), kwargs)
    return system_kwargs
end

function build_c_sys4_tcrd(; kwargs...)
    sys_kwargs = filter_kwargs(; kwargs...)
    nodes = nodes4_tcrd()
    c_sys4_tcrd = PSY.System(
        100.0,
        nodes,
        thermal_generators4_tcrd(nodes),
        loads4_tcrd(nodes),
        branches4_tcrd(nodes);
        time_series_in_memory = get(sys_kwargs, :time_series_in_memory, true),
        sys_kwargs...,
    )

    if get(kwargs, :add_forecasts, true)
        forecast_data = SortedDict{Dates.DateTime, TimeSeries.TimeArray}()
        for (ix, l) in enumerate(PSY.get_components(PowerLoad, c_sys4_tcrd))
            ini_time = TimeSeries.timestamp(timeseries_DA4_tcrd[ix])[1]
           forecast_data[ini_time] = timeseries_DA4_tcrd[ix]
           PSY.add_time_series!(
               c_sys4_tcrd,
               l,
               PSY.Deterministic("max_active_power", forecast_data),
           )
       end
    end

    return c_sys4_tcrd
end
