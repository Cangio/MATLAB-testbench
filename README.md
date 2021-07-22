# MATLAB-testbench
Thesis project about caracterization of HEMT transistor.
## Environment
The code handles an
 - Agilent Infiniium oscilloscope
 - RIGOL Programmable DC power supply
 - Agilent Arbitrary Waveform Generator
## Basic classes
Some classes have been implemented to send commands to instruments without knowing command syntax.
 -> **scopeClass.m**: implements basic functions for oscilloscope like reset, set time and vertical axis, start measure, set trigger etc.
 -> **awgClass.m**: implements basic functions for AWG including setting the output waveform and enabling/disabling the output.
 -> **psuClass.m**: implements basic functions for PSU including setting the output voltage or power of different outputs or retriving the power consumption.
These classes are stricly related to the instrumentation used for this testbench. In the class are included some constraints related to the instrument like max sampling rate.