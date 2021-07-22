% Characterize the probe sensor
%% Static acquisition
clc; clear;
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% USER DEFINE SETTINGS
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

psu_visa_str = "TCPIP0::192.168.158.116::inst0::INSTR";

% Define static current array
curr_array = 0.0:0.1:1;

% PSU channel used for measurement
psu_meas_ch = 1;
% PSU channel used for circuit power supply
psu_suppl_ch = [2 3];
% Voltage for logic power supply
cv_supply = 10;
cv_meas_supply = 5;

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% --------------- DO NOT EDIT --------------------- %

% Initialize instrument connections
psu = psuClass;
conn = psu.init(psu_visa_str);

% Reset psu
psu.reset();

psu.setVoltage(psu_meas_ch, 0);
if length(psu_suppl_ch) == 2
	psu.setTrack("ON");
	psu.setVoltage(psu_suppl_ch(1), cv_supply);
	%psu.setVoltage(psu_suppl_ch(2), -cv_supply); % If track enabled this is automatic
else
	psu.setVoltage(psu_suppl_ch, cv_supply);
end

% Enable circuit power supply
if length(psu_suppl_ch) == 2
	psu.setOnOff(psu_suppl_ch(1), 1);
	psu.setOnOff(psu_suppl_ch(2), 1);
else
	psu.setOnOff(psu_suppl_ch, 1);
end

pause(2);

psu.setCurrent(psu_meas_ch, curr_array(1));
psu.setVoltage(cv_meas_supply);
psu.setOnOff(psu_meas_ch, 1);

psu_volt = zeros([1 length(curr_array)]);
psu_curr = zeros([1 length(curr_array)]);
psu_powe = zeros([1 length(curr_array)]);

for cr=1:length(curr_array)
	psu.setCurrent(curr_array(cr));
   	pause(1);

   	psu.waitForOPC();
   	[psu_volt(cr), psu_curr(cr), psu_powe(cr)] = psu.measAll();

   	pause(1);
end

psu.setOnOff(1, "OFF");
psu.setOnOff(2, "OFF");
psu.setOnOff(3, "OFF");

%%
plot();
grid on
