classdef BKTOPRICE < FacBase
    %BKTOPRICE <a full descriptive name placed here>
    %
    %  Formula:
    %    {Book to Price} = {Total Equity Reported} / {Price} * {Shares Outstanding}
    %  All balance sheet items are being averaged on last four quarter values
    %
    %  Description:
    %    A popular multiple to value stock.
    %
    %  Copyright 2012 ING IM AP
    %  Dates: 10-Aug-2012 19:16:03

    methods (Access = protected)
        function factorTS = build(o, secIds, startDate, endDate)
            % book value is an accounting item and therefore Point-in-Time data will be retrieved
            bookValue = o.loadItem(secIds,'D000686133',startDate,endDate,4);
            % close price and NO. of shares are real time data so no PIT needed
            closePrice = o.loadItem(secIds,'D001410415',startDate,endDate);
            shares = o.loadItem(secIds,'D001410472',startDate,endDate);
            
            % Calculate the mean of last n-quarter book value for each point in time
            bookValueMean = ftsnanmean(bookValue{:});
            bookValueMean = backfill(bookValueMean, o.DCF('3M'),'entry');
            
            % multiply bookValueMean by 1 million because the data in compustat is in the unit of million
            factorTS = (1000000*bookValueMean./shares)./closePrice;
        end
    end
end
