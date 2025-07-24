from Osc import Osc
from random import random_float64
from Pan2 import Pan2
from World import World
from OscBuffers import OscBuffers

struct OscSynth(Representable, Movable):
    var oscs: List[Osc]  # List of Osc instances
    var sample_rate: Float64
    var pans: List[Pan2]  # List of Pan2 instances for stereo panning
    var pan_oscs: List[Osc]  
    var pan_freqs: List[Float64] # Frequencies for panning oscillators
    var osc_sum: List[Float64]  # Sum of oscillator outputs for stereo output
    var freqs: List[Float64]  # Frequencies for each oscillator

    fn __init__(out self, world: World):
        self.sample_rate = world.sample_rate
        self.oscs = List[Osc]()
        self.pans = List[Pan2]()
        self.pan_oscs = List[Osc]()
        self.freqs = List[Float64]()
        self.pan_freqs = List[Float64]()

        self.osc_sum = List[Float64](2, 0.0)  # Initialize with two zeros for stereo output
        
        for _ in range(4):
            var rand = random_float64() * 1000.0 + 100.0
            self.freqs.append(rand)
            self.freqs.append(rand+(random_float64() * 10.0))  # Add a small random variation
            self.oscs.append(Osc(world, 0))
            self.oscs.append(Osc(world, 0))

        for _ in range(len(self.oscs)):
            self.pans.append(Pan2())  # Initialize Pan2 instances for each Osc
            self.pan_oscs.append(Osc(world, 1))  # Initialize Pan2 instances for each Osc
            self.pan_freqs.append(random_float64() * 0.05 + 0.05)  # Add random frequency for panning

        print(len(self.pan_oscs), " pan_oscs")
        self.pans.append(Pan2())

    # fn init2(mut self, sample_rate: Float64):
    #     self.sample_rate = sample_rate
    #     for i in range(len(self.oscs)):
    #         self.oscs[i].set_sample_rate(sample_rate)  # Set sample rate for each Osc
    #         self.pan_oscs[i].set_sample_rate(sample_rate)  # Set sample rate for

    fn __repr__(self) -> String:
        return String("OscSynth")

    fn next(mut self, world: World) -> List[Float64]:
        for i in range(len(self.osc_sum)):
            self.osc_sum[i] = 0.0  # Reset the sum for each call
        # var osc_buffers = world.osc_buffers  # Get the OscBuffers instance from the World
        for i in range(len(self.oscs)):
            var osc_value = self.oscs[i].next(world.osc_buffers, self.freqs[i])  # Get the next value from the Osc

            var pan_value = self.pan_oscs[i % len(self.pan_oscs)].next(world.osc_buffers, self.pan_freqs[i])  # Get pan position

            var osc_value2 = self.pans[i % len(self.pans)].next(osc_value[0], pan_value[0])  # Apply panning

            self.osc_sum[0] += osc_value2[0]  # Add left channel value
            self.osc_sum[1] += osc_value2[1]  # Add right channel value

        for i in range(len(self.osc_sum)):
            self.osc_sum[i] /= Float64(len(self.oscs) * 20)  # Normalize the sum

        return self.osc_sum
