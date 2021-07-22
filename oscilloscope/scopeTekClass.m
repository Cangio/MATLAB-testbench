classdef scopeTekClass<handle
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%% Class for 5-MSO-6 scope
%
%%% Methods:
%		- init(resource)				// Open device connection
%		- reset()						// Reset to default
%		- rawWrite(comm)				// Write given command on SCPI
%		- data = rawWR(comm)			// Write command and get output
%		- waitForOPC()					// Wait for 100ms (compatibility)
%		- idn()							// Return IDN of device
%		- setTrigger(chan, varargin)	// Set trigger channel, level, slope
%		- dispChannel(chan)				// Display one given channel
%		- dispChannels(chans)			// Display multiple channels
%		- setTimeDiv(time)				// Set time division
%		- setTimeFromFreq(freq)			// Set time division from freq
%		- setVertDiv(chan, div)			// Set vertical division
%		- runStop(run)					// Run/stop operation
%		- setSN(sampling, points)		// Set sampling rate and # points
%		- setAcq(a_mode, varargin)		// Set acquisition mode
%		- chTerm(chan, term)			// Change channel termination
%		- acqWaveform(chan)				// Acquire wavefom from given channel
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

	properties
		visaObj
		timeDiv
		sysLoc
		folder
		nchans 	% Total number of channels
		maxSR 	% MAX Sampling Rate
		srs 	% Possible values for Sampling Rate
	end
	methods
		function res = init(obj, resource, folder)
			% Init resource
			try
				obj.visaObj = visadev(resource);
			catch
				error("Problem in connecting to visa instrument");
			end

			idn = writeread(obj.visaObj, "*IDN?");
			disp(strcat("Connected with: ", idn));

			obj.timeDiv = 1e-4;
			obj.nchans = 6;
			obj.maxSR = 4e9;
			obj.srs = [10e6 25e6 50e6 100e6 250e6 0.5e9 1e9 2e9 4e9];

			if nargin < 3
				folder = "Test";
			end
			obj.sysLoc = strcat("C:\DataDownload\", folder, "\");
			obj.folder = folder;

			res = true;
		end

		function reset(obj)
			% Reset oscilloscope to initial value
			% - Perform a *RST command
			% - Set time ref to center to a defined scale
			% - Set all channels OFF in 1Meg impedance

			obj.rawWrite('*RST');
			obj.rawWrite(":TIM:RANGe 1E-3");
			obj.rawWrite(":TIM:DELay 0");
			obj.rawWrite(":TIM:REF CENTer");
			obj.rawWrite(":WAV:FORM WORD;BYT LSBF;STR OFF");

			setSN(obj, 10e9, 1e4);
			waitForOPC(obj);

			% Set 1Meg impedance
			for i=1:obj.nchans
				obj.rawWrite(strcat("CH", num2str(i), ":TERMINATION 1e6"));
			end
			obj.waitForOPC();

			%obj.offAllChan();
			obj.waitForOPC();
		end

		function rawWrite(obj, comm)
			% Interface for visadev writeline function
			% INPUT: string -> command to be sent

			writeline(obj.visaObj, comm);
		end

		function data = rawWR(obj, comm)
			% Interface for visadev writeline function
			% INPUT: string -> command to be sent
			% OUTPUT: string -> response from instrument

			data = writeread(obj.visaObj, comm);
		end

		function waitForOPC(obj)
			% Block execution until scope is ready
			K=0;
			%while(K~=1)   
			%    K = str2double(writeread(obj.visaObj, "*OPC?"));
			%end
			pause(0.1);
		end

		function r = idn(obj)
			% Get the IDN of instrument
			r = writeread(obj.visaObj, "*IDN?");
		end

		function isChan = checkChan(obj, chan)
			% Check if provided channel is available for instrument
			if isa(chan, 'string') || isa(chan, 'char')
				chan = str2double(chan);
			end
			% Check if valid channel
			if ~ismember(chan, [0:obj.nchans])
				isChan = false;
			else
				isChan = true;
			end
		end

		function setTrigger(obj, chan, varargin)
			% Set the scope EDGE mode trigger
			% INPUT:
			%   chan: integer 0-4
			%		CH0: Trigger source AUX
			%		CHx
			%	level: float
			%	r_f: [-1|0|1]
			%		set falling|either|rising edge of trigger

			if obj.checkChan(chan) == false and false
				error("Not a valid channel");
			end
			schan = int2str(chan);

			% Optional arguments are trig_voltage and ris/fal edge
			optargs = {0.0 1};
			if nargin > 2
				optargs(1:(nargin-2)) = varargin;
			end
			[level r_f] = optargs{:};
			slevel = num2str(level);

			
			%writeline(obj.visaObj, ":TRIGger:SWEep NORMal");
			
			% Set source channel
			if chan == 0
				writeline(obj.visaObj, "TRIG:A:EDGE:SOU AUX");
				writeline(obj.visaObj, strcat("TRIG:A:LEV:AUX ", slevel));
			else
				writeline(obj.visaObj, strcat("TRIG:A:EDGE:SOU CH", schan));
				writeline(obj.visaObj, strcat("TRIG:A:LEV:CH", schan, " ", slevel));
			end

			% Set trigger edge
			switch r_f
				case 1
					sr_f = "RIS";	% Trigger for POSitive edge
				case 0
					sr_f = "EIT"; 	% Trigger for EITHer edge
				case -1
					sr_f = "FALL";	% Trigger for NEGative edge
				otherwise
					sr_f = "RIS";
			end
			writeline(obj.visaObj, strcat("TRIG:A:EDGE:SLO ", sr_f));
		end

		function dispChannelSolo(obj, chan)
			% Set scope to display desired channel (other would be off)
			% INPUT:
			%   chan: integer 1-4

			if checkChan(chan) == 1
				error("Not a valid channel");
			end

			% Enable display of only the selected channel
			for i=1:4
				if chan == i
					obj.rawWrite(strcat("DIS:GLO:CH", int2str(i),":STATE ON"));
				else
					obj.rawWrite(strcat("DIS:GLO:CH", int2str(i),":STATE OFF"));
				end
			end
		end

		function dispChannel(obj, chan, onoff)
			% Enable/Disable given channel
			% INPUT:
			%   chan: integer 1-4

			if obj.checkChan(chan) == 1
				error("Not a valid channel");
			end
			schan = int2str(chan);
			if onoff == 1
				obj.rawWrite(strcat("DIS:GLO:CH", schan,":STATE ON"));
			else
				obj.rawWrite(strcat("DIS:GLO:CH", schan,":STATE OFF"));
			end
		end

		function dispChannels(obj, chan)
			% Set scope to display desired channels
			% Multiple channels allowed
			% args:
			%   chan: array of integers 1-4

			% Enable display of only the selected channel
			for i=1:4
				if ismember(i, chan)
					obj.rawWrite(strcat("DIS:GLO:CH", int2str(i),":STATE ON"));
				else
					obj.rawWrite(strcat("DIS:GLO:CH", int2str(i),":STATE OFF"));
				end
			end
		end

		function obj = setTimeDiv(obj, time)
			% Set time division in horizontal scale
			
			%time = time * 10;
			obj.timeDiv = time;
			writeline(obj.visaObj, strcat("HOR:MODE:SCA ", num2str(obj.timeDiv)));
		end

		function obj = setTimePer(obj, time)
			% Set time period
			% Time division is period/10
			
			obj.timeDiv = time / 10;
			writeline(obj.visaObj, strcat("HOR:MODE:SCA ", num2str(obj.timeDiv)));
		end

		% Set time division from frequency
		function obj = setTimeFromFreq(obj, freq)
			time = (1 / freq) * 6;
			obj.timeDiv = time;
			writeline(obj.visaObj, strcat("HOR:MODE:SCA ", num2str(obj.timeDiv)));
		end

		function setVertDiv(obj, chan, div)
			% Set vertical div for a channel
			% INPUT:
			%   chan: integer or array 1-4
			%	div: float (in V)

			if isa(chan, 'string') || isa(chan, 'char')
				chan = str2double(char);
			end
			if isa(div, 'string') || isa(div, 'char')
				div = str2double(div);
			end

			for i=1:length(chan)
				writeline(obj.visaObj, strcat("CH", num2str(chan(i)), ":SCA ", num2str(div)));
			end
		end

		function chTerm(obj, chan, term)
			% Set channel termination
			% args:
			%   chan: integer {0:6}
			%   term: integer {50|1e6}
			if isa(chan, 'integer') || isa(chan, 'double')
				sterm = num2str(term);
			else
				sterm = term;
			end

			obj.rawWrite(strcat("CH", num2str(i), ":TERMINATION ", sterm));
		end

		function runStop(obj, run)
			% Run/stop scope acquisition
			% args:
			%   run: integer {0|1}
			
			if run == 1
				writeline(obj.visaObj, "ACQ:STATE RUN");
			else
				writeline(obj.visaObj, "ACQ:STATE STOP");
			end
		end

		function setSN(obj, samp, pts)
			% Set sampling rate and # of points to acquire
			% args:
			%   samp: integer (sampling rate in GSa/s)
			%	pts: integer (# of points)
			
			if samp > obj.maxSR
				samp = obj.maxSR;
			end
			writeline(obj.visaObj, strcat("HOR:MODE:SAMPLER ", num2str(samp)));
			writeline(obj.visaObj, strcat("HOR:MODE:RECO ", num2str(pts)));
		end

		function setAutoSN(obj, pts)
			% Auto set sampling rate given # of points and time division
			%
			% args:
			%	pts: integer (# of points)
			
			if ~isnumeric(obj.timeDiv)
				error("Need to call setTimeDiv before");
			end

			rate = pts / obj.timeDiv;
			setSN(obj, rate, pts);
		end

		function setAvrAcq(obj, cnt)
			% Set acquisition mode as AVErage
			% Specify the # of acquisition to be averaged
			%
			% args:
			%   cnt: integer

			obj.rawWrite("ACQ:MOD AVE"); % Set acquire mode to AVErage
			obj.rawWrite(strcat("ACQ:NUMAVg ", num2str(cnt)));
		end

		function setAcq(obj, a_mode, varargin)
			% Set acquisition mode to [SAMple | HIRes | AVErage | ENVelope]
			% For AVErage specify number of averages or apply default: 10

			% Optional arguments are average count for average mode
			optargs = {10};
			if nargin > 2
				optargs(1:(nargin-2)) = varargin;
			end
			cnt = optargs{:};

			if ~ismember(a_mode, ["SAM" "HIR" "AVE" "ENV"])
				disp("Not a valid mode")
				return
			else
				% If AVErage mode call proper function
				if a_mode == "AVE"
					obj.setAvrAcq(cnt);
				else
					obj.rawWrite(strcat("ACQ:MOD ", a_mode));
				end
			end
		end
			
		function meas(obj, num, chan, m_type)
			schan = num2str(chan);
			snum = num2str(num);

			obj.rawWrite(strcat("MEASU:MEAS", snum,":SOU CH", schan));
		end

		function [wavef, time] = acqWaveform(obj, chan)
			% Get waveform from scope
			% args:
			%   chan: integer {1:6}
			% return:
			%	wavef: voltage vector
			%	time: time vector

			if isa(chan, 'string') || isa(chan, 'char')
				chan = str2double(chan);
			end
			schan = num2str(chan);

			obj.rawWrite(strcat(":DATA:SOURCE CH", schan));

			obj.rawWrite("DATa:WIDth 2");

			obj.rawWrite(":DATA:ENCDG SRIBINARY");

			scopeEncodingMethod = obj.rawWR(":DATA:ENCDG?");
			scopeWaveformPreamble = obj.rawWR(":WFMpre?");
			scopeNumPoints = obj.rawWR(":WFMpre:NR_Pt?");

			n_points = str2double(scopeNumPoints);
			x_incr = str2double(obj.rawWR(':WFMpre:XINcr?'));
			y_mul = str2double(obj.rawWR(':WFMpre:ymult?'));
			x_zero = str2double(obj.rawWR(':WFMpre:xzero?'));
			y_zero = str2double(obj.rawWR(':WFMpre:yzero?'));


			obj.rawWrite(":CURVE?");
			rawWaveform = readbinblock(obj.visaObj, 'int16');
			%fscanf(visaScope);

			time = (x_zero:x_incr:x_zero+x_incr*(n_points-1))';
			wavef = y_zero + rawWaveform.*y_mul;
		end
	end % End methods
end % End class