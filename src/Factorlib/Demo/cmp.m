function cmp(A, B, filename)
    FTSASSERT(numel(A)==numel(B));
    set(0, 'DefaultFigureVisible', 'off');
    figfmt = 'height=0.6cm,width=1.8cm';
    
    body = cell(length(A), 7);
    body(:) = {''};
    
    for i = 1:length(A)
        rho = 1;
        if isa(A{i},'FacBase') && isa(B{i}, 'FacBase')
            body{i,2} = A{i}.id;
            body{i,3} = ['\scriptsize ' regexprep(class(A{i}),'_','\\$0')];
            [A{i},B{i}] = aligndates(A{i}, B{i}, A{i}.dates);
            rho = csrankcorr(A{i}, B{i}); 
            body{i,4} = num2str(nanmean(rho, 1), '%.4f');
            tabplot(fts2mat(rho), num2str(i, 'CMP%3.3d'));
            body{i,5} = ['\raisebox{-0.2cm}{\includegraphics[' figfmt ']{' num2str(i, 'CMP%3.3d') '}}'];
        else
            if isempty(A{i})
                body{i,6} = '\textcolor{black}{\checkmark}';
            end
            if isempty(B{i})
                body{i,7} = '\textcolor{black}{\checkmark}';
            end
        end
        
        if nanmean(rho, 1) < 0.99
            body{i,1} = ['\rowcolor{inglblue}' num2str(i)];
        elseif mod(i,2)
            body{i,1} = ['\rowcolor{cone}' num2str(i)];
        else
            body{i,1} = ['\rowcolor{ctwo}' num2str(i)];
        end
    end

    title = {'#' 'Factor' 'Name' '$\overline{\text{corr}}_{bt}$' 'TS' '\textcolor{black}{A}' '\textcolor{black}{B}'};
    p = PDFDoc(filename);
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

