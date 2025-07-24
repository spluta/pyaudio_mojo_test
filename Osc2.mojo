

# struct Osc(Representable, Movable, Copyable):
#     var phase: Float64
#     var freq: Float64
#     var freq_mul: Float64 
#     var sine_buffer: OscBuffers
#     var max_sinc_offset: Int
#     var sinc_len: Int
#     var sinc_half_len: Int
#     var sinc_points: List[Float64]  # Points for sinc interpolation
#     var sinc_table_size: Int
#     var sinc_table: List[Float64]  # Sinc table for interpolation

#     fn __init__(out self, freq: Float64 = 100.0, sample_rate: Float64 = 44100.0, type: Int64 = 0, sinc_table_size: Int = 8192):
#         self.phase = 0.0
#         self.freq = freq
#         self.freq_mul = 1.0 / sample_rate
#         self.sine_buffer = OscBuffers(16384, type)  # Initialize with a sine wave buffer of size 16384
#         self.max_sinc_offset = 1024  # Set a default max sinc offset

#         self.sinc_len = 64
#         self.sinc_points = [0.0] * self.sinc_len  # Initialize sinc points
#         for i in range(self.sinc_len):
#             self.sinc_points[i] = Float64(i) / Float64(self.sinc_len - 1)  # Fill sinc points with normalized values
        
#         self.sinc_half_len = self.sinc_len // 2  # Half length for sinc interpolation
#         self.sinc_table_size = sinc_table_size
#         self.sinc_table = List[Float64](self.sinc_table_size, 0.0)  # Initialize sinc table with zeros
#         self.sinc_table = self.create_sinc_table(self.sinc_table_size, 8)  # Create sinc table with 8 ripples

#     fn __repr__(self) -> String:
#         return String(
#             "Osc"
#         )
    
#     fn set_sample_rate(mut self: Osc, sample_rate: Float64):
#         self.freq_mul = 1.0 / sample_rate

#     fn next(mut self: Osc) -> Float64:
#         self.phase += (self.freq*self.freq_mul)
#         if self.phase >= 1.0:
#             self.phase -= 1.0
#         return self.sine_buffer.next(self.phase)

#     fn create_sinc_table(mut self: Osc, n_points: Int, ripples: Int) -> List[Float64]:
#         """
#         Create a sinc table with specified number of points and ripples.

#         Args:
#             n_points: Number of points in the table
#             ripples: Number of zero-crossings (ripples) on each side of the main lobe
        
#         Returns:
#             List of sinc table values
#         """
#         var table = List[Float64](n_points, 0.0)
#         var center = n_points//2 - 1
        
#         for i in range(n_points):
#             if i == center:
#                 # Avoid division by zero at the center point
#                 table[i] = 1.0
#             else:
#                 # Calculate the normalized distance from center (-ripples*pi to ripples*pi)
#                 var x = (Float64(i) - center) / center * ripples * 3.141592653589793
#                 # Calculate sinc value: sin(x)/x
#                 table[i] = sin(x) / x

#         return table

#     fn get_spaced_out(
#         self: Osc,
#         buf_data: UnsafePointer[SIMD[DType.float64, 1]],
#         ramp: Float64,
#         buf_divs: Float64,
#         buf_loc: Float64,
#         each_table_size: Int,
#         fmaxindex: Float64,
#         spacing1: Int,
#         sinc_crossfade: Float64,
#         num_chans: Int,
#         chan_loc: Int
#     ) -> Float64:
#         """Get spaced out value using sinc interpolation."""
        
#         # Now that we have the ramp, use it to get the value from the buffer
#         var spacing2 = spacing1 * 2

#         var clipped_buf_loc = max(0.0, min(buf_loc, 1.0)) * (buf_divs - 1.0)
#         var ibuf_loc = Int(clipped_buf_loc)

#         var findex = ramp * fmaxindex
#         var ibuf_divs = Int(buf_divs)
#         var out: Float64

#         var frac_loc = clipped_buf_loc - Float64(ibuf_loc)

#         var sinc1 = self.get_spaced_sinc_sum(buf_data, each_table_size, findex, spacing1, ibuf_loc, num_chans, chan_loc)
#         var sinc2: Float64 = 0.0
#         var outA: Float64 = 0.0
        
#         # We only need to calculate sinc2 if we aren't in the top octave
#         if spacing1 < self.max_sinc_offset:
#             sinc2 = self.get_spaced_sinc_sum(buf_data, each_table_size, findex, spacing2, ibuf_loc, num_chans, chan_loc)
#             outA = sinc1 * (1.0 - sinc_crossfade) + sinc2 * sinc_crossfade
#         else:
#             outA = sinc1

#         var outB: Float64 = 0.0
#         if ibuf_loc < ibuf_divs - 1:
#             sinc1 = self.get_spaced_sinc_sum(buf_data, each_table_size, findex, spacing1, ibuf_loc + 1, num_chans, chan_loc)
#             if spacing1 < self.max_sinc_offset:
#                 sinc2 = self.get_spaced_sinc_sum(buf_data, each_table_size, findex, spacing2, ibuf_loc + 1, num_chans, chan_loc)
#                 outB = sinc1 * (1.0 - sinc_crossfade) + sinc2 * sinc_crossfade
#             else:
#                 outB = sinc1

#         out = outA * (1.0 - frac_loc) + outB * frac_loc
#         return out

#     fn get_spaced_sinc_sum(
#         self: Osc,
#         table: UnsafePointer[SIMD[DType.float64, 1]],
#         table_size: Int,
#         findex: Float64,
#         spacing: Int,
#         ibuf_loc: Int,
#         num_chans: Int,
#         chan_loc: Int
#     ) -> Float64:
#         """Calculate spaced sinc sum with quadratic interpolation."""
        
#         var sinc_sum: Float64 = 0.0

#         # zero_index is the index of the first sample of the small table inside the big table
#         var zero_index = ibuf_loc * table_size
#         var sinc_mult = self.max_sinc_offset // spacing
#         var index = Int(findex)
#         var frac = findex - Float64(index)
        
#         for sp in range(self.sinc_len):
#             # The exact point along the 1D table
#             var loc_point = index + ((sp - self.sinc_half_len) * spacing)
#             loc_point = wrap(loc_point, 0, table_size - 1)
            
#             # Round to the nearest spacing
#             var spaced_point_base = (loc_point // spacing) * spacing

#             # The offset from the exact point to the nearest spacing
#             var sinc_offset2 = loc_point - spaced_point_base

#             # Add the zero index to shift to the correct table
#             var spaced_point = spaced_point_base + zero_index

#             # Quadratic interpolation
#             var sinc_indexA = self.sinc_points[sp] - (sinc_offset2 * sinc_mult)
#             var sinc_indexB = sinc_indexA - 1
#             var sinc_indexC = sinc_indexA - 2

#             sinc_indexA = wrap(sinc_indexA, 0, self.sinc_table_size - 1)
#             var wrapped_sinc_indexB = wrap(sinc_indexB, 0, self.sinc_table_size - 1)
#             var wrapped_sinc_indexC = wrap(sinc_indexC, 0, self.sinc_table_size - 1)

#             var sinc_val = quadratic_interpolation(
#                 self.sinc_table[sinc_indexA],
#                 self.sinc_table[wrapped_sinc_indexB], 
#                 self.sinc_table[wrapped_sinc_indexC],
#                 frac
#             )

#             sinc_sum += sinc_val * table[spaced_point]

#         return sinc_sum