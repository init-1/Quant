function varargout = TruncateTS(startdate, enddate, varargin)
% this function truncate a number of time series by user specified
% startdate and enddate
varargout = varargin;
if ~isempty(startdate)
    startdate = datenum(startdate);
    for i = 1:numel(varargout)
        varargout{i}(varargout{i}.dates < startdate, :) = [];
    end
end

if ~isempty(enddate)
    enddate = datenum(enddate);
    for i = 1:numel(varargout)
        varargout{i}(varargout{i}.dates > enddate, :) = [];
    end
end

