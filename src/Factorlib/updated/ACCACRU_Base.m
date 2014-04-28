classdef ACCACRU_Base < FacBase
    %ACCACRU_Base Discretionary Component on Accrual Inventory/AP/AR
    %
    %  Formula:
    %    {Discretionary Component on Accruals} = ({Accruals} - {Expected Accruals}) / {Total Asset}
    %  where
    %    {Expected Accruals} = {Average}_{3 years}(Accruals)_{1 year lag} 
    %                        / {Average}_{3 years}(Total Revenues)_{1 year lag}
    %                        * {Total Revenues}_{current}
    %
    %  All balance sheet items are averaged on last four quarter values
    %
    %  Description:
    %    It studies components of accruals and decompose accruals into discretionary and 
    %    non-discretionary components to quantify management manipulation.  
    %    Discretionary component is defined to be the different on current and expected accruals
    %    level which is based upon trend and proportion to previous 5 years.  
    %    If current accruals is larger than expected accruals, management manipulation is likely. 
    %    The factor is based on: Earnings Quality and Stock Returns: The evidence from Accruals
    %    Konan Chan, Louis KC Chan, Narasimhan Jegadeesh and Josef Lakonishok, 
    %    NBER Working Paper January 2001
    %
    %    Note the original paper uses 5-year averages instead of 3 years here.
    %
    %  Copyright 2012 ING IM AP
    %  Dates: 10-Aug-2012 17:23:38
    
    methods (Access = protected)
        function factorTS = build(o, secIds, startDate, endDate, accrualId)
            asset   = o.loadItem(secIds, 'D000686130', startDate, endDate, 4);
            revenue = o.loadItem(secIds, 'D000686629', startDate, endDate, 16); % 4-year span
            accrual = o.loadItem(secIds, accrualId,    startDate, endDate, 20); % 5-year span
            
            accrual_ann = cell(1,4);
            revenue_ann = cell(1,4);
            for i = 1:length(accrual_ann)
                shift = (i-1)*4;
                accrual_ann{i} = ftsnanmean(accrual{1+shift:4+shift}) - ftsnanmean(accrual{5+shift:8+shift});
                revenue_ann{i} = ftsnanmean(revenue{1+shift:4+shift})*4;
            end
            accrual_expected = ftsnanmean(accrual_ann{2:4})...  % 1-year lagged 3-year average
                ./ ftsnanmean(revenue_ann{2:4})...  % 1-year lagged 3-year average
                .* revenue{1};    % current revenue
            factorTS = (accrual_ann{1} - accrual_expected) ./ ftsnanmean(asset{1:4});
        end
    end
end
