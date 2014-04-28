classdef ASTABCF < FacBase
    %ASTABCF <a full descriptive name placed here>
    %
    %  Formula:
    %
    %  Description:
    %
    %  Copyright 2012 ING IM AP
    %  Dates: 10-Aug-2012 19:16:03

    methods (Access = protected)
        function factorTS = build(o, secIds, startDate, endDate)
            nQtrs = 16;
            cfo = o.loadItem(secIds,'D000679450',startDate,endDate,nQtrs+1);
            %%%fqtr = o.loadItem(secIds,'D000647426',startDate,endDate,nQtrs+1);
            capex = o.loadItem(secIds,'D000686214',startDate,endDate,nQtrs+1);
            
            window = 3;
            fcfGrth = cell(window,1);
            for i = 1:window
                k = (i-1)*4;
                if i == 1
                    fcf = ftsnansum(cfo{k+1:k+4}) - ftsnansum(capex{k+1:k+4});
                else
                    fcf = fcfLag;
                end
                fcfLag = ftsnansum(cfo{k+5:k+8}) - ftsnansum(capex{k+5:k+8});
                fcfGrth{i} = (fcf - fcfLag)./((abs(fcf)+abs(fcfLag))/2);
            end
            
            factorTS = ftsnanmean(fcfGrth{:});
            factorTS = backfill(factorTS, o.DCF('3M'), 'entry');
        end
    end
end
