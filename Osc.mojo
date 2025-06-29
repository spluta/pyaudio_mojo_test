from math import sin

struct SineBuffer(Representable, Movable, Copyable):
    var buffer: List[Float64]
    var size: Int64

    fn __init__(out self, size: Int64 = 16384):
        self.size = size
        self.buffer = List[Float64]()
        for i in range(size):
            self.buffer.append(sin(2.0 * 3.141592653589793 * Float64(i) / Float64(size)))  # Precompute sine values

    fn __repr__(self) -> String:
        return String(
            "SinBuffer(size=" + String(self.size) + ")"
        )

    fn quadratic_interp(self, x: Float64) -> Float64:
        # Get indices for 3 adjacent points
        var index = Int64(x)
        var index_prev = (index + self.size - 1) % self.size
        var index_next = (index + 1) % self.size
        
        # Get the fractional part
        var frac = x - Float64(index)
        
        # Get the 3 sample values
        var y0 = self.buffer[index_prev]
        var y1 = self.buffer[index]
        var y2 = self.buffer[index_next]
        
        # Quadratic interpolation formula: a*x^2 + b*x + c
        # where x is between -1 and 1 (centered around the middle point)
        var a = 0.5 * (y0 - 2.0 * y1 + y2)
        var b = 0.5 * (y2 - y0)
        var c = y1
        
        # Calculate interpolated value with frac in range [0,1]
        # Adjusting frac to be in [-1,1] for the formula
        var x_adj = frac * 2.0 - 1.0
        return a * x_adj * x_adj + b * x_adj + c

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

    fn process(self, f_index: Float64) -> Float64:
        var f_index2 = (f_index * Float64(self.size)) % Float64(self.size)
        # print("f_index: ", f_index2)  # Debugging output
        var value = self.lin_interp(f_index2)
        # var value = self.cubic_interp(f_index2)
        return value

struct Osc(Representable, Movable, Copyable):
    var phase: Float64
    var freq: Float64
    var freq_mul: Float64 
    var sine_buffer: SineBuffer

    fn __init__(out self, freq: Float64 = 100.0, sample_rate: Float64 = 44100.0):
        self.phase = 0.0
        self.freq = freq
        self.freq_mul = 1.0 / sample_rate
        self.sine_buffer = SineBuffer()

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
        return self.sine_buffer.process(self.phase)