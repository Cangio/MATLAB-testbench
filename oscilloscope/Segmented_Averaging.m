%% Segmented Memory Averaging using MATLAB
% This example connects to an Agilent scope over TCPIP and sends SCPI
% commands to initiate a segmented mode acquisition and then
% averages the segments together before displaying the final, averaged 
% waveform in MATLAB
% 
% Note that this demos does not require drivers or any other layers in the
% software stack. It does however require connectng to an Agilent
% oscilloscope. The user can alternatively use the IPAddress "localhost" if
% MATLAB is installed directly on the oscilloscope.
%
% 
% Authors: Vinod Cherian, The MathWorks
%          Jeff Schuch, Agilent Technologies

%% Interface configuration and instrument connection

% Change the IP address to match your instrument's IP address
% Use 'localhost' if running from MATLAB installed directly on scope
IPAddress = '192.168.158.14';
scopePort = 5025;

% Create a TCPIP object. Agilent instruments use port 5025 to send SCPI
% commands and receive data so use that information.
tcpipObj = instrfind('Type', 'tcpip', 'RemoteHost', IPAddress, 'RemotePort', scopePort, 'Tag', '');

% Create the TCPIP object if it does not exist
% otherwise use the object that was found.
if isempty(tcpipObj)
    tcpipObj = tcpip(IPAddress, scopePort);
else
    fclose(tcpipObj);
    tcpipObj = tcpipObj(1);
end

% Set the buffer size. Change this buffer size to slightly over the number
% of bytes you get back in each read
tcpipObj.InputBufferSize = 350000;
% Set the timeout value
tcpipObj.Timeout = 1;
% Set the Byte order
tcpipObj.ByteOrder = 'littleEndian';
% Open the connection
fopen(tcpipObj)

%% Instrument Setup
% Now setup the instrument using SCPI commands. refer to the instrument
% programming manual for your instrument for the correct SCPI commands for
% your instrument.

% Set acquisition mode to segmented
fprintf(tcpipObj, ':ACQUIRE:MODE SEGMENTED');

% Set total number of points per segment
fprintf(tcpipObj, ':ACQUIRE:POINTS 40000');

% Set sample rate
fprintf(tcpipObj, ':ACQUIRE:SRATE 40e9');

% Turn interpolation off for faster averaging
fprintf(tcpipObj, ':ACQUIRE:INTERPOLATE OFF');

% Set total number of segments over which to average
fprintf(tcpipObj, ':ACQUIRE:SEGMENTED:COUNT 100');

% If needed, set the timebase
fprintf(tcpipObj, ':TIMEBASE:SCALE 100e-9');

% Force a trigger to capture segments
fprintf(tcpipObj,'*TRG');

% Depending on how many segments are captured, a  pause may be necessary in
% order to account for the time required to capture all of the segments
pause(2);

% Specify data from Channel 1
fprintf(tcpipObj,':WAVEFORM:SOURCE CHAN3');

% Get the data back as a BYTE (i.e., INT8)
fprintf(tcpipObj,':WAVEFORM:FORMAT BYTE');

% Set the byte order on the instrument as well
fprintf(tcpipObj,':WAVEFORM:BYTEORDER LSBFirst');
fprintf(tcpipObj, 'WAVEFORM:STREAMING OFF');

% Get the preamble block
preambleBlock = query(tcpipObj,':WAVEFORM:PREAMBLE?');

% The preamble block contains all of the current WAVEFORM settings.  
% It is returned in the form <preamble_block><NL> where <preamble_block> is:
%    FORMAT        : int16 - 0 = BYTE, 1 = WORD, 2 = ASCII.
%    TYPE          : int16 - 0 = NORMAL, 1 = PEAK DETECT, 2 = AVERAGE
%    POINTS        : int32 - number of data points transferred.
%    COUNT         : int32 - 1 and is always 1.
%    XINCREMENT    : float64 - time difference between data points.
%    XORIGIN       : float64 - always the first data point in memory.
%    XREFERENCE    : int32 - specifies the data point associated with
%                            x-origin.
%    YINCREMENT    : float32 - voltage diff between data points.
%    YORIGIN       : float32 - value is the voltage at center screen.
%    YREFERENCE    : int32 - specifies the data point where y-origin
%                            occurs.
%preambleBlock

