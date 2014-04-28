function result = wgtmean(oldData,varargin)    
    
    if isa(oldData,'myfints'), oldData = fts2mat(oldData); end
    if size(oldData,1) == 1, oldData = oldData'; end    
    len = size(oldData,1);    
    
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
    result = fun(oldData(len-step+1:len,:).*repmat(weight(end-step+1:end,:),[1,size(oldData,2)])./sum(weight(end-step+1:end,:)));    
              
%     for i = 2:len
%         step = min(i,K);
%         newData(i,:) = fun(oldData(i-step+1:i,:).*repmat(weight(end-step+1:end,:),[1,size(oldData,2)])./sum(weight(end-step+1:end,:)));
%     end        
end