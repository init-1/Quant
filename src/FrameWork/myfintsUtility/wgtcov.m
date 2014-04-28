function covmat = wgtcov(oldData,varargin)    
    
    if isa(oldData,'myfints'), oldData = fts2mat(oldData); end        
    if size(oldData,1) == 1, oldData = oldData'; end    
    [len,Nfac] = size(oldData);    
    covmat = nan(Nfac);
    
    myoption.method = 'eq';
    myoption.ignoreNaN = 1;
    myoption.window = len;
    myoption.start = 0;
    myoption.end = 1;   

    myoption = Option.vararginOption(myoption,{'method','window','start','end','ignoreNaN'},varargin{:});

    window = myoption.window;
    ignoreNaN = myoption.ignoreNaN;
    method = myoption.method;    
    d1 = myoption.start;
    d2 = myoption.end;

    if isinf(window),  window = len; end

    if strcmpi(method,'lin')
        weight = linspace(d1,d2,window)';    
        K = min(window,len);
    elseif strcmpi(method,'exp')
        K = round(3.45*(window+1)); % the weight after K = 3.45*(N+1) can be ignored
        K = min(K, len);
        alpha = 2/(window+1);
        power = (K-1:-1:0)';
        weight = (1-alpha).^power;
    elseif strcmpi(method,'eq')
        weight = ones(window,1);        
        K = min(window,len);
    else
        error('Invalid weighting method.');
    end

    if ignoreNaN
        fun = @nansum;
    else
        fun = @sum;
    end           
    
    step = min(len,K);
    if len > 1        
        wtmean = fun(oldData(len-step+1:len,:).*repmat(weight(end-step+1:end,:),[1,size(oldData,2)])./sum(weight(end-step+1:end,:)));        
        wtmean = repmat(wtmean,len,1);        
        oldData = oldData - wtmean;    
        % denom = sum(weight)*(len-1)/len;
        denom = (sum(weight)^2 - sum(weight.^2))./sum(weight); % based on the wiki definition
        for i=1:Nfac
            for j = i:Nfac               
                X = oldData(len-step+1:len,i);
                Y = oldData(len-step+1:len,j);            
                if ignoreNaN
                    weight(isnan(X) | isnan(Y)) = 0;
                    denom = (sum(weight)^2 - sum(weight.^2))./sum(weight); % based on the wiki definition
                end
                covmat(i,j) = fun(weight.*X.*Y)./denom;
                covmat(j,i) = covmat(i,j);
            end
        end    
    end    
end