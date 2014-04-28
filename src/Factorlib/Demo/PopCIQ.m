%% Script to massively populate factor values to FactorTS_BT and FactorTS_Live
% function PopFactor(aggId, startDate, endDate, isLive)
TRACE.Attach('PopCIQ.log');
addpath(['Y:\' getenv('USERNAME') '\QuantStrategy\Analytics\FactorLib\updated\']);

isLive     = false;
isUpdateDB = 2;
startDate  = '1998-12-31';
endDate    = '2012-08-31';
targetFreq = 'M';
aggIds     = {}; %'00053' '0064106233' '0064891800' '0064990100' '0064899903'
dateBasis = DateBasis('M');

secids = LoadIndexHoldingTS(aggIds, startDate, endDate, isLive, targetFreq);

if isLive
    args = {secids, endDate};
else
    args = {targetFreq, secids, startDate, endDate, dateBasis};
end

db = DB('QuantStrategy');

%%%%%%%%%%%%%%% Register %%%%%%%%%%%%%%%%%%%%%%
% startid = 270;
% fmstr = db.runSql(['select * from fac.factormstr where id<''' num2str(startid,'F%5.5d') ''' order by id']);
% nFactor = length(fmstr.Id);
% for i = 1:nFactor  % 1:232, 237:269
%     clsname = fmstr.MatlabFunction{i};
%     for k = 1:2
%         filepath = regexprep(which(clsname), '%*', '');
%         if isempty(filepath)
%             idx = false;
%             TRACE.Warn(['I can''t find ' clsname '.m\n']);
%             break;
%         end
%         itemids = grep(filepath, '\<D00.......\>');
%         idx = ismember(itemids, DB.ITEM_MAP(:,2));
%         if any(idx)
%             break;
%         else
%             mc = eval(['?' clsname]);
%             clsname = mc.SuperClasses{1}.Name;
%             if ismember(clsname, {'FacBase', 'GlobalEnhanced'})
%                 break;
%             end
%         end
%     end
%     
%     if fmstr.IsActive{i} && any(idx) && isempty(strfind(fmstr.MatlabFunction{i}, 'RIG'))
%         %fmstr.Id{i}(3) = '1';
%         srcid = fmstr.Id{i};
%         id = startid; % started from 270
%         startid = startid + 1;
%         fmstr.Id{i} = num2str(id, 'F%5.5d');
%         try
%             tf = db.runSql(['select * from fac.factormstr where id=''' fmstr.Id{i} '''']);
%             TRACE([fmstr.Id{i} ' has been registered.\n']);
%         catch e
%             if isnan(fmstr.FactorTypeId(i))
%                 vstr = sprintf('values(''%s'', ''%s'', ''%s'', ''%s'', NULL, %d, ''%s'', %d, %d, %d)', ...
%                 fmstr.Id{i}, fmstr.Name{i}, fmstr.Desc_{i}, fmstr.MatlabFunction{i}, ...
%                 fmstr.IsActive{i}, srcid, fmstr.InProduction{i}, fmstr.HigherTheBetter(i), fmstr.QSItemId(i));
%             else
%                 vstr = sprintf('values(''%s'', ''%s'', ''%s'', ''%s'', %d, %d, ''%s'', %d, %d, %d)', ...
%                 fmstr.Id{i}, fmstr.Name{i}, fmstr.Desc_{i}, fmstr.MatlabFunction{i}, fmstr.FactorTypeId(i), ...
%                 fmstr.IsActive{i}, srcid, fmstr.InProduction{i}, fmstr.HigherTheBetter(i), fmstr.QSItemId(i));
%             end
%             
%             str = ['insert into fac.factormstr '...
%                 '(id,name,desc_,matlabfunction,factortypeid,isactive,sourceid,inproduction,higherthebetter,qsitemid) '...
%                 vstr];
%             str = regexprep(str, '\<NaN\>', '''''');
%             db.runSql(str);
%             TRACE(['Registered ' fmstr.Id{i} '\n']);
%         end
%     end
% end

%%%%%%%%%%%%%%%%%%% Populate %%%%%%%%%%%%%%%%%%%%%
fmstr = db.runSql('select * from fac.factormstr where id>=''F00270'' and id<''F01000'' order by id');
nFactor = length(fmstr.Id);
factors = cell(nFactor,1);
oldFacs = cell(nFactor,1);

for i = 1:nFactor-1
    factors{i} = Factory.RunRegistered(fmstr.Id(i), 'complete', isLive, args{:});

%     try
%     factors{i} = LoadFactorTS(secids, fmstr.Id{i}, startDate, endDate, isLive, 'M', true, dateBasis);
%     catch e
%     end
% 
    try   
    oldFacs{i} = LoadFactorTS(secids, fmstr.SourceId{i}, startDate, endDate, isLive, 'M');
    catch e
    end
end

cmp(factors, oldFacs, ['cmp-' aggIds{1}]);



