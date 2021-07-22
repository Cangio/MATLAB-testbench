# Oscilloscope classes
## Tektronix 5-MSO scope
The class provide all the functionalities to set the scope and acquire data
### Usage example
```
scope_visa_str = "TCPIP0::192.168.158.34::inst0::INSTR";

scope = scopeTekClass;
scope.init(scope_visa_str);

scope.reset();

% Display channel 5 and 6
scope.dispChannels([5 6]);

% Set trigger on channel 6, level 0V, rising edge
scope.setTrigger(6, 0, 1);

% Set average-mode acquisition with average num = 14
scope.setAcq("AVE", 14);

% Acquire waveform on channel 6
[wavef, time] = scope.acqWaveform(6);

% Plot waveform
figure
plot(time, wavef)
grid on; hold on;
title("Acquisition")
xlabel("Time")
ylabel("Voltage")
```