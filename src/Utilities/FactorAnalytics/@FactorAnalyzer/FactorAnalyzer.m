% Class: FactorAnalyzer
% To read data from DB and perform analysis 
% Author: Louis Luo
% Last Modifying Date: 2012-01-20

% this file only contains constructor and static function, other member methods are stored in the same folder outside this file
classdef FactorAnalyzer
properties (SetAccess = private, GetAccess = public)
    freq
    aggid
    univname
    ctrylist
    dateParam           
    facinfo
    factorts
    bmhd
    gics        
    ctry
    ctrysect
    ctryb2p 
    mcap
    b2p
    beta
    brcost
    adv

    fwdret
    fwdretByDay
    statistics
    nbucket
    
    corrmat
    riskmodel
    
    periodstatistics % added for strategy factor monitor
end

properties (Constant)
end

methods 
    function o = FactorAnalyzer(facinfo, AggidOrSecid, startdate, enddate, isprod, freq, ctrylist, nbucket, dateParam, univname)            
        if ~isfield(facinfo,'ishigh')
            facstruct = LoadFactorInfo(facinfo.name,'HigherTheBetter',isprod);
            facinfo.ishigh = facstruct.HigherTheBetter';                
        end
        o.aggid = AggidOrSecid;
        o.univname = univname;
        o.facinfo = facinfo;
        o.nbucket = nbucket;            
        o.ctrylist = ctrylist;            
        o.freq = freq;
        o.dateParam = dateParam;
        o = LoadUnivData(o, AggidOrSecid, startdate, enddate, isprod);  
        secids = FieldId2QuantId(fieldnames(o.bmhd,1));

        if FactorAnalyzer.isFactorId(facinfo.name)
            o.factorts = FactorAnalyzer.LoadFactor(secids, facinfo.name, startdate, enddate, isprod, o.freq, o.dateParam{:});                
        else
            o.factorts = FactorAnalyzer.RunFactorBT(facinfo.name, secids, startdate, enddate, o.freq, o.dateParam{:});
        end

        [o.factorts{:}, o.bmhd, o.ctry, o.ctrysect, o.ctryb2p, o.gics, o.fwdret, o.mcap, o.beta, o.b2p, o.brcost,o.adv, o.fwdretByDay{:}] ...
            = aligndata(o.factorts{:}, o.bmhd, o.ctry, o.ctrysect, o.ctryb2p, o.gics, o.fwdret, o.mcap, o.beta, o.b2p, o.brcost,o.adv, o.fwdretByDay{:});
        
        for i = 1:numel(o.factorts)
            % !!! don't change the parameter of winsorizedata
            o.factorts{i}(:,:) = WinsorizeData(fts2mat(o.factorts{i}), 'pct', 0.02, 'nsigma', 6);
        end
    end
end % end of methods

methods (Static)               
    function fts = LoadFactor(secids, factorid, startdate, enddate, isprod,  freq, varargin)
        fts = cell(size(factorid));
        dates = genDateSeries(startdate, enddate, freq, varargin{:});
        fids = QuantId2FieldId(secids);
        T = length(dates);
        N = numel(secids);
        for i = 1:numel(factorid)                
            try
                disp(['Running Factor - ' factorid{i}]);
                if isprod == 1
                    fts{i} = LoadFactorTSProd(secids, factorid{i}, startdate, enddate, 1);
                elseif isprod == 0
                    fts{i} = LoadFactorTS(secids, factorid{i}, startdate, enddate, 0);
                end
            catch
                disp(['No data for factor- ' factorid{i}]);
                fts{i} = myfints(dates,nan(T,N),fids);
            end                
            fts{i} = aligndates(fts{i}, dates);
            fts{i} = backfill(fts{i}, 400);
        end
    end
    
    function [secids, fts] = LoadIndexHolding(aggid, startdate, enddate, islive, freq, varargin)
        [secids, fts] = LoadIndexHoldingTS(aggid, startdate, enddate, islive, freq);
        dates = genDateSeries(startdate, enddate, freq, varargin{:});
        fts = aligndates(fts, dates);
        fts = backfill(fts, 400);
    end

    function fts = LoadRawItem(secids, itemid, startdate, enddate, freq, varargin)
        fts = LoadRawItemTS(secids, itemid, startdate, enddate);
        dates = genDateSeries(startdate, enddate, freq, varargin{:});
        fts = aligndates(fts, dates);
        fts = backfill(fts, 400, 'entry');
    end

    function fts = LoadSecTS(secids, itemid, seq, startdate, enddate, freq, varargin)
        fts = LoadQSSecTS(secids, itemid, seq, startdate, enddate);
        dates = genDateSeries(startdate, enddate, freq, varargin{:});
        fts = aligndates(fts, dates);
        fts = backfill(fts, 400, 'entry');
    end

    function fts = LoadFacDecile(secids, factorid, startdate, enddate, isprod, freq, nbucket, bmhd, varargin)
        if isprod == 1
            fts = LoadFactorDecile(secids, factorid, startdate, enddate, 1, freq, nbucket, isprod, bmhd);
        elseif isprod == 0
            fts = LoadFactorDecile(secids, factorid, startdate, enddate, 0, freq, nbucket, isprod, bmhd);
        end
        dates = genDateSeries(startdate, enddate, freq, varargin{:});
        fts = aligndates(fts, dates);
        fts = backfill(fts, 400, 'entry');
    end

    function fts = LoadItemDecile(secids, itemid, startdate, enddate, freq, nbucket, bmhd, varargin)
        fts = LoadRawItemDecile(secids, itemid, startdate, enddate, freq, nbucket, bmhd);
        dates = genDateSeries(startdate, enddate, freq, varargin{:});
        fts = aligndates(fts, dates);
        fts = backfill(fts, 400, 'entry');
    end

    function fts = RunFactorBT(factorname, secids, startdate, enddate, freq, varargin)
        fts = cell(size(factorname));
        for i = 1:numel(factorname)
            disp(['Running Factor: ' factorname{i}]);
            fts{i} = create(eval(factorname{i}),  secids, 0, startdate, enddate, freq);
        end
        dates = genDateSeries(startdate, enddate, freq, varargin{:});
        [fts{:}] = aligndates(fts{:}, dates);     
        fts = cellfun(@(x) {backfill(x,400,'entry')}, fts);
    end

    function fts = RunFactorLive(factorname, aggid, enddate)
        fts = Factory.RunFactor(factorname,aggid, 1, enddate);
    end

    function isTrue = isFactorId(name)
        if strcmpi(name{1}(1:3), 'F00')
            isTrue = true;
        else
            isTrue = false;
        end
    end

end
    
end


