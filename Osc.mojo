from math import sin
from functions import quadratic_interpolation

struct OscBuffer(Representable, Movable, Copyable):
    var buffer: List[Float64]
    var size: Int64

    fn __init__(out self, size: Int64 = 16384, type: Int64 = 0):
        self.size = size
        self.buffer = List[Float64]()
        if type == 0:  # Sine wave
            self.init_sine(size)
        elif type == 1:  # Triangle wave
            self.init_triangle(size)
        elif type == 2:  # Square wave
            self.init_square(size)
        elif type == 3:  # Sawtooth wave
            self.init_sawtooth(size)
        else:
            self.init_sine(size)  # Default to sine wave if type is unknown

    fn init_sine(mut self: OscBuffer, size: Int64):
        for i in range(size):
            self.buffer.append(sin(2.0 * 3.141592653589793 * Float64(i) / Float64(size)))  # Precompute sine values
    
    fn init_square(mut self: OscBuffer, size: Int64):
        for i in range(size):
            if i < size // 2:
                self.buffer.append(1.0)  # First half is 1
            else:
                self.buffer.append(-1.0)  # Second half is -1

    fn init_sawtooth(mut self: OscBuffer, size: Int64):
        for i in range(size):
            self.buffer.append(2.0 * (Float64(i) / Float64(size))
                            - 0.5)  # Linear ramp from -1 to 1
    
    fn init_triangle(mut self: OscBuffer, size: Int64):
        for i in range(size):
            if i < size // 2:
                self.buffer.append(2.0 * (Float64(i) / Float64(size)) - 1.0)  # Ascending part
            else:
                self.buffer.append(1.0 - 2.0 * (Float64(i) / Float64(size)))  # Descending part

    fn __repr__(self) -> String:
        return String(
            "SinBuffer(size=" + String(self.size) + ")"
        )

    fn quadratic_interp_loc(self, x: Float64) -> Float64:
        # Ensure indices are within bounds
        var mod_idx = Int64(x) % Int64(self.size)
        var mod_idx1 = (mod_idx + 1) % Int64(self.size)
        var mod_idx2 = (mod_idx + 2) % Int64(self.size)

        # Get the fractional part
        var frac = x - Float64(Int64(x))

        # Get the 3 sample values
        var y0 = self.buffer[mod_idx]
        var y1 = self.buffer[mod_idx1]
        var y2 = self.buffer[mod_idx2]

        return quadratic_interpolation(y0, y1, y2, frac)

    fn lin_interp(self, x: Float64) -> Float64:
        # Get indices for 2 adjacent points
        var index = Int64(x)
        var index_next = (index + 1) % self.size
        
        # Get the fractional part
        var frac = x - Float64(index)
        
        # Get the 2 sample values
        var y0 = self.buffer[index]
        var y1 = self.buffer[index_next]
        
        # Linear interpolation formula: y0 + frac * (y1 - y0)
        return y0 + frac * (y1 - y0)

    fn next(self, f_index: Float64) -> Float64:
        var f_index2 = (f_index * Float64(self.size)) % Float64(self.size)
        var value = self.lin_interp(f_index2)
        return value

struct Osc(Representable, Movable, Copyable):
    var phase: Float64
    var freq: Float64
    var freq_mul: Float64 
    var sine_buffer: OscBuffer

    fn __init__(out self, freq: Float64 = 100.0, sample_rate: Float64 = 44100.0, type: Int64 = 0):
        self.phase = 0.0
        self.freq = freq
        self.freq_mul = 1.0 / sample_rate
        self.sine_buffer = OscBuffer(16384, type)  # Initialize with a sine wave buffer of size 16384

    fn __repr__(self) -> String:
        return String(
            "Osc"
        )
    
    fn set_sample_rate(mut self: Osc, sample_rate: Float64):
        self.freq_mul = 1.0 / sample_rate

    fn next(mut self: Osc) -> Float64:
        self.phase += (self.freq*self.freq_mul)
        if self.phase >= 1.0:
            self.phase -= 1.0
        return self.sine_buffer.next(self.phase)