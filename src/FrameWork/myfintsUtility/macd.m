function [macdvec, nineperma] = macd(data, dim)
%MACD   Moving Average Convergence/Divergence (MACD).
%
%   [MACDVEC, NINEPERMA] = MACD(DATA) calculates the Moving Average
%   Convergence/Divergence (MACD) line, MACDVEC, from the data vector, DATA,
%   as well as the 9-period exponential moving average, NINEPERMA, from the
%   MACD line.
%
if nargin < 2, dim = 1; end
if dim == 2, data = data'; end
if isrow(data), data = data'; end

% Pre allocate vars
ema26p = nan(size(data));
ema12p = ema26p;

% Calculate the 26-period (7.5%)exp mov avg and the 12-period (15%) exp mov avg
for i = 1:size(data,2)
    idx = ~isnan(data(:,i));
    ema26p(idx,i) = tsmovavg(data(idx,i), 'e', 26, 1);
    ema12p(idx,i) = tsmovavg(data(idx,i), 'e', 12, 1);
end

% Calculate the MACD line.
macdvec = ema12p - ema26p;

% Calculate the 9-period (20%) exp mov avg of the MACD line.
nineperma = nan(size(data));

for i = 1:size(data,2)
    idx = ~isnan(macdvec(:,i));
    nineperma(idx,i) = tsmovavg(macdvec(idx, i), 'e', 9, 1);
end

end