from math import sin
from functions import *
from memory import Pointer

# struct OscBuffer(Representable, Movable, Copyable):
#     var buffer: InlineArray[Float64, 16384]

struct OscBuffers(Representable, Movable, Copyable):
    var buffers: List[InlineArray[Float64, 16384]]  # List of all waveform buffers

    var size: Int64

    fn __init__(out self):
        self.size = 16384
        self.buffers = List[InlineArray[Float64, 16384]]()
        for _ in range(7):  # Initialize buffers for sine, triangle, square, and sawtooth
            self.buffers.append(InlineArray[Float64, 16384](fill=0.0))
        self.init_sine()  # Initialize sine wave buffer
        self.init_triangle()  # Initialize triangle wave buffer
        self.init_sawtooth()  # Initialize sawtooth wave buffer
        self.init_square()  # Initialize square wave buffer
        self.init_triangle2()  # Initialize triangle wave buffer using harmonics
        self.init_sawtooth2()  # Initialize sawtooth wave buffer using harmonics
        self.init_square2()  # Initialize square wave buffer using harmonics

    fn init_sine(mut self: OscBuffers):
        for i in range(self.size):
            self.buffers[0][i] = (sin(2.0 * 3.141592653589793 * Float64(i) / Float64(self.size)))  # Precompute sine values

    fn init_triangle(mut self: OscBuffers):
        for i in range(self.size):
            if i < self.size // 2:
                self.buffers[1][i] = 2.0 * (Float64(i) / Float64(self.size)) - 1.0  # Ascending part
            else:
                self.buffers[1][i] = 1.0 - 2.0 * (Float64(i) / Float64(self.size))  # Descending part

    fn init_sawtooth(mut self: OscBuffers):
        for i in range(self.size):
            self.buffers[2][i] = 2.0 * (Float64(i) / Float64(self.size)) - 1.0  # Linear ramp from -1 to 1

    fn init_square(mut self: OscBuffers):
        for i in range(self.size):
            if i < self.size // 2:
                self.buffers[3][i] = 1.0  # First half is 1
            else:
                self.buffers[3][i] = -1.0  # Second half is -1

    fn init_triangle2(mut self: OscBuffers):
        # Construct triangle wave from sine harmonics
        # Triangle formula: 8/pi^2 * sum((-1)^(n+1) * sin(n*x) / n^2) for n=1 to 512
        for i in range(self.size):
            var x = 2.0 * 3.141592653589793 * Float64(i) / Float64(self.size)
            var sample: Float64 = 0.0
            
            for n in range(1, 513):  # Using 512 harmonics
                var harmonic = sin(Float64(n) * x) / (Float64(n) * Float64(n))
                if n % 2 == 0:  # (-1)^(n+1) is -1 when n is even
                    harmonic = -harmonic
                sample += harmonic
            
            # Scale by 8/π² for correct amplitude
            self.buffers[4][i] = 8.0 / (3.141592653589793 * 3.141592653589793) * sample

    fn init_sawtooth2(mut self: OscBuffers):
        # Construct sawtooth wave from sine harmonics
        # Sawtooth formula: 2/pi * sum((-1)^(n+1) * sin(n*x) / n) for n=1 to 512
        for i in range(self.size):
            var x = 2.0 * 3.141592653589793 * Float64(i) / Float64(self.size)
            var sample: Float64 = 0.0
            
            for n in range(1, 513):  # Using 512 harmonics
                var harmonic = sin(Float64(n) * x) / Float64(n)
                if n % 2 == 0:  # (-1)^(n+1) is -1 when n is even
                    harmonic = -harmonic
                sample += harmonic
            
            # Scale by 2/π for correct amplitude
            self.buffers[5][i] = 2.0 / 3.141592653589793 * sample

    fn init_square2(mut self: OscBuffers):
        # Construct square wave from sine harmonics
        # Square formula: 4/pi * sum(sin((2n-1)*x) / (2n-1)) for n=1 to 512
        for i in range(self.size):
            var x = 2.0 * 3.141592653589793 * Float64(i) / Float64(self.size)
            var sample: Float64 = 0.0
            
            for n in range(1, 513):  # Using 512 harmonics
                var harmonic = sin(Float64(2 * n - 1) * x) / Float64(2 * n - 1)
                sample += harmonic
            
            # Scale by 4/π for correct amplitude
            self.buffers[6][i] = 4.0 / 3.141592653589793 * sample

    fn __repr__(self) -> String:
        return String(
            "OscBuffers(size=" + String(self.size) + ")"
        )

    fn quadratic_interp_loc(self, x: Float64, buf_num: Int64) -> Float64:
        # Ensure indices are within bounds
        var mod_idx = Int64(x) % Int64(self.size)
        var mod_idx1 = (mod_idx + 1) % Int64(self.size)
        var mod_idx2 = (mod_idx + 2) % Int64(self.size)

        # Get the fractional part
        var frac = x - Float64(Int64(x))

        # Get the 3 sample values
        var y0 = self.buffers[buf_num][mod_idx]
        var y1 = self.buffers[buf_num][mod_idx1]
        var y2 = self.buffers[buf_num][mod_idx2]

        return quadratic_interpolation(y0, y1, y2, frac)

    fn lin_interp(self, x: Float64, buf_num: Int64) -> Float64:
        # Get indices for 2 adjacent points
        var index = Int64(x)
        var index_next = (index + 1) % self.size
        
        # Get the fractional part
        var frac = x - Float64(index)
        
        # Get the 2 sample values
        var y0 = self.buffers[buf_num][index]
        var y1 = self.buffers[buf_num][index_next]
        # Linear interpolation formula: y0 + frac * (y1 - y0)
        return y0 + frac * (y1 - y0)

    # Get the next sample from the buffer using linear interpolation
    # Needs to receive an unsafe pointer to the buffer being used
    fn next_lin(self, f_index: Float64, buf_num: Int64) -> Float64:
        var f_index2 = (f_index * Float64(self.size)) % Float64(self.size)
        var value = self.lin_interp(f_index2, buf_num)
        return value
        
    fn next_quadratic(self, f_index: Float64, buf_num: Int64) -> Float64:
        var f_index2 = (f_index * Float64(self.size)) % Float64(self.size)
        var value = self.quadratic_interp_loc(f_index2, buf_num)
        return value

    fn next(self, phase: Float64, osc_type: Int64 = 0, interp: Int64 = 0) -> Float64:
        if interp == 0:
            return self.next_lin(phase, osc_type)  # Linear interpolation
        elif interp == 1:
            return self.next_quadratic(phase, osc_type)  # Quadratic interpolation
        else:
            return self.next_lin(phase, osc_type)  # Default to linear interpolation


