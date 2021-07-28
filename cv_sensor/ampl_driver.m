%% Characterize the probe sensor with input amplitude swing
% Sensor 
% Change 
clc;clear;
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% USER DEFINE SETTINGS
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

psu_visa_str = "TCPIP0::192.168.158.116::inst0::INSTR";
scope_visa_str = "TCPIP0::192.168.158.34::inst0::INSTR";
awg_visa_str = "TCPIP0::192.168.158.115::inst0::INSTR";

% Set MAX watching time in s
max_time = 100e-3;  % 100ms

% Define static current array
%curr_array = 0.0:0.1:1;

% Define freq sweep
ampl_sweep = linspace(0.5, 7, 14);
awg_freq = 100e3; % Set output freq at 100kHz

% Enable/Disable average measure and set # of averages
avr = true;
avr_cnt = 10;

% Set channels to acquire in array
chs = [3 4 5 6];
% Set correspondent channel names
chs_names = ["Csens" "DriverOut" "Vsens" "AWG"];
chs_vdiv = [0.4 4 4/25 1];

% Set trigger source
% Format: [<trig_chan> <trig_voltage> <ris/fal>]
% 	1 fo rising edge ; -1 for falling edge ; 0 for either
trig = [6 1 1];

% PSU channel used for circuit power supply
psu_suppl_ch = [1 2 3];
psu_suppl_vl = [7 30 2];
psu_track = false;
% Voltage for logic power supply
cv_supply = [];

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% --------------- DO NOT EDIT --------------------- %

addpath("oscilloscope");

% Max # of points the scope can get
max_points = 100e3;
max_sr = 6.25e9;

% Define all possible volt scales
volt_scale = [0.02 0.05 0.1 0.2 0.5 1 2 5 10];
% Index for volt_scale[] for each channel
chs_volts = [6 6 6 6 6 6 6];

% Initialize instrument connections
%if exist('scope', 'var') ~= 1
scope = scopeClass;
scope.init(scope_visa_str);
%end

%if exist('awg', 'var') ~= 1
awg = awgClass;
awg.init(awg_visa_str);
%end

%if exist('psu', 'var') ~= 1
psu = psuClass;
psu.init(psu_visa_str);
%end


% Reset scope and psu
%scope.reset(); psu.reset();
% Set trigger
scope.setTrigger(trig(1), trig(2));

% SET PSU
if psu_track == true
	psu.setTrack("ON");
	psu.setVoltage(2, psu_suppl_vl(find(psu_suppl_ch==2)));
else
	for ch=1:length(psu_suppl_ch)
		psu.setVoltage(psu_suppl_ch(ch), psu_suppl_vl(ch));
	end
end

% Enable circuit power supply
for ch=psu_suppl_ch
	psu.setOnOff(ch, 1);
end
% END PSU

x = input("Enable the driver and press y: ", 's');
clear x

% Enable channels
scope.dispChannels(chs);

% Compute Sample Rate based on acquisition time and max_points
scope.setAutoSN(max_points);

scope.setTimeFromFreq(awg_freq);

%scope.rawWrite(":SYSTEM:HEADER OFF");
%scope.rawWrite(":WAV:TYPE RAW");
%scope.rawWrite(":ACQUIRE:MODE RTIME");
%scope.rawWrite(":ACQ:INTerpolate OFF");

% Enable/Disable average acquisition
scope.setAvrAcq(avr, avr_cnt);

%scope.rawWrite(":WAVeform:FORMat ASC");

%psu.setCurrent(psu_meas_ch, curr_array(1));
%psu.setOnOff(psu_meas_ch, 1); % Turn on channel

scope_vpp = zeros([length(chs) length(ampl_sweep)]);

for amp=1:length(ampl_sweep)

	awg.outpSine(awg_freq, ampl_sweep(amp));
	scope.runStop(1);

	scope.setVertDiv(1, ampl_sweep(amp)/25*4/6);
    scope.waitForOPC();
    scope.setVertDiv(3, ampl_sweep(amp)/8);
    scope.waitForOPC();
	

	pause(3);

	for ch=chs
		try
			scope_vpp(ch, amp) = scope.rawWR(strcat("MEAS:VPP? CHAN", num2str(ch)));
		catch
			scope_vpp(ch, amp) = scope.rawWR(strcat("MEAS:VPP? CHAN", num2str(ch)));
		end
        scope.waitForOPC();
	end
end

clear ch amp
%%
ampl_sweep_text = strings(1, length(ampl_sweep));
for i=1:length(ampl_sweep)
    ampl_sweep_text(i) = strcat(sprintf("%.1f", ampl_sweep(i)), "V");
end

% Turn off power supply output
awg.setOnOff(0);

figure(1)
clf(1)
for ch=chs
	plot(ampl_sweep, scope_vpp(chs(ch), :))
    hold on
end
xticklabels(ampl_sweep_text)
grid on
legend(chs_names)
xlabel('Voltage set (V)')
ylabel('Voltage readout (V)')

% Compute ratio between output voltage and sensor voltage
diff = scope_vpp(1,:) ./ scope_vpp(3,:);

%diff_db = mag2db(diff);

figure(2)
clf(2)
plot(ampl_sweep, diff)
hold on
xticklabels(ampl_sweep_text)
grid on
legend('Sens/AWG ratio')
title('Probe voltage vs. AWG voltage (with driver)')
xlabel('Voltage')
ylabel('Sensor/AWG (V/V)')

% Current % error
% Probe scale is 1/25 that compensate the 25Ohm resistor
% I = (V*25) / 25Ohm = V
% Vmax is considered as Vpp/2
% Ideal current is computed considering the input voltage and 25Ohm
%   resistor value
c_diff = ((scope_vpp(1, :) ./ 2) - (scope_vpp(2, :)./2)) ./ (scope_vpp(1, :) ./ 2);
c_mean = ones([1 length(c_diff)]).*100 .* sum(c_diff,2)./length(c_diff);
figure
plot(ampl_sweep, c_diff.*100)
hold on
xticklabels(ampl_sweep_text)
plot(ampl_sweep, c_mean, '-r')
grid on
title('Difference in % of meas current vs ideal current')
xlabel('Voltage')
ylabel('Normalized difference (%)')

%% Save figure and data
start_name = 'ampl_sweep_driver_s2';
start_name = ['cv_sensor\' start_name];

figure(1)
fig_name = [start_name '_volts.fig'];
savefig(fig_name)

figure(2)
fig_name = [start_name '_ratio.fig'];
savefig(fig_name)

figure(3)
fig_name = [start_name '_err.fig'];
savefig(fig_name)

save([start_name '.mat'], 'ampl_sweep', 'scope_vpp', 'chs', 'chs_names', 'c_diff')