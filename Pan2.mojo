from functions import clip

struct Pan2 (Defaultable, Representable, Movable, Copyable):
    var pan: Float64  # Pan value between -1.0 (left) and 1.0 (right)
    var output: List[Float64]  # Output list for stereo output

    fn __init__(out self):
        self.pan = 0.0  # Pan value between -1.0 (left) and 1.0 (right)
        self.output = List[Float64](2, 0.0)  # Initialize output list for stereo output

    fn __repr__(self) -> String:
        return String("Pan2")

    fn set_pan(mut self, mut pan: Float64):
        self.pan = clip(pan, -1.0, 1.0)  # Set the pan value
        

    fn next(mut self, sample: Float64, pan: Float64) -> List[Float64]:
        # Calculate left and right channel samples based on pan value
        self.pan = clip(pan, -1.0, 1.0)  # Ensure pan is set and clipped before processing
        var left = sample * (1.0 - self.pan) / 2  # Left channel
        var right = sample * (1.0 + self.pan) / 2  # Right channel

        self.output[0] = left
        self.output[1] = right
        return self.output  # Return stereo output as List