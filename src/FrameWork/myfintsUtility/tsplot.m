function h = tsplot(x, series, varargin)
[m, n] = size(series); % From now on, m is number of observations, n is number of series

%% Process arguments
o.title = ' ';
o.style = {'b', 'g', 'r', 'k', 'c', 'm', 'y'};
o.xticklabels = num2str(x);
o.xtickLabelRotation = 45;
o.xadjust = false;
o.ylabel = ' ';
o.ymax = [];
o.ymin = [];
o.ycolor = {[0 0 0]};
o.notes = ' ';
o.group = [];
o.layout = [];
o.range = [];
o.hornlineposn = [];
o.vertlineposn = [];
o.legend = {};
o.drawfun = {@plot};
o.figure = [];
o.fontsize = 8;
o.orientation = 'Portrait';
o = Option.vararginOption(o, fieldnames(o), varargin{:});
if iscell(o.xticklabels)
    len = max(cellfun(@length, o.xticklabels));
    o.xticklabels = cellfun(@(x){sprintf('%*.*s',len,len,x);}, o.xticklabels);
    if size(o.xticklabels,2) > 1
        o.xticklabels = o.xticklabels';
    end
    o.xticklabels = cell2mat(o.xticklabels);
end

%% Check the group (numericial matrix) argument
% 1 group: every row of group represents a subplot and every
% column represents a series
[numPlots, n1] = size(o.group);
if numPlots == 0 || n1 == 0
    o.group = true(1, n);
    numPlots = 1;
else
    FTSASSERT(n1 == n, ['the dimension of group and ' inputname(1) ' are not argree.']);
end

%% Check layout
if isempty(o.layout)
    o.layout = [numPlots 1];
end

