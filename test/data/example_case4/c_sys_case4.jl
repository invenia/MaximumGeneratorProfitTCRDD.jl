"""
    function c_sys_case4(; kwargs...)

Constructs the system for the example Case 4. The example based from [1], note that the
values of the elements are modified.

"""
function c_sys_case4(; kwargs...)
    sys_kwargs = filter_kwargs(; kwargs...)
    # Buses of the System
    nodes = nodes4_tcrd()
    # Build the System
    c_sys4_tcrd = PSY.System(
        100.0,
        nodes,
        thermal_generators4_tcrd(nodes),
        loads4_tcrd(nodes),
        branches4_tcrd(nodes);
        time_series_in_memory = get(sys_kwargs, :time_series_in_memory, true),
        sys_kwargs...,
    )

    # Dates for the System
    dates = collect(
        DateTime("1/1/2024  0:00:00", "d/m/y  H:M:S"):Hour(1):DateTime(
        "1/1/2024  23:00:00",
        "d/m/y  H:M:S",
        ),
    )

    # Load pattern for 24 hrs
    #time series per zone
    loadz1_ts = ones(Float64, 24)

    # Loads of the system
    loads4_tcrd(nodes4_tcrd())
    timeseries_DA4_tcrd = [
        TimeArray(dates, loadz1_ts),
        TimeArray(dates, loadz1_ts),
        ]

    # Forecasts of the System
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
