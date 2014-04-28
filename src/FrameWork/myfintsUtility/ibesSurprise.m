function surprise = ibesSurprise(act,fp0,est,fp1)
% calculate the earnings surprise (reported EPS - expected EPS), fp1 stands
% for financial period 1 (e.g. FQ1, FY1...), fp0 stands for financial
% period 0 (e.g. FQ0, FY0...)

FTSASSERT(isaligneddata(act,fp0,est,fp1),'At least one input myfints is not aligned with others');

dates = act.dates;
actData = fts2mat(act);
fp0Data = fts2mat(fp0);
estData = fts2mat(est);
fp1Data = fts2mat(fp1);

[r,c] = size(actData);

resData = nan(r,c);

% for each entry in act: find the latest observation in act where fq1 = fq0, and
% fp1.dates < fp0.dates
for j = 1:c
    for i = 1:r
        idx = find((fp1Data(:,j) == fp0Data(i,j) & dates < dates(i)),1,'last');
        if ~isempty(idx)
            resData(i,j) = actData(i,j) - estData(idx,j);
        end
    end
end

surprise = myfints(dates, resData, fieldnames(act,1), act.freq);

return