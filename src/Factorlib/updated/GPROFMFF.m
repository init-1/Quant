classdef GPROFMFF < FacBase
    %GPROFMFF <a full descriptive name placed here>
    %
    %  Formula:
    %
    %  Description:
    %
    %  Copyright 2012 ING IM AP
    %  Dates: 10-Aug-2012 19:16:09

    methods (Access = protected)
        function factorTS = build(o, secIds, startDate, endDate)
            sDate = datestr(datenum(startDate)-186, 'yyyy-mm-dd');
            qtrs = 11;
            sales = o.loadItem(secIds,'D000686629',sDate,endDate,qtrs);
            cogs = o.loadItem(secIds,'D000685790',sDate,endDate,qtrs);
            
            %% Call common calculation function
            window1 = 4;
            sales_ms = movfunPIT(sales, window1, @nansum);
            cogs_ms = movfunPIT(cogs, window1, @nansum);
            
            gm = cell(1,8);
            for i = 1:8
                % gm stands for gross margin
                gm{i} = (1 - cogs_ms{i}./sales_ms{i});
                gm{i}((fts2mat(gm{i})<0)) = NaN;
            end
            
            %% Calculation here USUALLY
            gm_sma = ftsnanmean(gm{1:4});
            gm_sma_lag = ftsnanmean(gm{5:8});
            
            nbf = o.DCF('2M');
            gm_sma = backfill(gm_sma, nbf, 'entry');
            gm_sma_lag = backfill(gm_sma_lag, nbf, 'entry');
            
            factorTS = (gm_sma./gm_sma_lag).*gm{1};
        end
    end
end
