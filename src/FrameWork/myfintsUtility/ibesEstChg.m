function factorTS = ibesEstChg(fts1,fp1,fts2,fp2,nLag)
% calculate the n-month ibes estimate change (FY1/FQ1 estimate - FY1/FQ1 estimate with nLag), fp1 stands
% for financial period 1 (e.g. FQ1, FY1...), fp0 stands for financial
% period 0 (e.g. FQ0, FY0...)

FTSASSERT(isaligneddata(fts1,fp1,fts2,fp2),'At least one input myfints is not aligned with others');

lagfts1 = lagts(fts1,nLag,NaN);
lagfts2 = lagts(fts2,nLag,NaN);
lagfp2 = lagts(fp2,nLag,NaN);

lagfts1(fp1 == lagfp2) = lagfts2(fp1 == lagfp2);

factorTS = (fts1 - lagfts1)./((abs(fts1)+abs(lagfts1))/2);
factorTS = factorTS(nLag+1:end,:);
factorTS(isinf(fts2mat(factorTS))) = NaN;

return