%% Check range
if isempty(o.range)
    o.range = mat2cell((1:numPlots)', ones(numPlots,1));
end

%% Check drawfun
if ~iscell(o.drawfun), o.drawfun = {o.drawfun}; end
FTSASSERT(isa(o.drawfun{1}, 'function_handle'), 'drawfun not a fun handle')
numDrawFuns = length(o.drawfun);

% 2 Style
FTSASSERT(isvector(o.style), 'styles should be a vector.');
numStyle = length(o.style);

% 3 string-type arguments
for vname = {'title', 'notes'}
    var = vname{1};
    if ~iscell(o.(var))
        o.(var) = {o.(var)};
    end
    
    [r,c] = size(o.(var));
    if r == 0 || c == 0
        o.(var{1}) = {''};
    elseif r == 1 && c > 1
        o.(var) = o.(var)';  % for compatibility
    end
    
    [r,c] = size(o.(var));
    if r == 1
        o.(var) = repmat(o.(var), numPlots, 1);
        r = numPlots;
    end
    FTSASSERT(r == numPlots && c == 1, [var ' must be a string or 1x1 or %dx2 cell array'], numPlots);
end

% 3.5 string-type argument for y-axes
for vname = {'ylabel', 'ycolor'}
    var = vname{1};
    if ~iscell(o.(var))
        o.(var) = {o.(var)};
    end
    
    [r,c] = size(o.(var));
    if r == 0 || c == 0
        o.(var) = {''};
%     elseif r == 1 && c > 1
%         o.(var) = o.(var)';  % for compatibility
    end
    
    [r,c] = size(o.(var));
    if c == 1
        o.(var) = [o.(var) o.(var)];
        c = 2;
    end
    if r == 1
        o.(var) = repmat(o.(var), numPlots, 1);
        r = numPlots;
    end
    FTSASSERT(r == numPlots && c == 2, [var ' must be a 1x1 cell or %dx2 cell array'], numPlots);
end

% 4 numeric-type arguments for y-axes
vname = {'ymin', 'ymax'};
hfun = {@nanmin, @nanmax};
for i = 1:length(hfun)
    var = vname{i};
    [r,c] = size(o.(var));
    if r == 0 || c == 0
        o.(var) = NaN(numPlots, 2);
    elseif r == 1 && c == 1
        o.(var) = repmat(o.(var), numPlots, 2);
    elseif r == 1 && c == numPlots
        o.(var) = [o.(var)' o.(var)'];
    elseif r == numPlots && c == 1
        o.(var) = [o.(var) o.(var)];
    else
        FTSASSERT(r == numPlots && c == 2, ['dimension of ''' var ''' mismatched with ''group''']);
    end
    for j = 1:size(o.(var),1)
        if isnan(o.(var)(j,1)) && any(o.group(j,:)>0)
            o.(var)(j,1) = hfun{i}(hfun{i}(series(:,o.group(j,:)>0))); % left axes
        end
        if isnan(o.(var)(j,2)) && any(o.group(j,:)<0)
            o.(var)(j,2) = hfun{i}(hfun{i}(series(:,o.group(j,:)<0))); % right axes
        end
    end
end

idx = o.ymax <= o.ymin;
o.ymin(idx) = o.ymin(idx) - 0.5;
o.ymax(idx) = o.ymax(idx) + 0.5;

% 5 cell-type argument: legend
if ~iscell(o.legend), o.legend = {o.legend}; end
if any(cellfun(@(x)~iscell(x), o.legend)), o.legend = {o.legend}; end
[r,c] = size(o.legend);
if r * c == 1 && numPlots > 1
    o.legend = repmat(o.legend, 1, numPlots);
elseif r > 1 && c > 1 || r == 1 && c ~= numPlots || c == 1 && r ~= numPlots
    error('legend must be a string or a vector cell of length 1 or %d.\n', numPlots);
end

if isempty(o.figure)
    h = figure;
    paperPos = [0, (29.7-min(8*o.layout(1),29.7))/2, 21, min(8*o.layout(1), 29.7)];
    set(gcf, 'PaperUnits', 'centimeters', ...
        'PaperType', 'A4', ...
        'PaperPosition', paperPos, ...
        'Units', 'centimeters');
    orient(o.orientation);
else
    h = o.figure;
    set(0, 'currentFigure', h);
end

s = 0; % start from 0 for mod()
d = 0;
for i = 1:numPlots
    ax(1) = subplot(o.layout(1), o.layout(2), o.range{i});
    set(ax(1), 'FontSize', o.fontsize);
    for j = 1:n
        hold on;
        if o.group(i,j)
            if o.group(i,j) < 0  % SELECT right AXES
                if length(ax) > 1
                    set(gcf, 'CurrentAxes', ax(2));
                else
                    ax(2) = axes('HandleVisibility',get(ax(1),'HandleVisibility') ...
                               , 'Units',           get(ax(1),'Units') ...
                               , 'Position',        get(ax(1),'Position') ...
                               , 'Parent',          get(ax(1),'Parent') ...
                               , 'Fontsize',        get(ax(1),'FontSize'));
                end
            end
            if iscell(o.style{s+1})
                o.drawfun{d+1}(x, series(:,j), o.style{s+1}{:});
            else
                o.drawfun{d+1}(x, series(:,j), o.style{s+1});
            end
            s = mod(s+1, numStyle);
            d = mod(d+1, numDrawFuns);
        end
    end
    
    if length(ax) > 1
        set(ax(2),'YAxisLocation','right','Color','none', ...
                  'XGrid','off','YGrid','off','Box','off', ...
                  'HitTest','off');
        ylabel(ax(2), o.ylabel(i,2));
        
        islog1 = strcmp(get(ax(1),'YScale'),'log');
        islog2 = strcmp(get(ax(2),'YScale'),'log');
        
        if islog1
            o.ymin(i,1) = log10(o.ymin(i,1));
            o.ymax(i,1) = log10(o.ymax(i,1));
        end
        if islog2
            o.ymin(i,2) = log10(o.ymin(i,2));
            o.ymax(i,2) = log10(o.ymax(i,2));
        end
        
        % Find bestscale that produces the same number of y-ticks for both
        % the left and the right.
        [low, high, ticks] = bestscale(o.ymin(i,1),o.ymax(i,1),o.ymin(i,2),o.ymax(i,2),islog1,islog2);
        if ~isempty(low)
            if islog1
                yticks1 = logsp(low(1),high(1),ticks(1));
                decade1 =  abs(floor(log10(yticks1)) - log10(yticks1));
                low(1) = 10.^low(1);
                high(1) = 10.^high(1);
            else
                yticks1 = linspace(low(1),high(1),ticks(1));
            end
            
            if islog2
                yticks2 = logsp(low(2),high(2),ticks(2));
                decade2 =  abs(floor(log10(yticks2)) - log10(yticks2));
                low(2) = 10.^low(2);
                high(2) = 10.^high(2);
            else
                yticks2 = linspace(low(2),high(2),ticks(2));
            end
            
            % Set ticks on both plots the same
            set(ax(1),'YLim',[low(1) high(1)],'YTick',yticks1);
            set(ax(2),'YLim',[low(2) high(2)],'YTick',yticks2);
            
            % Set tick labels if axis ticks aren't at decade boundaries
            % when in log mode
            if islog1 && any(decade1 > 0.1)
                ytickstr1 = cell(length(yticks1),1);
                for j=length(yticks1):-1:1
                    ytickstr1{j} = sprintf('%3g',yticks1(j));
                end
                set(ax(1),'YTickLabel',ytickstr1)
            end
            
            if islog2 && any(decade2 > 0.1)
                ytickstr2 = cell(length(yticks2),1);
                for j=length(yticks2):-1:1
                    ytickstr2{j} = sprintf('%3g',yticks2(j));
                end
                set(ax(2),'YTickLabel',ytickstr2)
            end
            
        else
            % Use the default automatic scales and turn off the box so we
            % don't get double tick marks on each side.  We'll still get
            % the grid from the left axes though (if it is on).
            set(ax,'Box','off')
        end
        if ~isempty(o.ycolor)
            set(ax(2),'YColor',o.ycolor{i,2});
        end
    else  % only left axis exists
        set(ax(1),'YLim',[o.ymin(i,1) o.ymax(i,1)]);
    end
    
    if ~isempty(o.ycolor)
        set(ax(1),'YColor',o.ycolor{i,1});
    end
    
   
    %% We give a label for every month in x axis
    labelStep = max(round(m/26*o.layout(2)),1);
    if length(o.range{i}) > 1 && all(diff(o.range{i})==1)
        labelStep = max(round((labelStep-1)./length(o.range{i})),1);
    end
    labeledIdxs = 1 : labelStep : m;
    if labeledIdxs(end) ~= m
        if m - labeledIdxs(end) < labelStep/2  % two x-lables too close, remove one
            labeledIdxs(end) = [];
        end
        labeledIdxs(end + 1) = m; %#ok<AGROW>
    end
    xticklabels = o.xticklabels(labeledIdxs,:);
    xticks  = x(labeledIdxs);
    
    title(o.title(i), 'FontSize', o.fontsize+1, 'FontWeight', 'bold');
    
    ylabel(ax(1), o.ylabel(i,1));
    
    xlim = x([1 m]);
    if o.xadjust
        adj = x(2)-x(1);
        xlim = [xlim(1)-adj xlim(2)+adj];
    end
    set(ax, 'XLim', xlim, 'XTick', xticks, 'XTickLabel', []);

    set(gcf, 'CurrentAxes', ax(1));
    yLim = get(ax(1), 'YLim');
    xLim = get(ax(1), 'XLim');
    
    % Draw x-axis labels
    y = (yLim(1)-(yLim(2)-yLim(1))*0.012) * ones(length(xticks), 1);
    text(xticks, y, xticklabels, 'Rotation', o.xtickLabelRotation, 'HorizontalAlignment', 'right', 'FontSize', o.fontsize-1);
    
    % Draw notes centered at the bottom of figure
    y = (yLim(1)-(yLim(2)-yLim(1))*0.18);
    text(xLim(1) + (xLim(2)-xLim(1))/2, y, o.notes{i}, 'HorizontalAlignment', 'center', 'FontSize', o.fontsize);

    % Mark insample and outsample edge
    for j = 1:length(o.vertlineposn)
        line([o.vertlineposn(j) o.vertlineposn(j)], [yLim(1), yLim(2)], 'Color','r','LineWidth',1);
    end
    for j = 1:length(o.hornlineposn)
        line([xLim(1), xLim(2)], [o.hornlineposn(j) o.hornlineposn(j)], 'Color','r','LineWidth',1);
    end
    
    box on;
    grid on;
    
    %% Drawing legend
    numLegend = length(o.legend);
    if (numLegend ~= 0 && ~isempty(o.legend{i}))
        if iscell(o.legend{i})
            legend(ax(1), o.legend{i}{:});
        else
            legend(ax(1), o.legend{i});
        end
    end
    
    ax = [];  % clear the mass
end
end


function [low,high,ticks] = bestscale(umin,umax,vmin,vmax,isulog,isvlog)
%BESTSCALE Returns parameters for "best" yy scale.

penalty = 0.02;

% Determine the good scales
[ulow,uhigh,uticks] = goodscales(umin,umax);
[vlow,vhigh,vticks] = goodscales(vmin,vmax);

% Find good scales where the number of ticks match
[u,v] = meshgrid(uticks,vticks);
[j,i] = find(u==v);

if isulog && isvlog
    % When both Y-axes are logspace, we try to match tickmarks with powers of 10
    for k=length(i):-1:1
        utest = logsp(ulow(i(k)),uhigh(i(k)),uticks(i(k)));
        vtest = logsp(vlow(j(k)),vhigh(j(k)),vticks(j(k)));
        upot = abs(log10(utest)-round(log10(utest))) <= 10*eps*log10(utest);
        vpot = abs(log10(vtest)-round(log10(vtest))) <= 10*eps*log10(vtest);
        if ~isequal(upot,vpot),
            i(k) = [];
            j(k) = [];
        end
    end
elseif isulog || isvlog
    % When one Y-axis is linspace and the other is logspace, the only
    % choices are the cases with just upper and lower tickmarks
    for k=length(i):-1:1
        if ~isequal(uticks(i(k)),2)
            i(k) = [];
            j(k) = [];
        end
    end
end

if ~isempty(i)
    udelta = umax-umin;
    vdelta = vmax-vmin;
    ufit = ((uhigh(i)-ulow(i)) - udelta)./(uhigh(i)-ulow(i));
    vfit = ((vhigh(j)-vlow(j)) - vdelta)./(vhigh(j)-vlow(j));
    
    fit = ufit + vfit + penalty*(max(uticks(i)-6,1)).^2;
    
    % Choose base fit
    k = find(fit == min(fit)); k=k(1);
    low = [ulow(i(k)) vlow(j(k))];
    high = [uhigh(i(k)) vhigh(j(k))];
    ticks = [uticks(i(k)) vticks(j(k))];
else
    % Return empty to signal calling routine that we weren't able to
    % find matching scales.
    low = [];
    high = [];
    ticks = [];
end

end

%------------------------------------------------------------
function [low,high,ticks] = goodscales(xmin,xmax)
%GOODSCALES Returns parameters for "good" scales.
%
% [LOW,HIGH,TICKS] = GOODSCALES(XMIN,XMAX) returns lower and upper
% axis limits (LOW and HIGH) that span the interval (XMIN,XMAX)
% with "nice" tick spacing.  The number of major axis ticks is
% also returned in TICKS.

BestDelta = [ .1 .2 .5 1 2 5 10 20 50 ];
%penalty = 0.02;

% Compute xmin, xmax if matrices passed.
if length(xmin) > 1, xmin = min(xmin(:)); end
if length(xmax) > 1, xmax = max(xmax(:)); end
if xmin==xmax, low=xmin; high=xmax+1; ticks = 1; return, end

% Compute fit error including penalty on too many ticks
Xdelta = xmax-xmin;
delta = 10.^(round(log10(Xdelta)-1))*BestDelta;
high = delta.*ceil(xmax./delta);
low = delta.*floor(xmin./delta);
ticks = round((high-low)./delta)+1;

end

%---------------------------------------------
function  y = logsp(low,high,n)
%LOGSP Generate nice ticks for log plots
%   LOGSP produces linear ramps between 10^k values.

y = linspace(low,high,n);

k = find(abs(y-round(y))<=10*eps*max(y));
dk = diff(k);
p = find(dk > 1);

y = 10.^y;

for i=1:length(p)
    r = linspace(0,1,dk(p(i))+1)*y(k(p(i)+1));
    y(k(p(i))+1:k(p(i)+1)-1) = r(2:end-1);
end
end
