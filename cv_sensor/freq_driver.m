% Characterize the probe sensor
%% Static acquisition
clc;clear;
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% USER DEFINE SETTINGS
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

psu_visa_str = "TCPIP0::192.168.158.116::inst0::INSTR";
scope_visa_str = "TCPIP0::192.168.158.77::inst0::INSTR";
awg_visa_str = "TCPIP0::192.168.158.115::inst0::INSTR";

% Set MAX watching time in s
max_time = 100e-3;  % 100ms

% Define static current array
%curr_array = 0.0:0.1:1;

% Define freq sweep
freq_sweep = linspace(1e3, 10e6, 50);
awg_voltage = 2;

% Enable/Disable average measure and set # of averages
avr = true;
avr_cnt = 10;

% Set channels to acquire in array
chs = [1 2 3];
% Set correspondent channel names
chs_names = ["Vsens" "Csens" "AWG"];
chs_vdiv = [0.05 0.2 0.5];

% Set trigger source
% Format: [<trig_chan> <trig_voltage> <ris/fal>]
% 	1 fo rising edge ; -1 for falling edge ; 0 for either
trig = [3 0.0 1];

% PSU channel used for circuit power supply
psu_suppl_ch = [2 3];
% Voltage for logic power supply
cv_supply = 15;

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% --------------- DO NOT EDIT --------------------- %

addpath("oscilloscope");

% Max # of points the scope can get
max_points = 32768;
max_sr = 4e9;

% Define all possible volt scales
volt_scale = [0.02 0.05 0.1 0.2 0.5 1 2];
% Index for volt_scale[] for each channel
chs_volts = [6 6 6 6];

% Initialize instrument connections
scope = scopeClass;
scope.init(scope_visa_str);

psu = psuClass;
psu.init(psu_visa_str);

awg = awgClass;
awg.init(awg_visa_str);

% Reset scope and psu
%scope.reset(); psu.reset();
% Set trigger
scope.setTrigger(trig(1), trig(2));

% SET PSU
if length(psu_suppl_ch) == 2
	psu.setTrack("ON");
	psu.setVoltage(psu_suppl_ch(1), cv_supply);
else
	psu.setVoltage(psu_suppl_ch, cv_supply);
end

% Enable circuit power supply
if length(psu_suppl_ch) == 2
	psu.setOnOff(psu_suppl_ch(1), 1);
else
	psu.setOnOff(psu_suppl_ch, 1);
end

x = input("Enable the driver and press y: ", 's');

% END PSU

% Enable channels
scope.dispChannels(chs);

% Compute Sample Rate based on acquisition time and max_points
sr = max_points * freq_sweep(1) * 10;
scope.setSN(sr, max_points);

scope.setTimeFromFreq(freq_sweep(1));

scope.rawWrite(":SYSTEM:HEADER OFF");
scope.rawWrite(":WAV:TYPE RAW");
scope.rawWrite(":ACQUIRE:MODE RTIME");
scope.rawWrite(":ACQ:INTerpolate OFF");

% Enable/Disable average acquisition
scope.setAvrAcq(avr, avr_cnt);

scope.rawWrite(":WAVeform:FORMat ASC");

%psu.setCurrent(psu_meas_ch, curr_array(1));
%psu.setOnOff(psu_meas_ch, 1); % Turn on channel

scope_vpp = zeros([length(chs) length(freq_sweep)]);

for frq=1:length(freq_sweep)

	awg.outpSine(freq_sweep(frq), awg_voltage);
    scope.setTimeFromFreq(freq_sweep(frq));
    scope.setAutoSN(max_points);
	scope.runStop(1);

	pause(5);

	for ch=chs
		scope_vpp(ch, frq) = scope.rawWR(strcat("MEAS:VPP? CHAN", num2str(ch)));
        scope.waitForOPC();
	end
	    
	% Once found optimal scale set the scope
	%scope.setVertDiv(ch, volt_scale(v_s_index));

end

clear ch frq 

% Turn off AWG output
awg.setOnOff(0);

freq_sweep_text = strings(1, length(freq_sweep));
for i=1:length(freq_sweep)
    [val, unit] = findMag(freq_sweep(i));
    freq_sweep_text(i) = strcat(sprintf("%.1f", val), unit, "Hz");
end

figure(1)
for ch=chs
	plot(freq_sweep, scope_vpp(chs(ch), :))
    hold on
end
xticklabels(freq_sweep_text)
grid on
legend(chs_names)

% Compute ratio between output voltage and sensor voltage
diff = scope_vpp(1,:) ./ scope_vpp(3,:);

%diff_db = mag2db(diff);

figure(2)
clf(2)
plot(freq_sweep, diff)
hold on
xticklabels(freq_sweep_text)
grid on
legend('Meas/AWG diff')
title('Probe voltage vs. AWG voltage (with driver)')
xlabel('Freq')
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
plot(freq_sweep, c_diff.*100)
hold on
xticklabels(freq_sweep_text)
plot(freq_sweep, c_mean, '-r')
grid on
title('Difference in % of meas current vs ideal current')
xlabel('Freq')
ylabel('Normalized difference (%)')

%% Save figure and data
start_name = 'freq_sweep_driver_s2';
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

save([start_name '.mat'], 'freq_sweep', 'scope_vpp', 'chs', 'chs_names', 'c_diff')