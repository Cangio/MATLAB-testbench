## Voltage sweep with AWG - Driver - Sensor
### Circuit connection:

AWG  =====> DRIVER =====> SENSOR =====> SCOPE

### Setup
Power supply for both driver and sensor was +- 10V.\
AWG frequency was fixed at 100kHz.
### Acquisition
[Reference file](https://raw.githubusercontent.com/Cangio/MATLAB-testbench/cv_sensor/voltage_meas_noload.m).
For driver voltage measure the scope has been connected to sensor output, no load and scope in 1MOhm DC.\
For sensor voltage measure the scope has been connected to OUT_VOLT output of sensor.\
For AWG voltage measure scope and AWG have been connected directly.\
Measures have been taken in 3 separate measures and input was always channel 1 of scope.
### Goal
The goal of the measurement was to check if gain of 1/25 of voltage sensor is constant regardless of input voltage.
### Results
![Output - sensor voltage ratio](/images/ampl_sweep_driver_s2_noload.jpg)
[Download figure](https://raw.githubusercontent.com/Cangio/MATLAB-testbench/cv_sensor/ampl_sweep_driver_s2_noload.fig).\
[Download dataset](https://raw.githubusercontent.com/Cangio/MATLAB-testbench/cv_sensor/ampl_sweep_driver_s2_noload.mat).\

***