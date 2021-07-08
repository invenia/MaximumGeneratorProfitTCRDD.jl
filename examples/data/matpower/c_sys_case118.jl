"""
    function filter_kwargs(; kwargs...)

Gets and filters keyword arguments to build the example system for case 4
"""
function filter_kwargs(; kwargs...)
    system_kwargs = filter(x -> in(first(x), PSY.SYSTEM_KWARGS), kwargs)
    return (system_kwargs)
end

"""
    function c_sys_case118(; kwargs...)

Constructs the system for the example Case 118.

"""
function c_sys_case118(; kwargs...)
    sys_kwargs = filter_kwargs(; kwargs...)
    # Build the System
    base_dir = "../examples/data/"
    c_sys_118 = PSY.System(joinpath(base_dir, "matpower", "case118.m"))
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
    # Loads timeseries
    timeseries_DA = [TimeArray(dates, loadz1_ts)]

    # Forecasts of the System
    if get(kwargs, :add_forecasts, true)
        forecast_data = SortedDict{Dates.DateTime, TimeSeries.TimeArray}()
        for (ix, l) in enumerate(PSY.get_components(PowerLoad, c_sys_118))
            ini_time = TimeSeries.timestamp(timeseries_DA[1])[1]
            forecast_data[ini_time] = timeseries_DA[1]
            PSY.add_time_series!(
                c_sys_118,
                l,
                PSY.Deterministic("max_active_power", forecast_data),
                )
        end
    end
    return c_sys_118
end
