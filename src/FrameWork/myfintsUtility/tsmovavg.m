function vout = tsmovavg(vin, mode, win, dim)
%TSMOVAVG calculates the (weighted) moving average of a vector of data.
%
%   Syntax: VO = TSMOVAVG(VI, 's', LAG, DIM)        => SIMPLE, s
%           VO = TSMOVAVG(VI, 'e', TIMEPER, DIM)    => EXPONENTIAL, e
%           VO = TSMOVAVG(VI, 't', NUMPER, DIM)     => TRIANGULAR, t
%           VO = TSMOVAVG(VI, 'w', WEIGHTS, DIM)    => WEIGHTED, w
%           VO = TSMOVAVG(VI, 'm', NUMPER, DIM)     => MODIFIED, m
if nargin < 4, dim = 1; end
if nargin < 3, win = 5; end
if nargin < 2, mode = 's'; end

if dim == 2, vin = vin'; end
FTSASSERT(numel(win) == 1 && win > 0 && win < size(vin,1), ...
    'win must be scalar greater than 0 or less than the number of observations.');

switch lower(mode)
    case 's'
        b = ones(1,win)./win;
        vout = filter(b, 1, vin);
    case 'e'
        % Calculate based on recursive formula:
        %  S_t = k * Y_t + (1-k) * S_{t-1}
        % where k = 2 / (win+1);
        k = 2 / (win+1);
        kvin = vin * k;
        oneK = 1-k;
        vout = nan(size(vin));
        vout(win-1,:) =  sum(vin(1:win,:),1)./win; % facilitate the loop below
        for idx = win:size(vin,1)
            vout(idx,:) = kvin(idx,:) + vout(idx-1,:) * oneK;
        end
    case 't'
        % Window size
        win = ceil((win + 1) / 2);
        b = ones(1,win) ./ win;
        vout = filter(b, 1, filter(b, 1, vin));
    case 'w'
        b = win;  % in this case, win actually is a vector representing weights
        vout = filter(b, sum(b), vin);
    case 'm'
        b = ones(1,win)./win;
        vout = filter(b, 1, vin);
        for idx = win+1:size(vin,1)
            vout(:,idx) = vout(:,idx-1) + (vin(:,idx)-vout(:,idx-1))/win;
        end
    otherwise
        FTSASSERT(false, ['Unrecognized ' inputname(2) ' parameter']);
end

vout(1:win-1,:) = NaN;
if dim == 2
    vout = vout';
end
end
