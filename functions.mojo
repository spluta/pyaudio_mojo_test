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

fn quadratic_interpolation(y0: Float64, y1: Float64, y2: Float64, x: Float64) -> Float64:
    """Performs quadratic interpolation between three points.
    
    Args:
        y0: The value at position 0
        y1: The value at position 1
        y2: The value at position 2
        x: The interpolation position (typically between 0 and 2)
        
    Returns:
        The interpolated value at position x
    """
    # Calculate the coefficients of the quadratic polynomial
    var a = ((x - 1) * (x - 2)) * 0.5 * y0
    var b = (x * (x - 2)) * (-1.0) * y1
    var c = (x * (x - 1)) * 0.5 * y2

    # Return the estimated value
    return a + b + c

    # # Quadratic interpolation coefficients
    # var a = 0.5 * (y0 - 2.0 * y1 + y2)
    # var b = 0.5 * (y2 - y0)
    # var c = y1

    # # Calculate interpolated value with frac in range [0,1]
    # return a * frac * frac + b * frac + c 