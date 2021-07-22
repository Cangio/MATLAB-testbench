% Characterize the driver

%% Static acquisition
clc; clear;
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% USER DEFINE SETTINGS
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

psu_visa_str = "TCPIP0::192.168.158.116::inst0::INSTR";
scope_visa_str = "TCPIP0::192.168.158.34::inst0::INSTR";
awg_visa_str = "TCPIP0::192.168.158.115::inst0::INSTR";

% Define static current array
ampl_sweep = 0.1:0.1:4;

% PSU channel used for measurement
%psu_meas_ch = 1;
% PSU channel used for circuit power supply
psu_suppl_ch = [2 3];
% Voltage for logic power supply
cv_supply = 15;

% Enable/Disable average measure and set # of averages
avr = true;
avr_cnt = 10;

% Set channels to acquire in array
chs = [4 5 6];
% Set correspondent channel names
chs_names = ["DriverOut" "VSensor" "AWG"];

chs_mult = [4 4/25 1];
chs_imp = [1e6 50 1e6];

% Set trigger source
% Format: [<trig_chan> <trig_voltage> <ris/fal>]
% 	1 fo rising edge ; -1 for falling edge ; 0 for either
trig = [6 0.0 1];

awg_freq = 1e5; % 100kHz freq

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% --------------- DO NOT EDIT --------------------- %

addpath("oscilloscope");

% Max # of points the scope can get
max_points = 100e3;
max_sr = 6.25e9;

% Define all possible volt scales
volt_scale = [0.02 0.05 0.1 0.2 0.5 1 2 5 10];
% Index for volt_scale[] for each channel
chs_volts = [6 6 6 6 6 6];

% Initialize instrument connections
psu = psuClass;
psu.init(psu_visa_str);

scope = scopeTekClass;
scope.init(scope_visa_str);

awg = awgClass;
awg.init(awg_visa_str);

% Reset all
%psu.reset(); awg.reset(); psu.reset();

% SET PSU
if length(psu_suppl_ch) == 2
	psu.setTrack("ON");
	psu.setVoltage(psu_suppl_ch(1), cv_supply);
else
	psu.setVoltage(psu_suppl_ch, cv_supply);
end

% SET SCOPE
% Max # of points the scope can get
% Enable channels
scope.dispChannels(chs);

% Compute Sample Rate based on acquisition time and max_points
scope.setSN(3.125e9, max_points);

scope.setTimeFromFreq(awg_freq);

scope.rawWrite(":HEADER OFF");

% Enable/Disable average acquisition
%scope.setAvrAcq(avr_cnt);
scope.setAcq("HIR"); % HI Resolution

for ch=1:length(chs)
	sch = num2str(chs(ch));
	scope.rawWrite(strcat("MEASU:MEAS", num2str(ch),":SOU CH", sch));
	scope.setVertDiv(chs(ch), ampl_sweep(1)*chs_mult(ch)/6);
	scope.chTerm(chs(ch), chs_imp(ch));
end

% Enable outputs
% Enable circuit power supply
if length(psu_suppl_ch) == 2
	psu.setOnOff(psu_suppl_ch(1), 1);
else
	psu.setOnOff(psu_suppl_ch, 1);
end

x = input("Enable the driver and press y: ", 's');
clear x

scope_vpp = zeros([length(chs) length(ampl_sweep)]);
pb = CmdLineProgressBar("Acquisition ", 10);

for amp=1:length(ampl_sweep)

	pb.progress(i);

	awg.outpSine(awg_freq, ampl_sweep(amp));
	scope.runStop(1);

	for ch=1:length(chs)
		scope.setVertDiv(chs(ch), ampl_sweep(amp)*chs_mult(ch)/6);
    	scope.waitForOPC();
	end	

	pause(1);

	for ch=1:length(chs)
		try
			scope_vpp(ch, amp) = scope.rawWR(strcat("MEASU:MEAS", num2str(ch), ":RESUlts:CURR:MEAN?"));
		catch
			scope_vpp(ch, amp) = scope.rawWR(strcat("MEASU:MEAS", num2str(ch), ":RESUlts:CURR:MEAN?"));
		end
        scope.waitForOPC();
	end
end

awg.outpSine(awg_freq, 1);
awg.setOnOff("OFF");

%
ampl_sweep_text = strings(1, length(ampl_sweep));
for i=1:length(ampl_sweep)
    ampl_sweep_text(i) = strcat(sprintf("%.1f", ampl_sweep(i)), "V");
end

for ch=1:length(chs)
	figure(ch)
	clf(ch)
	plot(ampl_sweep, scope_vpp(ch, :))
	grid on; hold on;
	xticklabels(ampl_sweep_text);
	xlabel('AWG output (V)')
	ylabel(chs_names(ch))
	title(strcat("Input voltage vs. ", chs_names(ch)))
end

%% Make plots
% Plot AWG VS Output voltage
awg_chan = 6; out_chan = 4; sens_chan = 5;
awg_idx = find(chs==awg_chan); out_idx = find(chs==out_chan); sens_idx = find(chs==sens_chan);

figure
plot(scope_vpp(awg_idx, :), scope_vpp(out_idx, :))
hold on
plot(scope_vpp(awg_idx, :), scope_vpp(sens_idx, :).*25)
%xticklabels(ampl_sweep_text)
grid on
legend("Driver Output", "Probe * 25")
title('Input VS Output voltage no load')
xlabel('AWG output (V)')
ylabel('Driver output (V)')
%%
% Plot gain for every point
volt_ratio = scope_vpp(1, :) ./ scope_vpp(3, :);
average_ratio = ones([1 length(volt_ratio)]) .* (sum(volt_ratio)/length(volt_ratio));
figure(2)
clf(2)
plot(scope_vpp(3, :), volt_ratio)
hold on
plot(scope_vpp(3, :), average_ratio, '-r')
%xticklabels(ampl_sweep_text)
grid on
legend('Gain', 'Average')
title('Driver gain no load')
xlabel('AWG voltage (V)')
ylabel('Gain (V/V)')