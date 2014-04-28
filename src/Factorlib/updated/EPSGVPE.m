classdef EPSGVPE < FacBase
    %EPSGVPE <a full descriptive name placed here>
    %
    %  Formula:
    %
    %  Description:
    %
    %  Copyright 2012 ING IM AP
    %  Dates: 10-Aug-2012 19:16:07
    
    methods (Access = protected)
        function factorTS = build(o, secIds, startDate, endDate)
            LTG=o.loadItem(secIds,'D000435589',startDate,endDate);
            PR=o.loadItem(secIds,'D000432078',startDate,endDate);
            EPS=o.loadItem(secIds,'D000435584',startDate,endDate);
            
            nbf = o.DCF('2M');
            LTG=backfill(LTG,nbf,'entry');
            PR=backfill(PR,nbf,'entry');
            EPS=backfill(EPS,nbf,'entry');
            
            factorTS=LTG.*EPS./PR/100;
        end
        
        function factorTS = buildLive(o, secIds, endDate)
            startDate=datestr(datenum(endDate)-10,'yyyy-mm-dd');
            PR=o.loadItem(secIds,'D000432078',startDate,endDate);
            
            try
                LTG1 = o.loadItem(secIds,'D000448970',startDate,endDate); %qfs ibes
                LTG2 = LTG1;
            catch %#ok<*CTCH>
                LTG2 = o.loadItem(secIds,'D000435589',startDate,endDate); %non qfs
                LTG1 = LTG2;
            end
            
            try
                EPS1 = o.loadItem(secIds,'D000448965',startDate,endDate); %qfs ibes
                EPS2 = EPS1;
            catch
                EPS2 = o.loadItem(secIds,'D000435584',startDate,endDate); %non qfs
                EPS1 = EPS2;
            end
            
            [LTG1,LTG2,PR,EPS1,EPS2]=aligndata(LTG1,LTG2,PR,EPS1,EPS2,datenum(endDate));
            
            LTG1(isnan(fts2mat(LTG1))) = LTG2(isnan(fts2mat(LTG1)));
            EPS1(isnan(fts2mat(EPS1))) = EPS2(isnan(fts2mat(EPS1)));
            
            %% Calculation here USUALLY
            factorTS = LTG1 .* EPS1 ./ PR / 100;
        end
        
        
        
        
    end
end