# struct OscBuffer(Representable, Movable, Copyable):
#     var buffer: InlineArray[Float64, 16384]  # List of all waveform buffers

#     var size: Int64

#     fn __init__(out self, type: Int64 = 0):
#         self.size = 16384
#         self.buffer = InlineArray[Float64, 16384](fill=0.0)
#         if type == 0:
#             self.init_sine()  # Initialize sine wave buffer
#         elif type == 1:
#             self.init_triangle()  # Initialize triangle wave buffer
#         elif type == 2:
#             self.init_sawtooth()  # Initialize sawtooth wave buffer
#         elif type == 3:
#             self.init_square()  # Initialize square wave buffer
#         elif type == 4:
#             self.init_triangle2()  # Initialize triangle wave buffer using harmonics
#         elif type == 5:
#             self.init_sawtooth2()  # Initialize sawtooth wave buffer using harmonics
#         elif type == 6:
#             self.init_square2()  # Initialize square wave buffer using harmonics

#     fn init_sine(mut self: OscBuffer):
#         for i in range(self.size):
#             self.buffer[i] = (sin(2.0 * 3.141592653589793 * Float64(i) / Float64(self.size)))  # Precompute sine values

#     fn init_triangle(mut self: OscBuffer):
#         for i in range(self.size):
#             if i < self.size // 2:
#                 self.buffer[i] = 2.0 * (Float64(i) / Float64(self.size)) - 1.0  # Ascending part
#             else:
#                 self.buffer[i] = 1.0 - 2.0 * (Float64(i) / Float64(self.size))  # Descending part

#     fn init_sawtooth(mut self: OscBuffer):
#         for i in range(self.size):
#             self.buffer[i] = 2.0 * (Float64(i) / Float64(self.size)) - 1.0  # Linear ramp from -1 to 1

#     fn init_square(mut self: OscBuffer):
#         for i in range(self.size):
#             if i < self.size // 2:
#                 self.buffer[i] = 1.0  # First half is 1
#             else:
#                 self.buffer[i] = -1.0  # Second half is -1

