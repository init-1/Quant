classdef DispSkewFY1 < FacBase
    %DispSkewFY1 <a full descriptive name placed here>
    %
    %  Formula:
    %
    %  Description:
    %
    %  Copyright 2012 ING IM AP
    %  Dates: 10-Aug-2012 19:16:07
    
    methods (Access = protected)
        function factorTS = build(o, secIds, startDate, endDate)
            %% Load data here (Loadxxx())
            sDate = datestr(addtodate(datenum(startDate),-2,'M'),'yyyy-mm-dd');
            EPSFY1MN = o.loadItem(secIds, 'D000435584', sDate, endDate);
            EPSFY1SD = o.loadItem(secIds, 'D000435634', sDate, endDate);
            EPSFY1MD = o.loadItem(secIds, 'D000435594', sDate, endDate);
            
            %% call common calculation function
            factorTS = o.calculation(EPSFY1MN, EPSFY1SD, EPSFY1MD);
        end
        
        function factorTS = buildLive(o, secIds, endDate)
            %% Load data here (Loadxxx())
            sDate = datestr(addtodate(datenum(endDate),-2,'M'),'yyyy-mm-dd');
            EPSFY1MN = o.loadItem(secIds, 'D000448965', sDate, endDate);
            EPSFY1SD = o.loadItem(secIds, 'D000449135', sDate, endDate);
            EPSFY1MD = o.loadItem(secIds, 'D000449005', sDate, endDate);

            %% call common calculation function
            factorTS = o.calculation(EPSFY1MN, EPSFY1SD, EPSFY1MD);
        end
        
        function factorTS = calculation(o, EPSFY1MN, EPSFY1SD, EPSFY1MD)
        % calculation function of factor dispersion/skewness IBES FY1
            EPSFY1MN = backfill(EPSFY1MN, o.DCF('Q'), 'entry');
            EPSFY1SD = backfill(EPSFY1SD, o.DCF('Q'), 'entry');
            EPSFY1MD = backfill(EPSFY1MD, o.DCF('Q'), 'entry');
            
            disper = EPSFY1SD ./(abs(EPSFY1MN) + EPSFY1SD);
            skew = abs(EPSFY1MN - EPSFY1MD) ./(abs(EPSFY1MD) + abs(EPSFY1MN - EPSFY1MD));
            
            disper_score = rankScore(disper, 'ascend');
            skew_score = rankScore(skew, 'ascend');
            
            factorTS = 1 - ftsnanmean(disper_score, skew_score);
        end
    end
end

function ofts = rankScore(ifts, mode)
    ifts = csRank(ifts,mode);
    count = sum(~isnan(fts2mat(ifts)),2);
    ofts = bsxfun(@rdivide, ifts, count+1);
end
