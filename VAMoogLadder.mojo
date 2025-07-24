from math import tan, pi, tanh
from functions import clip
from World import World

struct VAMoogLadder(Representable, Movable, Copyable):
    var nyquist: Float64
    var step_val: Float64
    var last_1: Float64
    var last_2: Float64
    var last_3: Float64
    var last_4: Float64

    fn __init__(out self, world: World, freq: Float64 = 100.0):
        self.nyquist = world.sample_rate * 0.5
        self.step_val = 1.0 / world.sample_rate
        self.last_1 = 0.0
        self.last_2 = 0.0
        self.last_3 = 0.0
        self.last_4 = 0.0

    fn __repr__(self) -> String:
        return String(
            "VAMoogLadder"
        )

    fn next(mut self, sig: Float64, freq: Float64, q_val: Float64) -> Float64:
        var cf = clip(freq, 0.0, self.nyquist * 0.6)
        
        # k is the feedback coefficient of the entire circuit
        var k = 4.0 * q_val
        
        var omegaWarp = tan(pi * cf * self.step_val)
        var g = omegaWarp / (1.0 + omegaWarp)
        
        var g4 = g * g * g * g
        var s4 = g * g * g * (self.last_1 * (1 - g)) + g * g * (self.last_2 * (1 - g)) + g * (self.last_3 * (1 - g)) + (self.last_4 * (1 - g))
        
        # internally clips the feedback signal to prevent the filter from blowing up
        if s4 > 1.0:
            s4 = tanh(s4 - 1.0) + 1.0
        elif s4 < -2.0:
            s4 = tanh(s4 + 1.0) - 1.0
        
        # input is the incoming signal minus the feedback from the last stage
        var input = (sig - k * s4) / (1.0 + k * g4)
        
        var v1 = g * (input - self.last_1)
        var lp1 = self.last_1 + v1
        
        var v2 = g * (lp1 - self.last_2)
        var lp2 = self.last_2 + v2
        
        var v3 = g * (lp2 - self.last_3)
        var lp3 = self.last_3 + v3
        
        var v4 = g * (lp3 - self.last_4)
        var lp4 = self.last_4 + v4
        
        self.last_1 = lp1
        self.last_2 = lp2
        self.last_3 = lp3
        self.last_4 = lp4
        
        return lp4
