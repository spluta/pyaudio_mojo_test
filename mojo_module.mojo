from python import PythonObject
from python import Python
from python.bindings import PythonModuleBuilder

import math
from random import random_float64
from os import abort
from memory import UnsafePointer

import functions as funcs

from BufSynth import BufSynth
from OscSynth import OscSynth

# this is needed to make the module importable in Python - so simple!
@export
fn PyInit_mojo_module() -> PythonObject:
    try:
        var m = PythonModuleBuilder("mojo_module")
        # m.def_function[factorial]("factorial", docstring="Compute n!")

        _ = (
            m.add_type[AudioEngine]("AudioEngine")
            .def_method[AudioEngine.next]("next")
            .def_method[AudioEngine.init2]("init2")
        )

        return m.finalize()
    except e:
        return abort[PythonObject](String("error creating Python Mojo module:", e))


struct AudioEngine(Defaultable, Representable, Movable):
    var buf_synth: BufSynth  # Instance of BufSynth
    var osc_synth: OscSynth  # Instance of OscSynth
    

    var sample_rate: Float64
    
    var loc_wire_buffer: UnsafePointer[SIMD[DType.float64, 1]]  # Placeholder for wire buffer

    fn __init__(out self):
        # in the future I imagine we can send arguments to the constructor
        self.sample_rate = 44100.0

        # we will make two synths - one for the buffer and one for oscillators
        self.buf_synth = BufSynth()  # Initialize BufSynth
        self.osc_synth = OscSynth()  # Initialize OscSynth

        # it is way more efficient to use an UnsafePointer to write to the wire buffer directly
        self.loc_wire_buffer = UnsafePointer[SIMD[DType.float64, 1]]()  # Placeholder for wire buffer
        print("AudioEngine initialized with sample rate:", self.sample_rate)
        

    
    @staticmethod
    fn init2(self_: PythonObject, sample_rate: PythonObject) raises -> PythonObject:
        var self0 = self_.downcast_value_ptr[Self]()
        self0[].sample_rate = Float64(sample_rate)

        print("AudioEngine initialized with sample rate:", self0[].sample_rate)

        # make sure all the synths are initialized with the sample rate
        self0[].buf_synth.init2(self0[].sample_rate, "Shiverer.wav")  # Load a sound file into the buffer
        self0[].osc_synth.init2(self0[].sample_rate)

        return self_  # Return a PythonObject wrapping the float value


    fn __repr__(self) -> String:
        return String("AudioEngine")

    @staticmethod
    fn next(self_: PythonObject, wire_buffer: PythonObject) raises -> PythonObject:
        var self0 = self_.downcast_value_ptr[Self]()

        var length = len(wire_buffer)

        # using an UnsafePointer to access the wire buffer directly is way more efficient than using a PythonObject
        # it returns an interleaved array of float64 values rather than the numpy multidimensional array
        self0[].loc_wire_buffer = wire_buffer.__array_interface__["data"][0].unsafe_get_as_pointer[DType.float64]()

        # # iterate over the length of the wire buffer
        # # and fill it with the next samples from the BufSynth and OscSynth
        for i in range(length):
            var sample = self0[].buf_synth.next()

            var osc_sum = self0[].osc_synth.next()  # Get the next sample from the OscSynth

            for j in range(2):
                if j < 2:  # Assuming stereo output
                    self0[].loc_wire_buffer[i * 2 + j] = sample[j] + osc_sum[j]  # Fill the wire buffer with the sample data

        return PythonObject(None)  # Return a PythonObject wrapping the float value
    

