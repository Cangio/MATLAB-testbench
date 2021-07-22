

function [timeVector,Excitation,KSprobeOut,SensorOut]=acquisitionScope(scopeObj,SrateTemp,nPointsTemp,Amp1,Amp2,Amp3,OffsetSens,mainfolder,folderfile)


% Setting suitable sampling Rate
fprintf(scopeObj,['ACQ:SRAT ' num2str(SrateTemp)]);
waitForOPC(scopeObj);

% Setting N of points
fprintf(scopeObj,['ACQ:POIN ' num2str(nPointsTemp)]);
waitForOPC(scopeObj);

% Select Channel Ranges
fprintf(scopeObj,['CHAN1:RANGE ' num2str(2*Amp1)]);
fprintf(scopeObj,['CHAN2:RANGE ' num2str(2*Amp2)]);
fprintf(scopeObj,['CHAN3:RANGE ' num2str(2*Amp3)]);
waitForOPC(scopeObj);


% BIN file acquisition
sysLocation=["C:\DataDownload\" mainfolder "\"];

% Select Channel Offset
fprintf(scopeObj,['CHAN1:OFFS 0']);
fprintf(scopeObj,['CHAN2:OFFS 0']);
fprintf(scopeObj,['CHAN3:OFFS ' num2str(OffsetSens)]);
waitForOPC(scopeObj);

tic;
% Actual save
pause(0.5);
fprintf(scopeObj,'DIG');
waitForOPC(scopeObj);
pause(0.5);
fprintf(scopeObj,[':DISK:SAVE:WAV ALL, "' sysLocation folderfile '", BIN, OFF']);
waitForOPC(scopeObj);


% Import the bins
scopeLocation=['\\192.168.158.14\DataDownload\' mainfolder '\'];
[timeVector, Excitation] = importAgilentBin([scopeLocation folderfile '.bin'],1);
[~, KSprobeOut] = importAgilentBin([scopeLocation folderfile '.bin'],2);
[~, SensorOut] = importAgilentBin([scopeLocation folderfile '.bin'],3);

toc;

end