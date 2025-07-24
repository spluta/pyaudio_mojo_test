from OscBuffers import OscBuffers

struct World(Representable, Movable):
    var sample_rate: Float64
    var block_size: Int64
    var osc_buffers: OscBuffers  # Instance of OscBuffers for managing oscillator buffers

    fn __init__(out self, sample_rate: Float64 = 48000.0, block_size: Int64 = 64):
        self.sample_rate = sample_rate
        self.block_size = block_size
        self.osc_buffers = OscBuffers()
        print("World initialized with sample rate:", self.sample_rate, "and block size:", self.block_size)
    
    fn __repr__(self) -> String:
        return "World(sample_rate: " + String(self.sample_rate) + ", block_size: " + String(self.block_size) + ")"
