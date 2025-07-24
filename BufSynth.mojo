from Buffer import Buffer
from VAMoogLadder import VAMoogLadder
from Osc import Osc
from functions import linexp
from random import random_float64
from memory import UnsafePointer
from World import World
from PlayBuf import PlayBuf
from OscBuffers import OscBuffers

struct BufSynth(Representable, Movable):
    var sample_rate: Float64
    var num_chans: Int64
    var moog: List[VAMoogLadder]
    var mod: Osc
    var buf_speed: Osc
    var playBuf: PlayBuf
    var buffer: Buffer  # Instance of Buffer to hold sound data

    fn __init__(out self, world: World):
        self.sample_rate = world.sample_rate
        self.buffer = Buffer(world, "Shiverer.wav")  # Initialize the buffer
        self.num_chans = self.buffer.num_chans  # Use the number of channels from the buffer

        self.buf_speed = Osc(world)  # Initialize the buffer speed oscillator

        self.playBuf = PlayBuf(world, self.num_chans)  # Initialize PlayBuf with the number of channels

        self.moog = List[VAMoogLadder]()
        for _ in range(self.num_chans):
            self.moog.append(VAMoogLadder(world))  # Initialize VAMoogLadder instances for each channel

        self.mod = Osc(world)  # Initialize the main Osc with a default frequency


    fn next(mut self, osc_buffers: OscBuffers) -> List[Float64]:
        var buf_speed_val = linexp(self.buf_speed.next(osc_buffers, 0.05, 0), -1.0, 1.0, 0.5, 2.0)  # Get the buffer speed value from the Osc

        var sample = self.playBuf.next(self.buffer, buf_speed_val)
        var mod_val = self.mod.next(osc_buffers, 0.1, 1)  # Get the modulation value from the Osc
        
        for i in range(self.num_chans):
            sample[i] = self.moog[i].next(sample[i], linexp(mod_val, -1.0, 1.0, 500.0, 20000.0), 0.5)

        return sample

    fn __repr__(self) -> String:
        return String("BufSynth")