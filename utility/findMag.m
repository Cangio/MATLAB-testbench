function [val, mag] = findMag(num)
	% [val, mag] = findMag(num)
	% 
	% ex: findMag(1.3e5) -> [130, 'k']
	%
	% INPUT:
	% 		num: the number to analyze
	%
	% OUTPUT:
	%		val: float 
	%			number 1<val<1000
	%		mag: char
	%			human readable magnitude
    
	dn = abs(num);
	ex = 0; % Exponent
	if num >= 1
		while dn >= 1
			ex = ex + 3;
			dn = dn * 10^-3;
		end
		ex = ex - 3;
		val = dn * 10^3;
	else
		while dn <= 1
			ex = ex - 3;
			dn = dn * 10^3;
		end
		ex = ex + 3;
		val = dn * 10^-3;

	end

	switch ex
		case 9
			mag = 'G';
		case 6
			mag = 'M';
		case 3
			mag = 'k';
		case -3
			mag = 'm';
		case -6
			mag = 'u';
		case -9
			mag = 'n';
		otherwise
			mag = '';
end