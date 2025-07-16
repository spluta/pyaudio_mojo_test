from Buffer import Buffer
from VAMoogLadder import VAMoogLadder
from Osc import Osc
from functions import linexp
from random import random_float64
from memory import UnsafePointer

struct BufSynth(Defaultable, Representable, Movable):
    var sample_rate: Float64
    var buffer: Buffer
    var moog: List[VAMoogLadder]
    var mod: Osc

    fn __init__(out self):
        self.sample_rate = 44100.0  # Default sample rate
        self.buffer = Buffer()

        self.moog = List[VAMoogLadder]()
        self.mod = Osc(0.1, self.sample_rate)  # Initialize the main Osc with a default frequency


    fn init2(mut self, sample_rate: Float64, file_name: String) raises:
        self.sample_rate = sample_rate
        self.buffer.load_file(file_name)  # Load the sound file into the buffer
        self.buffer.set_sys_sample_rate(self.sample_rate)  # Set the sample rate for the buffer

        for _ in range(self.buffer.channels):
            self.moog.append(VAMoogLadder(200, self.sample_rate))

        for i in range(len(self.moog)):
            self.moog[i].set_sample_rate(self.sample_rate)

        self.mod.set_sample_rate(self.sample_rate)  # Set the sample rate for the modulator
    
    fn next(mut self) -> List[Float64]:
        var sample = self.buffer.next()
        var mod_val = self.mod.next()
        for i in range(self.buffer.channels):
            sample[i] = self.moog[i].next(sample[i], linexp(mod_val, -1.0, 1.0, 500.0, 20000.0), 0.5)

        return sample

    fn __repr__(self) -> String:
        return String("BufSynth")