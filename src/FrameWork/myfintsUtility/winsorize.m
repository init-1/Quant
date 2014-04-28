% this function winsorize the myfints cross sectionally
% input: 
%     ifts - input myfints
%     leftqt - scalar, left quantile for winsorize 
%     rightqt - scalar, right quantile for winsorize
%     setnan - 1 or 0, if 1, set the winsorized records to be NaN, if 0 set
%     them to be the quantile value 


function ofts = winsorize(ifts, leftqt, rightqt, setnan)

if setnan == 1
    qt = nan(size(ifts,1),2);
else
    qt = quantile(fts2mat(ifts),[leftqt, rightqt],2);
end
rankperc = csRankPrc(ifts, 'ascend')/100;

ofts = ifts;
for i = 1:size(ofts,1)
    ofts(i,fts2mat(rankperc(i,:)) <= leftqt) = qt(i,1);
    ofts(i,fts2mat(rankperc(i,:)) >= rightqt) = qt(i,2);
end

return
