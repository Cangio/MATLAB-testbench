% Characterize the driver

%% Static acquisition
%clc; clear;
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% USER DEFINE SETTINGS
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

psu_visa_str = "TCPIP0::192.168.158.116::inst0::INSTR";
scope_visa_str = "TCPIP0::192.168.158.77::inst0::INSTR";
awg_visa_str = "TCPIP0::192.168.158.115::inst0::INSTR";

% Define static current array
ampl_sweep = 0.2:0.2:4;

% PSU channel used for measurement
%psu_meas_ch = 1;
% PSU channel used for circuit power supply
psu_suppl_ch = [2 3];
% Voltage for logic power supply
cv_supply = 10;

% Enable/Disable average measure and set # of averages
avr = true;
avr_cnt = 10;

% Set channels to acquire in array
chs = [1 2];
% Set correspondent channel names
chs_names = ["Output" "Probe out" "AWG"];

% Set trigger source
% Format: [<trig_chan> <trig_voltage> <ris/fal>]
% 	1 fo rising edge ; -1 for falling edge ; 0 for either
trig = [1 0.0 1];

awg_freq = 1e5; % 100kHz freq

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
psu = psuClass;
psu.init(psu_visa_str);

scope = scopeClass;
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
scope.setTrigger(trig(1), trig(2));

% Compute Sample Rate based on acquisition time and max_points
scope.setAutoSN(max_points);

scope.setTimeFromFreq(awg_freq);

scope.rawWrite(":SYSTEM:HEADER OFF");
scope.rawWrite(":WAV:TYPE RAW");
scope.rawWrite(":ACQUIRE:MODE RTIME");
scope.rawWrite(":ACQ:INTerpolate OFF");

% Enable/Disable average acquisition
scope.setAvrAcq(avr, avr_cnt);

scope.rawWrite(":WAVeform:FORMat ASC");

%scope.setVertDiv(chs(1), 2);
%scope.setVertDiv(chs(2), 2/4); % Driver has gain 4


% Enable outputs
% Enable circuit power supply
if length(psu_suppl_ch) == 2
	psu.setOnOff(psu_suppl_ch(1), 1);
	psu.setOnOff(psu_suppl_ch(2), 1);
else
	psu.setOnOff(psu_suppl_ch, 1);
end

scope_vpp = zeros([length(chs) length(ampl_sweep)]);

for amp=1:length(ampl_sweep)

	awg.outpSine(awg_freq, ampl_sweep(amp));
	scope.runStop(1);

	scope.setVertDiv(1, ampl_sweep(amp)*4/6);
    %scope.setVertDiv(1, ampl_sweep(amp)/25*4/6);
    scope.waitForOPC();
    %scope.setVertDiv(2, ampl_sweep(amp)/25*4/6);
    scope.waitForOPC();
    scope.setVertDiv(2, ampl_sweep(amp)/6);
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

%
ampl_sweep_text = strings(1, length(ampl_sweep));
for i=1:length(ampl_sweep)
    ampl_sweep_text(i) = strcat(sprintf("%.1f", ampl_sweep(i)), "V");
end
%%
% Plot AWG VS Output voltage
figure(1)
clf(1)
plot(scope_vpp(2, :), scope_vpp(1, :))
hold on
%plot(scope_vpp(3, :), scope_vpp(2, :).*25)
%xticklabels(ampl_sweep_text)
grid on
legend('Input VS Output', 'Input VS Probe voltage')
title('Input VS Output voltage no load')
xlabel('AWG output (V)')
ylabel('Probe output (V)')

%% Plot AWG VS Output voltage
figure(3)
clf(3)
v_diff = (scope_vpp(1, :) - scope_vpp(2, :)*25) ./ scope_vpp(1, :);
plot(scope_vpp(1, :), v_diff.*100)
hold on
%plot(scope_vpp(3, :), scope_vpp(2, :).*25)
%xticklabels(ampl_sweep_text)
grid on
%legend('Input VS Output', 'Input VS Probe voltage')
title('Probe vs Output % error')
xlabel('Output voltage (V)')
ylabel('Relative error (%)')

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


%%

for i=1:length(x_a)
    inde = fix((scope_vpp(2, i)*100)-9);
    if inde == 0
        inde = 1;
    end
    y_a(i) = yy(inde);
end

figure
plot(x_a, y_a)
