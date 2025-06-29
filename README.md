### Mojo audio test

This is a project that uses PyAudio in python to create an audio callback loop and then creates all dsp in Mojo.

Inside the audio loop, python calls an "AudioEngine" written in Mojo, where all of the dsp functions are also written in mojo. Since mojo is able to call Python libraries internally, scipy and numpy are used inside Mojo to read a wav file and convert it to floats.

This is relatively efficient. I was able to get over 1000 sin oscilators going in one instance, with no hickups or distortion.

What was encouraging is that writing dsp code in Mojo is incredibly straight-forward. I think this has a lot of potential.

## Setup:

Python/Mojo interop is still getting smoothed out, so check out the latest instructions here as things will likely change:

https://docs.modular.com/mojo/manual/python/

```
git clone https://github.com/spluta/pyaudio_mojo_test.git

cd pyaudio_mojo_test

python3 -m venv venv
source venv/bin/activate

pip install numpy scipy
pip install --pre modular
```

use your package manager to install portaudio:
```
brew install portaudio
```

for me 'pip install pyaudio' didn't work outright. i had to tell it where portaudio was:
```
export SNDFILE_INSTALL_DIR='/opt/homebrew/Cellar/libsndfile/1.2.2_1'
```
which may be different in your system
then this worked:
```
pip install pyaudio
```

to run the script:
```
python pyaudio_mojo_test.py
``` 

It should play a recording of Shiverer by Eric Wubbels, with a Moog style ladder filter sweeping over the top and 8 sine waves panning from left to right.