classdef CmdLineProgressBar < handle
    % class for command-line progress-bar notification.
    % Use example:
    %   pb = CmdLineProgressBar('Doing stuff...');
    %   for k = 1 : 10
    %       pb.print(k,10)
    %       % do stuff
    %   end
    %

    % Author: Itamar Katz, itakatz@gmail.com
    % https://it.mathworks.com/matlabcentral/fileexchange/56871-command-line-progress-bar-waitbar

    properties
        last_msg_len = 0;
        iterMsg = "";
        iterations = 0;
    end
    methods
        function obj = CmdLineProgressBar(msg, iterations)
            obj.iterations = iterations;
            obj.iterMsg = msg;
            %fprintf('%s', msg)
        end

        function progress(obj, n)
            fprintf('%s', char(8*ones(1, obj.last_msg_len))) % delete last info_str
            info_str = sprintf('%s %d/%d', obj.iterMsg, n, obj.iterations);
            fprintf('%s', info_str);
            %--- assume user counts monotonically
            if n == obj.iterations
                fprintf('\n')
            end
            obj.last_msg_len = length(info_str);
        end
        %--- dtor
        function delete(obj)
            fprintf('\n')
        end
    end
end