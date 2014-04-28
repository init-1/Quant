function fts = mat2fts(date, val, sid, fid)
% Syntax: fts = mat2fts(date, val, sid)
%      or
%         fts = mat2fts(date, val, sid, fid)
    date = datenum(date);
    if nargin < 4
        [val, date, sid] = vec2ary(val, date, sid);
        fid = 1;
    else
        [val, date, sid, fid] = vec2ary(val, date, sid, fid);
    end
    
    % Pack o into myfints objects
    numFactors = length(fid);
    fts = cell(numFactors, 1);
    for i = 1:numFactors
        if iscell(fid)  % cell of strings
            desc = fid{i};
        else  % must be numeric, ortherwise calling error
            desc = num2str(fid(i));
        end
        fts{i} = myfints(date, val(:,:,i), sid, [], desc);
    end
    
   % if nargin < 4, fts = fts{1}; end
end
