classdef DateBasis
    properties (SetAccess = protected)
        nY
        nQ
        nM
        nW
        nD
        isBusDay
        freqBasis
    end
    
    methods
        function o = DateBasis(freqBasis, nY, nQ, nM, nW, nD, isBusDay)
            if nargin == 1 && ischar(freqBasis)
                [~,freqBasis] = DateBasis.tenor(freqBasis);
                switch upper(freqBasis)
                    case 'BD'
                        o = DateBasis('D',  252,  21*3, 21,    5, 1, true);
                        return;
                    case 'BW'
                        o = DateBasis('W', 50.4,  12.6, 4.2,   1, 5, true);
                        return;
                    case 'BM'
                        o = DateBasis('M',   12,   3,   1,  5/21, 1/21, true);
                        return;
                    case 'D'
                        o = DateBasis('D', 365.25, 91.25, 30.5, 7, 1, false);
                        return;
                    case 'W'
                        o = DateBasis('W', 52.1429, 13, 4.35, 1, 7, false);
                        return;
                    case 'M'
                        o = DateBasis('M', 12, 3, 1, 7/30.5, 1/30.5, false);
                        return;
                end
            end
            
            FTSASSERT(nargin == 7, 'Not expected arguments');
            o.freqBasis = freqBasis;
            o.nY = nY;
            o.nQ = nQ;
            o.nM = nM;
            o.nW = nW;
            o.nD = nD;
            o.isBusDay = isBusDay;
        end
        
        function dates = genDates(o, startDate, endDate, freq)
            [tau, freq] = DateBasis.tenor(freq);
            dates = genDateSeries(startDate, endDate, freq, 'Busdays', o.isBusDay);
            if tau ~= 1
                n = numel(dates);
                idx = 1:tau:n;
                if idx(end) ~= n, idx = [idx n]; end
                dates = dates(idx);
            end
        end
        
        function factor = cvtfactor(o, targetfreq, srcfreq)
            if nargin < 3, srcfreq = o.freqBasis; end
            
            map = {'D', 'nD' ...
                 ; 'W', 'nW' ...
                 ; 'M', 'nM' ...
                 ; 'Q', 'nQ' ...
                 ; 'A', 'nY' ...
                 ; 'Y', 'nY'};
            [tf,loc] = ismember(upper({srcfreq, targetfreq}), map(:,1));
            FTSASSERT(all(tf), 'invalid frequency indicators');
            src = map{loc(1),2};
            tgt = map{loc(2),2};
            factor = o.(tgt) ./ o.(src);
        end
    end
    
    methods (Static)
        function [tau, unit] = tenor(str)
            % str is something like '3M', '6D', '1Y', '2Q'. We may even allow
            % '5BD' later.
            [tau,~,~,nextidx] = sscanf(str, '%d', 1);
            if isempty(tau)
                tau = 1;
                nextidx = 1;
            end
            unit = sscanf(str(nextidx:end), '%s', 1);
        end
    end
end

