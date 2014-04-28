function test(oldornew, sn, isLive)
% Run as
%     test('new', 'BKTOPRICE') 
% or
%     test('old', 'BKTOPRICE')
%

    tic
    if nargin < 3, isLive = false; end
    if isLive
        matfilesuffix = '.mat';
    else
        matfilesuffix = '_DAVID_bt.mat';
    end
    
    secIds    = LoadIndexHoldingTS('00053', '2012-01-01', '2012-01-31', true);
    startDate = '2009-12-31';
    endDate   = '2012-05-31';
    freq      = 'M';
    dateBasis = DateBasis('BD');

    clsnames = getClassNames;
    counter = length(clsnames);

    if strcmpi(oldornew, 'old')
        TRACE('Running old version\n');
        rmpath(['Y:\' getenv('USERNAME') '\QuantStrategy\Analytics\FactorLib\updated\']);

        matfile = ['ofac' matfilesuffix];
        if exist(matfile, 'file')
            load(matfile);
        else
            ofac = cell(counter, 1);
        end
        
        if ischar(sn)
            clsnames = {sn};
        else
            ofac{sn} = [];
        end

        if isLive
            ofac = runFactors(clsnames, ofac, secIds, isLive, endDate); %#ok<NASGU>
        else
            ofac = runFactors(clsnames, ofac, secIds, isLive, startDate, endDate, freq); %#ok<NASGU>
        end
        save(matfile, 'ofac');
    end

    if strcmpi(oldornew, 'new')
        TRACE('Running new version\n');
        addpath(['Y:\' getenv('USERNAME') '\QuantStrategy\Analytics\FactorLib\updated\']);

        matfile = ['nfac' matfilesuffix];
        if exist(matfile, 'file')
            load(matfile);
        else
            nfac = cell(counter, 1);
        end
        
        if ischar(sn)
            clsnames = {sn};
        else
            nfac{sn} = [];
        end

        if isLive
            nfac = runFactors(clsnames, nfac, isLive, secIds, endDate, dateBasis); %#ok<NASGU>
        else
            nfac = runFactors(clsnames, nfac, isLive, freq, secIds, startDate, endDate, dateBasis); %#ok<NASGU>
        end
        save(matfile, 'nfac');
    end

    if strcmpi(oldornew, 'cmp')
        cmp2(clsnames);
    end
    toc
end

function clsnames = getClassNames
    files = dir('..\updated\');
    if isempty(files)
        TRACE('Nothing found\n');
        return;
    end

    clsnames = cell(length(files), 1);
    counter = 0;
    for i = 1:length(files)
        f = files(i);
        if f.isdir || isempty(regexp(f.name, '\.m', 'ONCE'))
            continue;
        end

        if ~isempty(regexpi(f.name, '(base\>)|(\<GB\_)', 'ONCE')), continue; end
        if strcmpi(f.name, 'GlobalEnhanced.m'), continue; end
        if strcmpi(f.name, 'RIM.m'), continue; end
        if strcmpi(f.name(1), '_'), continue; end
        if strcmpi(f.name, 'check.m'), continue; end
        if strcmpi(f.name, 'loadBondYield.m'), continue; end

        counter = counter + 1;
        clsnames{counter} = f.name(1:end-2);
    end

    clsnames = clsnames(1:counter);
end

function fac = runFactors(clsnames, fac, varargin)
    for i = 1:length(clsnames)
        TRACE('    %s', [clsnames{i} '...']);
        if isempty(fac{i})
            clsfun = str2func(clsnames{i});
            try
                fac{i} = create(clsfun(), varargin{:});
                fac{i}.desc = clsnames{i};
                fac{i} = copy(myfints, fac{i});
                TRACE(' done\n');
            catch e
                if strcmp(e.identifier, 'LOADDATA:NODATA')
                    fac{i} = e;
                    TRACE(' NO DATA\n');
                else
                    %rethrow(e);
                    fac{i} = e;
                    TRACE(' ERROE\n');
                end
            end
        else
            TRACE(' skipped\n');
        end
    end
end

function cmp(classnames)
    load('nfac_bt.mat');
    load('ofac_bt.mat');
    nlive = load('nfac.mat');
    olive = load('ofac.mat');
    nbtw = load('nfacw_bt.mat');
    
    set(0, 'DefaultFigureVisible', 'off');
    figfmt = 'height=0.6cm,width=1.8cm';
    body = cell(length(nfac), 9); %#ok<USENS>
    body(:) = {''};
    for i = 1:length(nfac)
        if mod(i,2)
            body{i,1} = ['\rowcolor{cone}' num2str(i)];
        else
            body{i,1} = ['\rowcolor{ctwo}' num2str(i)];
        end
        body{i,2} = regexprep(classnames{i},'_','\\$0');
        if isa(nfac{i},'myfints') && isa(ofac{i}, 'myfints') %#ok<USENS>
            assert(strcmp(classnames{i}, nfac{i}.desc));
            body{i,2} = ['\scriptsize ' regexprep(nfac{i}.desc,'_','\\$0')];
            rho = csrankcorr(nfac{i}, ofac{i}); 
            body{i,3} = num2str(nanmean(rho, 1), '%.3f');
            tabplot(fts2mat(rho), num2str(i, 'CMP%3.3d'));
            body{i,4} = ['\raisebox{-0.2cm}{\includegraphics[' figfmt ']{' num2str(i, 'CMP%3.3d') '}}'];
        end
        
        if isa(nlive.nfac{i},'myfints') && isa(olive.ofac{i}, 'myfints')
            assert(strcmp(classnames{i}, nlive.nfac{i}.desc));
            rho = csrankcorr(nlive.nfac{i}, olive.ofac{i});
            body{i,5} = num2str(nanmean(rho, 1), '%.3f');
        end
        
        if isa(nbtw.nfac{i},'myfints') 
            w = nbtw.nfac{i};
            rho = csrankcorr(w, lagts(w,1));
            body{i,8} = num2str(nanmean(rho, 1), '%.3f');
            tabplot(fts2mat(rho), num2str(i, 'RHOW%3.3d'));
            body{i,9} = ['\raisebox{-0.2cm}{\includegraphics[' figfmt ']{' num2str(i, 'RHOW%3.3d') '}}'];
            if isa(nfac{i}, 'myfints')
                w = aligndates(w, nfac{i}.dates);
                rho = csrankcorr(w, nfac{i});
                body{i,6} = num2str(nanmean(rho, 1), '%.3f');
                tabplot(fts2mat(rho), num2str(i, 'CMPW%3.3d'));
                body{i,7} = ['\raisebox{-0.2cm}{\includegraphics[' figfmt ']{' num2str(i, 'CMPW%3.3d') '}}'];
            end
        end
    end

    title = {'#' 'Factor' '$\overline{\text{corr}}_{bt}$' 'TS' '$\text{corr}_{live}$' '$\overline{\text{corr}}_{w,m}$' 'TS' '$\overline{\text{corr}}_{auto}$' 'TS'};
    p = PDFDoc('cmp');
    p.writeln('\setlength\tabcolsep{3pt}');
    p.table('', title, body, 'rl|rrr|rr|rr');
    p.run;
end

function cmp2(classnames)
    load('nfac_david_bt-nocache.mat');
    old = load('nfac_bt.mat');
    ofac = old.nfac;
    
    set(0, 'DefaultFigureVisible', 'off');
    figfmt = 'height=0.6cm,width=1.8cm';
    body = cell(length(nfac), 8); %#ok<USENS>
    body(:) = {''};
    for i = 1:length(nfac)
        rho = 1;
        body{i,2} = regexprep(classnames{i},'_','\\$0');
        if isa(nfac{i},'myfints') && isa(ofac{i}, 'myfints')
            assert(strcmp(classnames{i}, nfac{i}.desc));
            body{i,2} = ['\scriptsize ' regexprep(nfac{i}.desc,'_','\\$0')];
            rho = csrankcorr(nfac{i}, ofac{i}); 
            body{i,3} = num2str(nanmean(rho, 1), '%.4f');
            tabplot(fts2mat(rho), num2str(i, 'CMP%3.3d'));
            body{i,4} = ['\raisebox{-0.2cm}{\includegraphics[' figfmt ']{' num2str(i, 'CMP%3.3d') '}}'];
        elseif strcmpi(nfac{i}.identifier, 'LOADDATA:NODATA')
            body{i,8} = '\textcolor{black}{\checkmark}';
        end
        
        if nanmean(rho, 1) < 0.99
            body{i,1} = ['\rowcolor{inglblue}' num2str(i)];
        elseif mod(i,2)
            body{i,1} = ['\rowcolor{cone}' num2str(i)];
        else
            body{i,1} = ['\rowcolor{ctwo}' num2str(i)];
        end
        
        filepath = which(classnames{i});
        for j = 1:2
            ids = grep(filepath, '\<D00.......\>');
            if any(strncmp('D0004', ids, 5))
                body{i,5} = '\textcolor{black}{\checkmark}';
            end
            if any(strncmp('D0006', ids, 5) | strncmp('D0020', ids, 5))
                body{i,6} = '\textcolor{purple}{\checkmark}';
            end
            if any(strncmp('D0024', ids, 5))
                body{i,7} = '\textcolor{black}{\checkmark}';
            end
            if j == 2, break; end
            mc = eval(['?' classnames{i}]);
            filepath = mc.SuperClasses{1}.Name;
            if ~ismember(filepath, {'FacBase', 'GlobalEnhanced'})
                filepath = which(filepath);
            end
        end
    end

    title = {'#' 'Factor' '$\overline{\text{corr}}_{bt}$' 'TS' '\textcolor{black}{IBES?}' ...
             '\textcolor{cyan}{PIT?}' '\textcolor{black}{Broker?}' '\textcolor{black}{No Data}'};
    p = PDFDoc('cmp');
    p.table('', title, body);
    p.run;
end


function tabplot(r, fname)
    figure
    set(gcf, 'PaperUnits', 'centimeters', ...
        'PaperSize', [2 1], ...
        'PaperPosition', [-0.58 -0.38 2.8 1.48]);
    if numel(r) > 1
        plot(r, 'linewidth', 1);
        set(gca, 'XLim', [1 numel(r)], 'YLim', [0 1]);
    end
    set(gca, 'box', 'off', 'visible', 'off', 'color', 'none');
    saveas(gcf, [fname '.pdf']);
    close
end