% Maximum value storable in a INT8
maxVal = 2^8; 

%  split the preambleBlock into individual pieces of info
preambleBlock = regexp(preambleBlock,',','split');


% store all this information into a waveform structure for later use
waveform.Format = str2double(preambleBlock{1});     % This should be 0, since we're specifying INT8 output
waveform.Type = str2double(preambleBlock{2});
waveform.Points = str2double(preambleBlock{3});
waveform.Count = str2double(preambleBlock{4});      % This is always 1
waveform.XIncrement = str2double(preambleBlock{5}); % in seconds
waveform.XOrigin = str2double(preambleBlock{6});    % in seconds
waveform.XReference = str2double(preambleBlock{7});
waveform.YIncrement = str2double(preambleBlock{8}); % V
waveform.YOrigin = str2double(preambleBlock{9});
waveform.YReference = str2double(preambleBlock{10   });
waveform.VoltsPerDiv = (maxVal * waveform.YIncrement / 8);      % V
waveform.Offset = ((maxVal/2 - waveform.YReference) * waveform.YIncrement + waveform.YOrigin);         % V
waveform.SecPerDiv = waveform.Points * waveform.XIncrement/10 ; % seconds
waveform.Delay = ((waveform.Points/2 - waveform.XReference) * waveform.XIncrement + waveform.XOrigin); % seconds

%% Instrument control and data retreival
% Now control the instrument using SCPI commands. refer to the instrument
% programming manual for your instrument for the correct SCPI commands for
% your instrument.

% An optimization to try and speed up the data transfer
fclose(tcpipObj);
tcpipObj.Terminator = '';
fopen(tcpipObj);

% Declare variables for use in processing the segments
N = 0;
Total_segments = 10;
Avg_N_segments = zeros(waveform.Points,1);

% This will loop through each of the captured segments and pull the data
% from each segment into MATLAB for processing
while (N<=Total_segments)
    
    % This will place the Nth segment on the screen so it can be pulled into
    % MATLAB for processing.

    fwrite(tcpipObj, sprintf(':ACQUIRE:SEGMENTED:INDEX %d\n',N));
    
    % Now send commmand to read data
    fwrite(tcpipObj,sprintf(':WAV:DATA?\n'));
    
    % Read back the BINBLOCK with the data in specified format and store it in
    % the waveform structure
    waveform.RawData = binblockread(tcpipObj);
        
    % Generate X & Y Data
    waveform.XData = (waveform.XIncrement.*(1:length(waveform.RawData))) - waveform.XIncrement;
    waveform.YData = (waveform.RawData - waveform.YReference) .* waveform.YIncrement + waveform.YOrigin;
    
    Measurement_Nth_Segment = waveform.YData;
    
    N = N + 1;
    
    % Average the current segment with the average of all the previously
    % captured segments
    if N>1
        Avg_N_segments = (((N-1) .* Avg_N_segments) + (Measurement_Nth_Segment)).*(1/N);
    else
        Avg_N_segments = Measurement_Nth_Segment;
    end
    
    %Uncomment next two lines to see average plotted as segments are processed
    plot(waveform.XData,Avg_N_segments); hold on;
    pause(0.01);
end

%% Data Display and cleanup

% Plot the averaged data from all segments
plot(waveform.XData,Avg_N_segments)
set(gca,'XTick',(min(waveform.XData):waveform.SecPerDiv:max(waveform.XData)))
xlabel('Time (s)');
ylabel('Volts (V)');
title('Averaged Oscilloscope Data');
grid on;


% Close the TCPIP connection.
fclose(tcpipObj);
% Set the terminator back to LF
tcpipObj.Terminator = 'LF';

% Delete objects and clear them.
delete(tcpipObj); clear tcpipObj;