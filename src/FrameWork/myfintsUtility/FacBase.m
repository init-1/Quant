classdef FacBase < myfints
    properties (SetAccess = private)
        id = 0;
        name
        higherTheBetter
        isLive
        mode
        priceDateStruct
    end
    
    methods
        function obj = create(obj, secIds, isLive, varargin)
        % Usage:
        %  when isLive is true
        %     factor_object = create(factor_object, secIds, isLive, runDate, 'name', val,...)
        %  or when isLive is false
        %     factor_object = create(factor_object, secIds, isLive, startDate, endDate, targetFreq, 'name', val,...)
        %   
            if isa(secIds, 'myfints')  % First usage, secIds actually is already myfints obj
                fints = secIds;
            else    % Second usage, construct a myfints first
                if isLive
                    FTSASSERT(~isempty(varargin), 'No enough arguments');
                    runDate = varargin{1};
                    varargin(1) = [];
                    [fints, lastestPriceDate] = obj.buildLive(secIds, runDate);
                    if isequal(fints, [])  % obj.buildLive not implemented in derived class
                        % try backtest version with two output parameters
                        [fints, lastestPriceDate] = obj.build(secIds, runDate, runDate, 'M');
                    end
                    obj.priceDateStruct = lastestPriceDate;
                else
                    FTSASSERT(length(varargin) > 2, 'No enough arguments');
                    startDate = varargin{1};
                    endDate = varargin{2};
                    targetFreq = varargin{3};
                    varargin(1:3) = [];
                    fints = obj.build(secIds, startDate, endDate, targetFreq);
                    obj.priceDateStruct = [];
                end
                s.type = '()'; s.subs = {isinf(fints)};
                fints = subsasgn(fints, s, NaN);
            end
            
            obj = obj.copy(fints);
            obj.isLive = isLive;
            pty.name = '';
            pty.desc = '';
            pty.higherTheBetter = true;
            pty = Option.vararginOption(pty, [properties(obj); 'desc'], varargin{:});
            for f = intersect(fieldnames(pty)', properties(obj))
                obj.(f{:}) = pty.(f{:});
            end
        end
    end
    
    methods
        function val = subsref(obj, s)
            if strcmp(s(1).type,'.') && ismember(s(1).subs, properties(obj))
                val = obj.(s(1).subs);
                if length(s) > 1
                   val = subsref(val, s(2:end));
                end
                return;
            end
            val = subsref@myfints(obj, s);
        end
    end
    
    methods (Access = protected, Static)
    % One way to differentiate live and backtest version of build (i.e.,
    % build() and buildLive()) is to check the number of output parameters.
    % This may not very well but hard to change given current status of 
    % Factor Framework.
        function myfts = build(varargin)
            myfts = [];
        end
        function [myfts, priceDateStruct] = buildLive(varargin)
            myfts = [];
            priceDateStruct = [];
        end
    end
    
end