#     fn init_triangle2(mut self: OscBuffer):
#         # Construct triangle wave from sine harmonics
#         # Triangle formula: 8/pi^2 * sum((-1)^(n+1) * sin(n*x) / n^2) for n=1 to 512
#         for i in range(self.size):
#             var x = 2.0 * 3.141592653589793 * Float64(i) / Float64(self.size)
#             var sample: Float64 = 0.0
            
#             for n in range(1, 513):  # Using 512 harmonics
#                 var harmonic = sin(Float64(n) * x) / (Float64(n) * Float64(n))
#                 if n % 2 == 0:  # (-1)^(n+1) is -1 when n is even
#                     harmonic = -harmonic
#                 sample += harmonic
            
#             # Scale by 8/π² for correct amplitude
#             self.buffer[i] = 8.0 / (3.141592653589793 * 3.141592653589793) * sample

#     fn init_sawtooth2(mut self: OscBuffer):
#         # Construct sawtooth wave from sine harmonics
#         # Sawtooth formula: 2/pi * sum((-1)^(n+1) * sin(n*x) / n) for n=1 to 512
#         for i in range(self.size):
#             var x = 2.0 * 3.141592653589793 * Float64(i) / Float64(self.size)
#             var sample: Float64 = 0.0
            
#             for n in range(1, 513):  # Using 512 harmonics
#                 var harmonic = sin(Float64(n) * x) / Float64(n)
#                 if n % 2 == 0:  # (-1)^(n+1) is -1 when n is even
#                     harmonic = -harmonic
#                 sample += harmonic
            
#             # Scale by 2/π for correct amplitude
#             self.buffer[i] = 2.0 / 3.141592653589793 * sample

#     fn init_square2(mut self: OscBuffer):
#         # Construct square wave from sine harmonics
#         # Square formula: 4/pi * sum(sin((2n-1)*x) / (2n-1)) for n=1 to 512
#         for i in range(self.size):
#             var x = 2.0 * 3.141592653589793 * Float64(i) / Float64(self.size)
#             var sample: Float64 = 0.0
            
#             for n in range(1, 513):  # Using 512 harmonics
#                 var harmonic = sin(Float64(2 * n - 1) * x) / Float64(2 * n - 1)
#                 sample += harmonic
            
#             # Scale by 4/π for correct amplitude
#             self.buffer[i] = 4.0 / 3.141592653589793 * sample

#     fn __repr__(self) -> String:
#         return String(
#             "OscBuffers(size=" + String(self.size) + ")"
#         )

#     fn quadratic_interp_loc(self, x: Float64, buf_num: Int64) -> Float64:
#         # Ensure indices are within bounds
#         var mod_idx = Int64(x) % Int64(self.size)
#         var mod_idx1 = (mod_idx + 1) % Int64(self.size)
#         var mod_idx2 = (mod_idx + 2) % Int64(self.size)

#         # Get the fractional part
#         var frac = x - Float64(Int64(x))

#         # Get the 3 sample values
#         var y0 = self.buffer[mod_idx]
#         var y1 = self.buffer[mod_idx1]
#         var y2 = self.buffer[mod_idx2]

#         return quadratic_interpolation(y0, y1, y2, frac)

#     fn lin_interp(self, x: Float64, buf_num: Int64) -> Float64:
#         # Get indices for 2 adjacent points
#         var index = Int64(x)
#         var index_next = (index + 1) % self.size
        
#         # Get the fractional part
#         var frac = x - Float64(index)
        
#         # Get the 2 sample values
#         var y0 = self.buffer[index]
#         var y1 = self.buffer[index_next]
#         # Linear interpolation formula: y0 + frac * (y1 - y0)
#         return y0 + frac * (y1 - y0)

#     # Get the next sample from the buffer using linear interpolation
#     # Needs to receive an unsafe pointer to the buffer being used
#     fn next_lin(self, f_index: Float64, buf_num: Int64) -> Float64:
#         var f_index2 = (f_index * Float64(self.size)) % Float64(self.size)
#         var value = self.lin_interp(f_index2, buf_num)
#         return value
        
#     fn next_quadratic(self, f_index: Float64, buf_num: Int64) -> Float64:
#         var f_index2 = (f_index * Float64(self.size)) % Float64(self.size)
#         var value = self.quadratic_interp_loc(f_index2, buf_num)
#         return value

# from math import sin
# from functions import *