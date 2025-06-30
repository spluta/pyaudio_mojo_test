### Mojo audio test

This is a project that uses PyAudio in python to create an audio callback loop and then creates an AudioEngine and runs all dsp in Mojo.

Since mojo is able to call Python libraries internally, scipy and numpy are used inside Mojo to read a wav file and convert it to floats. Otherwise, there is no python code inside the Mojo engine, and all files are loaded prior to dsp beginning.

This is relatively efficient. I was able to get over 1000 sin oscilators going in one instance, with no hickups or distortion. For comparison, SuperCollider can get 5000. Part of this might be my implementation, where I am processing each Synth one sample at a time, rather than in blocks like SC does.

What was encouraging is that writing dsp code in Mojo is incredibly straight-forward and the feedback loop of being able to quickly compile the entire project in a few seconds to test is lightyears better than making externals is SC/max/pd. I think this has a lot of potential.

## Setup:

Python/Mojo interop is still getting smoothed out, so check out the latest instructions here as things will likely change:

https://docs.modular.com/mojo/manual/python/

Here is what works now:

```
git clone https://github.com/spluta/pyaudio_mojo_test.git

cd pyaudio_mojo_test

python3 -m venv venv
source venv/bin/activate

pip install numpy scipy
pip install --pre modular
```

use your package manager to install portaudio. on mac this is:
```
brew install portaudio
```

for me 'pip install pyaudio' didn't work outright. i had to tell it where portaudio was, so I had to run the following line before the pip install pyaudio
```
export SNDFILE_INSTALL_DIR='/opt/homebrew/Cellar/libsndfile/1.2.2_1'
```
your directory may be different, but you get the idea.
then this installed pyaudio:
```
pip install pyaudio
```

to run the script:
```
python pyaudio_mojo_test.py
``` 
if it complains about missing dependencies, you may look and see which python got installed in the venv and call that directly:
```
venv/bin/python pyaudio_mojo_test.py
```

It should play a recording of Shiverer by Eric Wubbels, with a Moog style ladder filter sweeping over the top and 8 sine waves panning from left to right.