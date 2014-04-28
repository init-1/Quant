% this function replace certain variables in the backtest dataset with new
% values and save to a new dataset

function ReplaceVar(fromfile, tofile, varargin)

replacefield = varargin(1:2:end-1);
replacevalue = varargin(2:2:end);

olddata = load(fromfile);
oldfield = fieldnames(olddata);

existidx = ismember(replacefield, oldfield);
if sum(~existidx) > 0
    warning(['following fields to be replaced do not exist in the original dataset: ', sprintf('%s ', replacefield{~existidx})]);
    replacefield = replacefield(existidx);
    replacevalue = replacevalue(existidx);
end

for i = 1:numel(replacefield)
    if strcmpi(replacefield{i},'startpf')
        assert(isequal(fieldnames(olddata.bmhd,1), fieldnames(startpf,1)), 'stocks in bmhd and startpf used to replace are not aligned');
    elseif isa(replacevalue{i},'myfints')
        if ~isaligneddata(olddata.bmhd, replacevalue{i})
            warning(['data in bmhd and ', replacefield{i},' used to replace are not aligned']);
            replacefts = replacevalue{i};
            replacefts(:,~ismember(fieldnames(replacefts,1), fieldnames(olddata.bmhd,1))) = [];
            [replacefts, olddata.bmhd] = aligndata(replacefts, olddata.bmhd, 'union', olddata.bmhd.dates);
            replacevalue{i} = replacefts;
        end
    end
    olddata.(replacefield{i}) = replacevalue{i};
end

save(tofile, '-struct', 'olddata');

return


