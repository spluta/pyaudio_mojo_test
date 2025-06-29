# to set the path to pysndfile, I had to run "export SNDFILE_INSTALL_DIR='/opt/homebrew/Cellar/libsndfile/1.2.2_1'"

"""PyAudio Example: Play audio files using scipy (callback version)."""

import sys
import time
import numpy as np
from scipy.io import wavfile
import pyaudio

import max.mojo.importer
import os

sys.path.insert(0, "")

import mojo_module

blocksize = 128

# Get default system sample rate from PyAudio
p_temp = pyaudio.PyAudio()
device_info = p_temp.get_default_output_device_info()
sample_rate = int(device_info['defaultSampleRate'])
print(f"Default sample rate: {sample_rate}")
p_temp.terminate()
channels = 2

wire_buffer = np.zeros((blocksize, channels), dtype=np.float64)

# Initialize the Mojo module AudioEngine
mojo_audio_engine = mojo_module.AudioEngine().init2(sample_rate)  # Initialize the mojo_audio_engine with the sample rate

# Define callback for playback
def callback(in_data, frame_count, time_info, status):
    global data_index, wire_buffer, mojo_audio_engine

    # pass the wire_buffer to the Mojo audio engine. Mojo modifies the wire_buffer in place
    mojo_audio_engine.next(wire_buffer)

    wire_buffer = np.clip(wire_buffer, -1.0, 1.0)
    # Convert to bytes
    # not sure why it needs to convert to float32, but it does
    chunk = (wire_buffer).astype(np.float32).tobytes()

    # Return empty data when we've reached the end
    if len(chunk) == 0:
        return (chunk, pyaudio.paComplete)
    
    return (chunk, pyaudio.paContinue)

# Instantiate PyAudio
p = pyaudio.PyAudio()

format_code = pyaudio.paFloat32

data_index = 0
# Open stream using callback
stream = p.open(format=format_code,
                channels=channels,
                rate=sample_rate,
                output=True,
                frames_per_buffer=blocksize,
                stream_callback=callback)

# Wait for stream to finish
while stream.is_active():
    time.sleep(0.1)

# Close the stream
stream.close()

# Release PortAudio system resources
p.terminate()