from python import PythonObject
from python import Python
from memory import UnsafePointer
from Buffer import Buffer
from World import World

alias dtype = DType.float64

struct PlayBuf (Representable, Movable):
    var phase: Float64  # Current phase of the buffer
    var num_chans: Int64  # Number of channels in the buffer
    var out_list: List[Float64]  # Output list for samples
    var sample_rate: Float64

    fn __init__(out self, world: World, num_chans: Int64 = 1):
        self.phase = 0.0
        self.num_chans = num_chans
        self.sample_rate = world.sample_rate  # Sample rate from the World instance
        self.out_list = List[Float64]()  # Initialize output list
        for _ in range(num_chans):
            self.out_list.append(0.0)  # Initialize output list with zeros

    fn __repr__(self) -> String:
        return String("PlayBuf")

    fn next(mut self: PlayBuf, mut buffer: Buffer, rate: Float64, loop: Bool = True) -> List[Float64]:
        # Calculate the step size based on the rate and number of channels
        var step = buffer.step * rate 

        self.phase += step  # Increment the phase

        if loop:
            # Loop the phase if it exceeds 1.0
            if self.phase >= 1.0:
                self.phase -= 1.0
            elif self.phase < 0.0:
                self.phase += 1.0  # Ensure phase is always positive
        else:
            # if not looping and out of range, return zeros
            if self.phase >= 1.0 or self.phase < 0.0:
                for i in range(self.num_chans):
                    self.out_list[i] = 0.0
                return self.out_list  # Return zeros if phase is out of bounds

        for i in range(self.num_chans):
            self.out_list[i] = buffer.next(i, self.phase, 1)  # Read the sample from the buffer at the current phase

        return self.out_list  # Return the output list with samples