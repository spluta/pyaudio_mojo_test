from Osc import Osc
from random import random_float64
from Pan2 import Pan2

struct OscSynth(Defaultable, Representable, Movable):
    var oscs: List[Osc]  # List of Osc instances
    var sample_rate: Float64
    var pans: List[Pan2]  # List of Pan2 instances for stereo panning
    var pan_oscs: List[Osc]  

    fn __init__(out self):
        self.sample_rate = 44100.0
        self.oscs = List[Osc]()
        self.pans = List[Pan2]()
        self.pan_oscs = List[Osc]()
        for _ in range(4):
            var rand = random_float64() * 1000.0 + 100.0
            self.oscs.append(Osc(rand, self.sample_rate))
            self.oscs.append(Osc(rand+(random_float64()*3.0+0.1), self.sample_rate))

        for _ in range(len(self.oscs)):
            self.pans.append(Pan2())  # Initialize Pan2 instances for each Osc
            self.pan_oscs.append(Osc(random_float64()*0.4+0.1, self.sample_rate))  # Initialize Pan2 instances for each Osc
        print(len(self.pan_oscs), "pan_oscs")
        self.pans.append(Pan2())

    fn init2(mut self, sample_rate: Float64):
        self.sample_rate = sample_rate
        for i in range(len(self.oscs)):
            self.oscs[i].set_sample_rate(sample_rate)  # Set sample rate for each Osc
            self.pan_oscs[i].set_sample_rate(sample_rate)  # Set sample rate for

    fn __repr__(self) -> String:
        return String("OscSynth")

    fn next(mut self) -> InlineArray[Float64, 2]:
        var osc_sum: InlineArray[Float64, 2] = InlineArray[Float64, 2](0.0, 0.0)  # Initialize sum of Oscss

        for i in range(len(self.oscs)):
            # var pan = self.pans[i % len(self.pans)].next()  # Use modulo to cycle through Pan2 instances

            var osc_value = self.oscs[i].next()  # Get the next value from the Osc
            var pan_value = self.pan_oscs[i % len(self.pan_oscs)].next()  # Apply panning to the Osc value
            var osc_value2 = self.pans[i % len(self.pans)].next(osc_value[0], pan_value[0])  # Apply panning to the Osc value

            osc_sum[0] += osc_value2[0]  # Add left channel value
            osc_sum[1] += osc_value2[1]  # Add right channel value

        for i in range(len(osc_sum)):
            osc_sum[i] /= Float64(len(self.oscs) * 20)  # Normalize the sum of Oscs

        return osc_sum
        