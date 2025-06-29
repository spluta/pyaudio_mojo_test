fn linlin(value: Float64, in_min: Float64, in_max: Float64, out_min: Float64, out_max: Float64) -> Float64:
    """Maps a value from one range to another range.

    Args:
        value: The value to map
        in_min: The minimum of the input range
        in_max: The maximum of the input range
        out_min: The minimum of the output range
        out_max: The maximum of the output range
        
    Returns:
        The mapped value in the output range
    """
    # First scale to 0..1 range, then scale to output range
    var normalized = (value - in_min) / (in_max - in_min)
    return normalized * (out_max - out_min) + out_min

fn linexp(value: Float64, in_min: Float64, in_max: Float64, out_min: Float64, out_max: Float64) -> Float64:
    """Maps a value from one linear range to another exponential range.

    Args:
        value: The value to map
        in_min: The minimum of the input range
        in_max: The maximum of the input range
        out_min: The minimum of the output range (must be > 0)
        out_max: The maximum of the output range (must be > 0)
        
    Returns:
        The exponentially mapped value in the output range
    """
    # First scale to 0..1 range linearly, then apply exponential scaling
    var normalized = (value - in_min) / (in_max - in_min)
    return out_min * pow(out_max / out_min, normalized)

fn clip(val: Float64, lo: Float64, hi: Float64) -> Float64:
    if val < lo:
        return lo
    elif val > hi:
        return hi
    else:
        return val