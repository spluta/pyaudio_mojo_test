from functions import clip

struct Pan2 (Defaultable, Representable, Movable, Copyable):
    var pan: Float64  # Pan value between -1.0 (left) and 1.0 (right)

    fn __init__(out self):
        self.pan = 0.0  # Pan value between -1.0 (left) and 1.0 (right)

    fn __repr__(self) -> String:
        return String("Pan2")

    fn set_pan(mut self, mut pan: Float64):
        self.pan = clip(pan, -1.0, 1.0)  # Set the pan value
        

    fn next(mut self, sample: Float64, pan: Float64) -> InlineArray[Float64, 2]:
        # Calculate left and right channel samples based on pan value
        self.pan = pan  # Ensure pan is set before processing
        var left = sample * (1.0 - self.pan) / 2  # Left channel
        var right = sample * (1.0 + self.pan) / 2  # Right channel

        return InlineArray[Float64, 2](left, right)  # Return stereo output