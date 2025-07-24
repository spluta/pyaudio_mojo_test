from math import sin
from functions import quadratic_interpolation
from World import World
from OscBuffers import OscBuffers
from Buffer import Buffer

struct Osc(Representable, Movable, Copyable):
    var phase: Float64
    var freq_mul: Float64
    var buf_type: Int64

    fn __init__(out self, world: World, buf_type: Int64 = 0):
        self.phase = 0.0
        self.freq_mul = 1.0 / world.sample_rate  # world.sample_rat
        self.buf_type = buf_type

    fn __repr__(self) -> String:
        return String(
            "Osc"
        )
    
    fn set_sample_rate(mut self: Osc, sample_rate: Float64):
        self.freq_mul = 1.0 / sample_rate

    fn increment_phase(mut self: Osc, freq: Float64):
        self.phase += (freq * self.freq_mul)
        if self.phase >= 1.0:
            self.phase -= 1.0
        elif self.phase < 0.0:
            self.phase += 1.0  # Ensure phase is always positive

    fn next(mut self: Osc, osc_buffers: OscBuffers, freq: Float64 = 100.0, osc_type: Int64 = 0, interp: Int64 = 0) -> Float64:
        self.increment_phase(freq)

        var sample: Float64 = osc_buffers.next(self.phase, osc_type, interp)  # Get the next sample from the Oscillator buffer
        return sample

    # for any buffer that is not an OscBuffer
    fn next(mut self: Osc, mut buffer: Buffer, freq: Float64 = 100.0, interp: Int64 = 0) -> Float64:
        self.increment_phase(freq)

        var sample: Float64 = buffer.next(0, self.phase, interp)  # Get the next sample from the Buffer
        return sample
