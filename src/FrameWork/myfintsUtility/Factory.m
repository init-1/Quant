classdef Factory    
    methods (Static)
        function factors = RunRegistered(factorids, updateMode, isLive, varargin)
        % Call as
        %    RunRegisteredSecId(factorids, isUpdateDB, isLive, targetFreq, secid, startDate, endDate);
        % when isLive == false, or
        %    RunRegisteredSecId(actorids, isUpdateDB, isLive, secid, runDate);
        % when isLive == true
        %
        % updateModel: 'incremental' or 'complete' or 'no'
        %
            if ~iscell(factorids), factorids = {factorids}; end
            
            % Get factor-specific class name from Regtable
            faclist = sprintf(',''%s''', factorids{:});
            facinfo = DB('QuantStrategy').runSql(...
                ['SELECT id, matlabfunction FROM fac.FactorMstr WHERE id in (' faclist(2:end) ') ORDER BY id']);
            factors = Factory.RunFactor(facinfo.matlabfunction, isLive, varargin{:});
            
            if ~iscell(factors), factors = {factors}; end
            if ismember(lower(updateMode), {'incremental' 'complete'})
                for i = 1:numel(factors)
                    if isa(factors{i}, 'FacBase')
                        try
                            if iscell(facinfo.id)
                                factors{i}.id = facinfo.id{i};
                            else
                                factors{i}.id = facinfo.id;
                            end
                            TRACE('Saving as %s to DB ...', factors{i}.id);
                            tic
                            Save2DB(factors{i}, updateMode);
                            TRACE([' done (' interval2str(toc) ')\n']);
                        catch exception
                            factors{i} = exception;
                            TRACE.Err([' ERROR (' exception.identifier ')\n']);
                        end
                    end
                end
            end
            if numel(factors) == 1
                factors = factors{:};
            end
        end
        
        function factors = RunFactor(className, isLive, varargin)
        % Call as
        %    RunFactorSecId(clsname, isLive, targetFreq, secid, startDate, endDate);
        % when isLive == false, or
        %    RunFactorSecId(clsname, isLive, secid, runDate);
        % when isLive == true
        %
            if ~iscell(className), className = {className}; end
            nFac = length(className);
            factors = cell(nFac, 1);
            for i = 1:nFac
                fun = str2func(className{i});
                try
                    tic
                    TRACE(['Running ' className{i} '(%d/%d) ...'], i, nFac);
                    factors{i} = create(fun(), isLive, varargin{:});
                    TRACE([' done (' interval2str(toc) ')\n']);
                catch exception
                    TRACE.Err([' ERROR (' exception.identifier ')\n']);
                    factors{i} = exception;
                    continue;
                end
            end
            if numel(factors) == 1
                factors = factors{:};
            end
        end
        
        function factorId = Register2DB(factorName, factorDesc, factorCreator, isHighBetter, isActive, isProd)
            factorInfo = runSP('QuantStrategy','fac.registerNewFactor',{factorName, factorDesc, factorCreator, isHighBetter, isActive, isProd});
            factorId = factorInfo.Id;
        end
        
    end % of static methods
end % of classdef

function str = interval2str(nSeconds)
   unitstrs = {'day' 'hour' 'minute' 'second'};
   unitbase = [3600*24; 3600; 60];
   str = '';
   for i = 1:4
       if i == 4
           unitval = round(nSeconds);
       else
           unitval = floor(nSeconds / unitbase(i));
           nSeconds = mod(nSeconds, unitbase(i));
       end
       if unitval > 1
           str = [str num2str(unitval) ' ' unitstrs{i} 's ']; %#ok<*AGROW>
       elseif unitval > 0
           str = [str num2str(unitval) ' ' unitstrs{i} ' '];
       end
   end
   str(end) = [];  % remove trailing space
end
