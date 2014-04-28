% this function calculate factor portfolio return
% variable inputs you can have
%     <qtile>: the quantile threshold defining portfolio holding 
%              ([0,0.5,1] means long top 50% of all stocks & short bottom 50%)
%     <wgtmethod>: the weighting method when constructing factor portfolio 
%               'signal': signal weighted
%               'BMWgtCapped': short side uses - benchmark weight, long side is signal weighted
%               'BMSigWgtCapped': long-short are both signal weighted, but short side is capped by benchmark weight

function [lsrtn, longrtn, shortrtn, factorPF, longPF, shortPF] = factorPFRtn(factorts,fwdret,bmhd,varargin)    
    % the case of long/short signal weighted factor portfolio
    option.qtile = [0,0.5,1];
    option.wgtmethod = 'signal';
    option = Option.vararginOption(option, {'wgtmethod'}, varargin{:});
    
    if strcmpi(option.wgtmethod, 'signal') % signal weighted by both long side and short side
%% modified by Louis on Jun-04-2012        
%         [QR, qtweight] = csqtrtn(factorts, fwdret, 'univ', bmhd, 'qtile', option.qtile, 'weight', abs(factorts));
%         longwgt = qtweight{end};
%         shortwgt = -qtweight{1};
%         longrtn = bsxfun(@plus, QR(:,end), -cssum(fwdret.*bmhd));
%         shortrtn = bsxfun(@plus, -QR(:,1), cssum(fwdret.*bmhd));   
        [longwgt, shortwgt] = longshort(factorts, 'univ', bmhd, 'threshold', 0, 'weight', abs(factorts)); % construct long short portfolio
        longrtn = cssum(longwgt.*fwdret);
        shortrtn = cssum(shortwgt.*fwdret);
        longPF = longwgt;
        shortPF = shortwgt;
        
    elseif strcmpi(option.wgtmethod, 'BMWgtCapped') % long side signal weighted, short side benchmark weighted
%% modified by Louis on Jun-04-2012          
%         weightshort = bmhd;
%         [~, qtweightshort] = csqtrtn(factorts, fwdret, 'univ', bmhd, 'qtile', option.qtile, 'weight', weightshort);
%         
%         weightlong = abs(factorts);
%         [~, qtweightlong] = csqtrtn(factorts, fwdret, 'univ', bmhd, 'qtile', option.qtile, 'weight', weightlong);
%         
%         longwgt = qtweightlong{end};
%         shortwgt = -qtweightshort{1};
        [~, shortwgt] = longshort(factorts, 'univ', bmhd, 'threshold', 0, 'weight', bmhd); % construct short portfolio
        [longwgt, ~] = longshort(factorts, 'univ', bmhd, 'threshold', 0, 'weight', abs(factorts)); % construct long portfolio
        
        shortwgt(shortwgt<0) = -bmhd(shortwgt<0); % scale down the shortside weight to mimic long-only constraints
        longwgt = bsxfun(@times, longwgt, cssum(abs(shortwgt))); % scale down the longside weight to match the short-side constraints
        
        longrtn = cssum(longwgt.*fwdret);
        shortrtn = cssum(shortwgt.*fwdret);
        
        longPF = longwgt;
        shortPF = shortwgt;    
        
    elseif strcmpi(option.wgtmethod, 'BMSigWgtCapped') % long side signal weighted, short side trying its best to get signal weighted unless capped by benchmark weight
%% modified by Louis on Jun-04-2012  
%         [~, qtweightshort] = csqtrtn(factorts, fwdret, 'univ', bmhd, 'qtile', option.qtile, 'weight', abs(factorts));        
%         [~, qtweightlong] = csqtrtn(factorts, fwdret, 'univ', bmhd, 'qtile', option.qtile, 'weight', abs(factorts));        
%         longwgt = qtweightlong{end};
%         shortwgt = -qtweightshort{1};
        [longwgt, shortwgt] = longshort(factorts, 'univ', bmhd, 'threshold', 0, 'weight', abs(factorts)); % construct long short portfolio
        
        bmhd_shortside = -bmhd;
        bmhd_shortside(~(shortwgt<0)) = 0; 
        shortwgt_scaled = bsxfun(@times,shortwgt,cssum(abs(bmhd_shortside))); % scale the shortside of the signal to the sum of the shortside bmhd
        
        shortwgt = bsxfun(@max,shortwgt_scaled,bmhd_shortside); % compare the signal wgt with bmhd wgt for the short side and pick the maximum
        longwgt = bsxfun(@times, longwgt, cssum(abs(shortwgt))); % scale down the longside weight to match the short-side constraints
        
        longrtn = cssum(longwgt.*fwdret);
        shortrtn = cssum(shortwgt.*fwdret);
        
        longPF = longwgt;
        shortPF = shortwgt;
    end
    
    factorPF = longwgt + shortwgt;
    
    % lsrtn = longrtn + shortrtn
    lsrtn = bsxfun(@plus, longrtn, shortrtn); % long - BM + ( -Short + BM) = long - short
    
end

function [longweight, shortweight] = longshort(factorts, varargin)
% this helper function construct a long short portfolio based on input signal, holding and weight
option.univ = factorts;
option.threshold = 0;
option.weight = factorts;

option = Option.vararginOption(option, {'univ','threshold','weight'}, varargin{:});

assert(isaligneddata(factorts, option.univ, option.weight), 'Input data not aligned');
assert(~any(any(fts2mat(option.weight) < 0)), 'negative input weight not allowed');

factorts(isnan(option.univ)) = NaN;
option.weight(isnan(option.univ)) = 0;

longweight = option.weight;
longweight(factorts < option.threshold) = 0;
longweight = bsxfun(@rdivide, longweight, nansum(longweight,2));

shortweight = option.weight;
shortweight(factorts > option.threshold) = 0;
shortweight = -bsxfun(@rdivide, shortweight, nansum(shortweight,2));

end


