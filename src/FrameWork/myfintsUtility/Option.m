classdef Option
  methods (Static)
    function option = vararginOption(option, optionNames, varargin)
    % Process named variable arguments. 
    % User can provide default values in option struct.
    % option values not provided by varargin are set to empty ([]). 
    % All unprocessed options (not appear in optionNames) are preserved and
    % returned in option.varargin.
    % Call usage:
    %    option = vararginOption(option, optionNames, optionName1, optionValue1, ...)
    % or
    %    option = vararginOption(optionNames, optionName1, optionValue1, ...)

        if ~isstruct(option) % check if first argument is actually option user provided which may contain some default values
            % We determined that user actually call this as
            %   vararginOption(optionNames, varargin)
            % but our function signature has more one argument, so
            % we shift left the arguments since user didn't provide option
            % and the first argument actually is optionNames and the second
            % should be mergered into varargin
            varargin = [optionNames, varargin];
            optionNames = option;
            option = [];  % option no use any more, gone so that the following can work smoothly
            for vname = optionNames
                option.(vname{:}) = [];
            end
        end   % else already there are some default init values in option

        option.varargin = {};    % we will put any unprocessed fields here
        for i = 1:2:length(varargin)
            vname = varargin{i};
            tf = strcmpi(vname, optionNames);
            if any(tf)
                vname = optionNames{tf};
                option.(vname) = varargin{i+1};
            else
                option.varargin = [option.varargin, {vname}, varargin(i+1)];
                warning('VAROPTION:UNRECOG', 'Unrecognized parameter %s will be ignored.', vname);
            end
        end
    end
      
    function cellargs = stackOption(option)
        fs = fieldnames(option);
        cellargs = cell(1, length(fs)*2);
        leftover = {};
        i = 1;
        for f = fs'
            if strcmp(f, 'varargin')
                leftover = option.(f{:});
                cellargs(end-1:end) = [];
                continue;
            end
            cellargs(i) = f;
            cellargs{i+1} = option.(f{:});
            i = i + 2;
        end
        cellargs = [cellargs leftover];
    end
    
    function cases = genCases(varargin)
        for i = 1:3:length(varargin)
            if ~iscell(varargin{i+1})
                varargin{i+1} = varargin(i+1);
            end
            if ~iscell(varargin{i+2})
                varargin{i+2} = varargin(i+2);
            end
            option.(varargin{i}) = varargin{i+1};
            caseID.(varargin{i}) = varargin{i+2};
        end
        
        flds = fields(option);

        count = 1;
        cases = {{''}};  % the vary first slot is for caseid concatenation
        while count <= length(flds)
            [cases,count] = pair(cases,count);
        end

        function [pn,i] = pair(po, i) % po: old pairs; pn: new pairs
            M = length(po);   % po: old pairs
            N = length(option.(flds{i}));
            pn = cell(1, N*M); % pn: new pairs (augmented)
            c = 0;
            for m = 1:M
                for n = 1:N
                    c = c + 1;
                    pn{c} = [po{m}, flds{i}, option.(flds{i})(n)];
                    pn{c}{1} = [pn{c}{1} caseID.(flds{i}){n}];
                end
            end
            pn = pn(1:c);
            i = i+1;  % reflect the progress
        end
    end
    
  end  % of methods
end
