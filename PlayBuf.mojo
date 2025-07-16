from python import PythonObject
from python import Python
from memory import UnsafePointer

alias dtype = DType.float64

struct Buffer(Defaultable, Representable, Movable):
    var size: Float64  # Size of the buffer
    var buf_sample_rate: Float64  # Sample rate for the buffer
    var sys_sample_rate: Float64  # System sample rate
    var step: Float64  # Step size for reading samples
    var data: UnsafePointer[SIMD[dtype, 1]]  # Pointer to the sound data, e.g., a NumPy array
    var scipy: PythonObject # Placeholder for SciPy or similar library
    var np: PythonObject  # Placeholder for NumPy or similar library
    var index: Float64  # Index for reading sound file data
    var channels: Int64  # Number of channels
    
    fn __init__(out self):
        self.data = UnsafePointer[SIMD[dtype, 1]]()
        self.index = 0.0
        self.size = 0.0
        self.step = 1.0  # Step size for reading samples
        self.buf_sample_rate = 44100.0  # Default sample rate
        self.sys_sample_rate = 44100.0  # Default system sample rate
        self.channels = 2  # Default number of channels (e.g., stereo)

        try:
            self.scipy = Python.import_module("scipy")
        except:
            print("Warning: Failed to import SciPy module")
            self.scipy = PythonObject(None)
        try:
            self.np = Python.import_module("numpy")
        except:
            print("Warning: Failed to import NumPy module")
            self.np = PythonObject(None)

    fn set_sys_sample_rate(mut self, sample_rate: Float64):
        self.sys_sample_rate = sample_rate
        self.step = self.buf_sample_rate / self.sys_sample_rate  # Update step based on system sample rate
        print(self.step)

    fn __repr__(self) -> String:
        return String("Synth")

    fn quadratic_interp(self, idx: Int64, idx1: Int64, idx2: Int64) -> Float64:
        # Ensure indices are within bounds
        var mod_idx = idx % (Int64(self.size) * self.channels)
        var mod_idx1 = idx1 % (Int64(self.size) * self.channels)
        var mod_idx2 = idx2 % (Int64(self.size) * self.channels)

        # Get the fractional part
        var frac = self.index - Float64(Int64(self.index))

        # Get the 3 sample values
        var y0 = self.data[mod_idx]
        var y1 = self.data[mod_idx1]
        var y2 = self.data[mod_idx2]

        # Quadratic interpolation coefficients
        var a = 0.5 * (y0 - 2.0 * y1 + y2)
        var b = 0.5 * (y2 - y0)
        var c = y1

        # Calculate interpolated value with frac in range [0,1]
        return a * frac * frac + b * frac + c 

    fn next(mut self) -> InlineArray[Float64, 2]:
        if self.index < self.size:
            self.index += self.step
            if self.index >= self.size:
                self.index = self.index - self.size  # Reset index if it exceeds size
        var out = InlineArray[Float64, 2](0.0, 0.0)  # Initialize output array for stereo

        var idx = Int64(self.index) * self.channels  # Calculate the index for interleaved data

        for i in range(min(self.channels, 2)):  # Handle up to 2 channels (for stereo output)
            out[i] = self.quadratic_interp(idx + i, idx + i + 2, idx + i + 4)  # Channel i

        return out

    fn load_file(mut self, filename: String) raises -> PythonObject:
        # using SciPy to read the WAV file
        var temp = self.scipy.io.wavfile.read(filename)  # Read the WAV file using SciPy
        
        
        self.buf_sample_rate = Float64(temp[0])  # Sample rate is the first element of the tuple
        var data = temp[1]  # Extract the actual sound data from the tuple
        # Convert to float64 if it's not already
        if data.dtype != self.np.float64:
            # If integer type, normalize to [-1.0, 1.0] range
            if self.np.issubdtype(data.dtype, self.np.integer):
                data = data.astype(self.np.float64) / self.np.iinfo(data.dtype).max
            else:
                data = data.astype(self.np.float64)
        self.size = Float64(len(data))  # Size is the length of the data array
        self.channels = Int64(Float64(data.shape[1]))  # Number of channels is the second dimension of the data array
        print("Channels:", self.channels)  # Print the shape of the data array for debugging
        self.data = data.__array_interface__["data"][0].unsafe_get_as_pointer[DType.float64]()

        return None
