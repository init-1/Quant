% this function construct multi-period portfolios using linear programming

function portfolio = PFConstruction(bmhd, signal, fwdret, price, parameter, startpf, assetcons, attributecons)

%% Step 1 - Deal with input data
pickup = parameter.pickup;
maxto = parameter.maxto;
capital = parameter.capital;

% convert all myfints to matrix
fname = fieldnames(bmhd,1);
dates = bmhd.dates;

bmhd = fts2mat(bmhd);
signal = fts2mat(signal);
fwdret = fts2mat(fwdret);
price = fts2mat(price);
for j = 1:numel(assetcons)
    assetcons{j}.ub = fts2mat(assetcons{j}.ub);
    assetcons{j}.lb = fts2mat(assetcons{j}.lb);
end
for j = 1:numel(attributecons)
    attributecons{j}.A = fts2mat(attributecons{j}.A);
    if isa(attributecons{j}.b, 'myfints')
        attributecons{j}.b = fts2mat(attributecons{j}.b);
    end
end

if ~isempty(startpf)
    startpf = fts2mat(startpf);
else
    startpf = zeros(size(bmhd(1,:)));
end

%% Step 2 - construct portfolio here
inihd = zeros(size(bmhd)); %initial holding for each period
opthd = zeros(size(bmhd)); %optimized holding for each period
optshr = zeros(size(bmhd)); %optimized shares for each period
tradehd = zeros(size(bmhd)); %traded weight for each period
tradeshr = zeros(size(bmhd)); %traded shares for each period

[nperiod, ~] = size(bmhd);
pfvalue = zeros(nperiod,1);
pfret = zeros(nperiod,1);
pfvalue(1) = capital;

% calculate the upper and lower bound based on the asset level constraints
[weightcons, sharecons, actsharecons] = RefineAssetConstraint(assetcons);

% roundlot = 100; % asuume 100 shares is the common round lot size
roundlot = 1; 
inihd(1,:) = startpf;
for i = 1:nperiod
    inihd(i,isnan(inihd(i,:))) = 0;
    
    % construct single period constraints
    [tempub, templb, tempcons] = SinglePeriodCons(i, inihd, price, pfvalue, bmhd, weightcons, sharecons, actsharecons, attributecons);
        
    % check the consistency of upper bound and lower bound
    if ~isempty(tempub) && ~isempty(templb)
        if any(any(templb > tempub))
            count = sum(sum(templb > tempub));
            warning(['Inconsistent constraint: in period ', num2str(i), ' there are ',num2str(count)...
                ,' observations where lower bound is higher than upper bound. Such lower bound will be forced to equate upper bound']);
            templb(templb > tempub) = tempub(templb > tempub);
        end
    end
    
    if i == 1 % max turnover doesn't apply to first period
        maxto = 2; 
    else
        tempbmhd = bmhd(i-1:i,:);
        tempbmhd(isnan(tempbmhd)) = 0;
        bmto = nansum(abs(tempbmhd(2,:) - tempbmhd(1,:)),2); 
        if bmto > 2*maxto % if the benchmark turnover is too big, loose the maximum turnover constraint
            maxto = bmto + parameter.maxto; 
        else
            maxto = max(parameter.maxto);
        end
    end
    
    % call linear optimizer
    optweight = LinearOptimize(signal(i,:)', bmhd(i,:)', inihd(i,:)', pickup, maxto, templb', tempub', tempcons{:});
    
    % process optimal weight
    opthd(i,:) = optweight';
    tradehd(i,:) = opthd(i,:) - inihd(i,:);
    
    % convert the optimal weight to shares and round them
    optshr(i,:) = round(pfvalue(i)*opthd(i,:)./price(i,:)/roundlot)*roundlot;
    tradeshr(i,:) = round(pfvalue(i)*tradehd(i,:)./price(i,:)/roundlot)*roundlot;
%     optshr(i,:) = pfvalue(i)*opthd(i,:)./price(i,:);
%     tradeshr(i,:) = pfvalue(i)*tradehd(i,:)./price(i,:);
    pfvalue(i) = nansum(price(i,:).*optshr(i,:));
    opthd(i,:) = (price(i,:).*optshr(i,:))/pfvalue(i);
    
    % calcualte portfolio return
    pfret(i) = nansum(opthd(i,:).*fwdret(i,:));
%     tradesize = abs(opthd(i,:) - inihd(i,:))*pfvalue(i);
     
    if i < nperiod
        inihd(i+1,:) = opthd(i,:).*(1+fwdret(i,:))/nansum(opthd(i,:).*(1+fwdret(i,:)),2);    
        pfvalue(i+1) = pfvalue(i)*(1+pfret(i));
    end
    
    opthd(i,isnan(opthd(i,:))) = 0;
    optshr(i,isnan(optshr(i,:))) = 0;
end

opthd(isnan(opthd)) = 0;
inihd(isnan(inihd)) = 0;
optshr(isnan(optshr)) = 0;
tradeshr(isnan(tradeshr)) = 0;


%% Step 3 output result
portfolio.opthd = myfints(dates, opthd, fname);
portfolio.inihd = myfints(dates, inihd, fname);
portfolio.optshr = myfints(dates, optshr, fname);
portfolio.tradeshr = myfints(dates, tradeshr, fname);

return

