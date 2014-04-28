classdef BUYBACK < FacBase
    %BUYBACK <a full descriptive name placed here>
    %
    %  Formula:
    %
    %  Description:
    %
    %  Copyright 2012 ING IM AP
    %  Dates: 10-Aug-2012 19:16:04
    
    methods (Access = protected)
        function factorTS = build(o, secIds, startDate, endDate)
            %% Load data here (Loadxxx())
            sDate = datestr(addtodate(datenum(startDate),-13,'M'),'yyyy-mm-dd');
            shares = o.loadItem(secIds, 'D001410472', sDate, endDate);
            
            %% Calculation here
            factorTS = 1 - shares./o.lagfts(shares, '12M', NaN);
        end
    end
end
