models = {...
    'FAC_MSCI_EAFEv2' ...
    'FAC_MSCI_WORLDV2' ...
    'FAC_APHD' ...
    'FAC_SP500' ...
    'ADM_MSCI_NA_US' ...
    'ADM_SP500' ...
    'FAC_MSCI_WORLDHCV2' ...
    'FAC_MSCI_ZAF' ...
    'FAC_HSI' ...
    'FAC_KLD400' ...
    'FAC_MSCI_CHINA_A' ...
    'FAC_MSCI_EM' ...
    'FAC_MSCI_GOLDEN_DRAGON' ...
    'FAC_MSCI_INDIA' ...
    'FAC_MSCI_NA' ...
    'FAC_MSCI_PACXJ' ...
    'FAC_MSCI_SCAP_BIOTEC' ...
    'FAC_MSCI_WORLDGCC' ...
    'FAC_VALUE_CHINA' ...
    'MSCIEM_EE' ...
    'STYLE_SP500' ...
    'TWSE_ENH' ...
};

prodModels = {...
    'FAC_MSCI_EAFEv2' ...
    'FAC_MSCI_WORLDV2' ...
    'FAC_APHD' ...
    'FAC_SP500' ...
    'ADM_MSCI_NA_US' ...
    'ADM_SP500' ...
    'FAC_MSCI_WORLDHCV2' ...
    'FAC_MSCI_ZAF' ...
};

map = containers.Map('KeyType', 'char', 'ValueType', 'any');
DB('QuantStrategy');

for model = models
    ret = DB.runSql(['select distinct factorid from bld.modelfactormap ' ...
        'where modelid in ' ...
        '(select modelid from bld.strategyModel where strategyid=''' model{:} ''')']);
    map(model{:}) = ret.factorid;
end

allfactors = values(map);
allfactors = unique(cat(1,allfactors{:}));
facflags = false(size(allfactors));
counter = 0;
body = cell(100,3);
allitems = {};
for i = 1:length(allfactors)
    ret = DB.runSql(['select matlabfunction from fac.factormstr where id=''' allfactors{i} '''']);
    filepath = regexprep(which(ret.matlabfunction), '%*', '');
    itemids = grep(filepath, '\<D0024.....\>');
    if ~isempty(itemids)
        facflags(i) = true;
        counter = counter + 1;
        body{counter,1} = allfactors{i};
        body{counter,2} = strrep(ret.matlabfunction, '_', '\_');
        body{counter,3} = itemids;
        allitems = [allitems itemids]; %#ok<AGROW>
    end
end
body = body(1:counter,:);

legends = '';
allitems = unique(allitems);
itemstr = sprintf(',''%s''', allitems{:});
ret = DB.runSql(['select id, left(sourceid,2) as source, dsname from datainterfaceserver.dataqa.api.itemmstr where id in (' itemstr(2:end) ')']);
[source,~,n] = unique(ret.source);
colors = {'purple' 'olive' 'cyan'};
for i = 1:length(source)
    legends = [legends '\quad\textcolor{' colors{i} '}{\textbf{' source{i} '}}(' num2str(sum(n==i)) ')'];
end

brokerfactorcolor = cell(counter,1);
for i = 1:counter
    [tf,loc] = ismember(body{i,3}, ret.id);
    [~, loc] = ismember(ret.source(loc(tf)), source);
    b = [colors(loc); body{i,3}];
    body{i,3} = sprintf('\\textcolor{%s}{%s}\\quad', b{:});
    brokerfactorcolor{i} = colors(loc(1));
end

p = PDFDoc('broker', 'Probe Broker Items in Production');
p.table('Broker Factors Used in Production', {'Factor' 'Matlab' ['Items' legends]}, body, 'llp{10cm}');

counter = 0;
body = cell(100,2);
brokerfactors = allfactors(facflags);
for i = 1:length(models)
    fids = map(models{i});
    tf = ismember(fids, brokerfactors);
    if any(tf)
        counter = counter + 1;
        fids = fids(tf);
        body{counter,1} = strrep(models{i}, '_', '\_');
        [~, loc] = ismember(fids, brokerfactors);
        b = [brokerfactorcolor{loc}; fids'];
        fstr = sprintf('\\textcolor{%s}{%s}\\quad', b{:});
        body{counter,2} = fstr;
    end
end
body = body(1:counter,:);

brokerfactorcolor = [brokerfactorcolor{:}];
legends = '';
for i = 1:length(source)
    legends = [legends '\quad\textcolor{' colors{i} '}{\textbf{' source{i} '}}(' num2str(sum(strcmp(brokerfactorcolor, colors{i}))) ')'];
end

p.writeln('\newpage');
p.table('Models involving Broker Factors', {'Model' ['Factors' legends]}, body, 'lp{10cm}');
p.run;

