classdef RIM < FacBase
    %RIM <a full descriptive name placed here>
    %
    %  Formula:
    %
    %  Description:
    %
    %  Copyright 2012 ING IM AP
    %  Dates: 10-Aug-2012 19:16:11

    methods (Access = protected)
        function factorTS = build(o, secIds, ~, endDate)
            %talked to Bing Li... we fix the start date by hard code it
            % average of ROE will depend on the start date
            [factorTS,~,~] = o.rim_factTS(secIds, '1990-01-01', endDate, o.freq);
        end
        
        function [factorTS, priceDateStruct] = buildLive(o, secIds, endDate)
            %
            % live alpha is evaluated as:
            % (1) RIM alpha is based on th rich/cheap score from time series of last
            % 12m (not include the current month)
            % (2) the alpha is calculated as if the last month end price is replaced by
            % the live price
            % (3) this methdology for the live alpha is the cloest to the backtest
            % alpha
            %
            %
            
            %% Load data here (Loadxxx())
            sDate = datestr(addtodate(datenum(endDate),-3,'M'),'yyyy-mm-dd');
            closePrice = o.loadItem(secIds,'D001410415',sDate,endDate);
            date_mostRecent = datestr(max(closePrice.dates),'yyyy-mm-dd');
            live_price = closePrice(date_mostRecent);
            live_secids=fieldnames(live_price,1);
            live_price_data = fts2mat(live_price);
            
            
            % get all fair RIM values for the past 12 months
            % need to load data from 1990-01-01 (for ind median ROE required by the
            % model)
            
            % V0 is the fair valuation based on the RIM model
            % we use the common routine for backtesting
            [~,V0,rim_data] = o.rim_factTS(secIds, '1990-01-01', endDate, 'M');
            
            % for debug only
            %[alpha_backtest,V0,rim_data] = o.rim_factTS(secIds, '1990-01-01', endDate, 'M');
            
            % secids for the fair values
            secid_v0 = fieldnames(V0,1);
            V0_data = fts2mat(V0);
            % we only need the last 12 months
            V0_data = V0_data(end-12:end,:);
            
            adjClose = rim_data.adjClosePrice;
            adjClose = adjClose (end-12:end,:);
            
            % now get the V0 for the live trading stocks
            [~,idx_v0,idx_live] = intersect(secid_v0, live_secids);
            
            
            V0_data_last12m =V0_data(:,idx_v0);
            adjClose_last12m = adjClose(:,idx_v0);
            live_price_data = live_price_data(idx_live);
            
            V0_live = V0_data_last12m(end,:);
            
            a10_live = V0_live ./ live_price_data -1;
            % last 12m a10
            a10_12m = V0_data_last12m ./adjClose_last12m -1;
            
            % alpha is based on current price a10_12m =a10_12m(1:end-1,:);
            alpha = ( a10_live - nanmean(a10_12m,1) ) ./nanstd(a10_12m,0,1);
            alpha(isinf(alpha))=nan;
            
            factorTS = myfints(datenum(date_mostRecent),alpha,live_secids);
            
            % Set priceDateStruct appropriately
            priceDateStruct = LatestDataDate(closePrice);
            
            
            %    if nargout > 1
            %         priceDateStruct = LatestDataDate(closeprice);
            %    end
            
        end
        
        
        % each stock's ROE fades to industry median
        %
        % median ROE for each industry
        % this is required for Terminal value estimation
        %
        function ind_ROE_median = ind_ROE_mean(rim_data) %misleading name
            
            % average of ROE across time...anchored at the start
            %avg_ROE = ftsmovfun(rim_data.ROE,inf,@nanmedian);
            
            gg = rim_data.GICS;
            gg = myfints(gg.dates, floor(fts2mat(gg./1000000)), fieldnames(gg,1));
            % now we need to do cross-sectional mean for each ind sector
            
            % thnaks for Louis for this function
            %ind_ROE_avg=csgroupfun(@nanmean,avg_ROE,gg);
            
            ind_ROE_median = csgroupfun_x(@nanmedian, rim_data.ROE, gg);
            
        end
        
        function [rim_data,rim_data_backfilled_aligned] = load_RIM_data(secIds, startDateIn, endDate, targetFreq)
            
            % get more data than needed  -- in case we need to backfill
            startDate = datestr(addtodate(datenum(startDateIn), -15, 'M'), 'yyyy-mm-dd');
            
            startDateWS = datestr(addtodate(datenum(startDate), -12, 'M'), 'yyyy-mm-dd');
            
            % for adjClose
            itemId='D001410415';
            adjClosePrice = o.loadItem(secIds,itemId,startDate,endDate);
            rim_data.adjClosePrice= adjClosePrice;
            
            
            % for IBES FY1 earnins estimate - target date
            % add return on equity
            itemId='D000111154';
            ROE=o.loadItem(secIds,itemId,startDateWS,endDate);
            ROE = o.lagfts(ROE, '4M', NaN); % lag 4 months if it is a worldscope data
            rim_data.ROE=ROE;
            
            % for IBES FY1 earnins estimate - target date
            itemId='D000415183';
            FY1_targetDate = o.loadItem(secIds,itemId,startDate,endDate);
            rim_data.FY1_targetDate =FY1_targetDate;
            
            % for IBES FY1 earnins estimate - target value
            itemId='D000435594';
            FY1_targetValue = o.loadItem(secIds,itemId,startDate,endDate);
            rim_data.FY1_targetValue = FY1_targetValue;
            
            
            % for IBES FY2 earnins estimate - target date
            itemId='D000415184';
            FY2_targetDate = o.loadItem(secIds,itemId,startDate,endDate);
            rim_data.FY2_targetDate = FY2_targetDate;
            
            % for IBES FY2 earnins estimate - target value
            itemId='D000435595';
            FY2_targetValue =  o.loadItem(secIds,itemId,startDate,endDate);
            rim_data.FY2_targetValue = FY2_targetValue;
            
            
            % for IBES FY3 earnins estimate - target date
            itemId='D000415185';
            FY3_targetDate = o.loadItem(secIds,itemId,startDate,endDate);
            % for IBES FY3 earnins estimate - target value
            itemId='D000435596';
            FY3_targetValue = o.loadItem(secIds,itemId,startDate,endDate);
            rim_data.FY3_targetDate = FY3_targetDate;
            rim_data.FY3_targetValue = FY3_targetValue;
            
            % for IBES FY0 tadate -- fiescal year end
            itemId='D000415185';
            FY0_targetDate = o.loadItem(secIds,itemId,startDate,endDate);
            rim_data.FY0_targetDate = FY0_targetDate;
            
            %LTG
            itemId='D000435589';
            LTG = o.loadItem(secIds,itemId,startDate,endDate);
            rim_data.LTG = LTG;
            
            
            %bookvalue per share
            itemId='D000110113';
            bookValue = o.loadItem(secIds,itemId,startDateWS,endDate);
            bookValue = o.lagfts(bookValue, '4M', NaN); % lag 4 months if it is a worldscope data
            rim_data.bookValue = bookValue;
            
            
            %dividend
            itemId='D000110146';
            last_dividend = o.loadItem(secIds,itemId,startDateWS,endDate);
            last_dividend  = o.lagfts(last_dividend, '4M', NaN); % lag 4 months if it is a worldscope data
            rim_data.last_dividend = last_dividend;
            
            %dividend pay out ratio
            %itemId='D000110442'
            
            % earnings per share
            itemId='D000110193';
            last_earnings = o.loadItem(secIds,itemId,startDateWS,endDate);
            last_earnings  = o.lagfts(last_earnings, '4M', NaN); % lag 4 months if it is a worldscope data
            rim_data.last_earnings = last_earnings;
            
            %total assets
            itemId='D000111193';
            total_assets = o.loadItem(secIds,itemId,startDateWS,endDate);
            total_assets  = o.lagfts(total_assets, '4M', NaN); % lag 4 months if it is a worldscope data
            rim_data.total_assets = total_assets;
            
            % number of outstanding shares
            %itemId='D000112644';
            itemId='D000110115';
            outstanding_shares = o.loadItem(secIds,itemId,startDateWS,endDate);
            outstanding_shares  = o.lagfts(outstanding_shares, '4M', NaN); % lag 4 months if it is a worldscope data
            rim_data.outstanding_shares = outstanding_shares;
            
            %
            
            %itemId='160100';
            %HOLT_Re = LoadQSSecTS(secIds,itemId,0,startDate,endDate,targetFreq);
            
            itemId='D002400100';
            HOLT_Re = o.loadItem(secIds,itemId,startDate,endDate);
            rim_data.HOLT_Re = HOLT_Re;
            
            
            itemId='913';
            GICS = LoadQSSecTS(secIds,itemId,0,startDate,endDate,targetFreq);
            rim_data.GICS = GICS;
            
            
            % align the data first -- monthly
            % then we back fill the nans
            % Genereate the date series
            alignDates = o.genDates(startDateIn, endDate, o.targetFreq);    % 'Busday', 0);
            
            % trick to aling all the fields in the data structure
            fnmames = fieldnames(rim_data);
            tmp_cell =  struct2cell(rim_data);
            aa_out=tmp_cell;
            [aa_out{:}] = aligndata(tmp_cell{:},alignDates,'union'); %keep all the fields
            % create a structure with aligned data
            rim_data_aligned = [];
            for i=1:numel(fnmames )
                rim_data_aligned .( fnmames{i} ) = aa_out{i};
            end
            
            %backfiell all the data -- get the most recent data
            rim_data_backfilled_aligned= backfill_all_fileds(rim_data_aligned);
        end
        
        function rim_fairvalue  = rim_alpha( rim_data_in )
            
            rim_data = rim_data_in;
            
            rim_data.ROE = convert_to_decimal(rim_data.ROE);
            
            
            
            all_dates = rim_data.ROE.dates;
            [~,r]=size(fts2mat(rim_data.ROE));
            % time series of today
            today_ = repmat(all_dates,[1,r]);
            rim_data.today_ = today_;
            
            rim_data.LTG = convert_to_decimal(rim_data.LTG);
            rim_data.HOLT_Re = convert_to_decimal(rim_data.HOLT_Re);
            rim_data.ind_ROE_avg =  convert_to_decimal(rim_data.ind_ROE_avg);
            
            % interpolation FEPS
            [FEPS1,FEPS2,FEPS3] = interpolation_eps (rim_data);
            rim_data.FEPS_1 = FEPS1;
            rim_data.FEPS_2 = FEPS2;
            rim_data.FEPS_3 = FEPS3;
            
            
            % per share
            rim_data.lastYear_earning = rim_data.last_earnings;
            rim_data.lastYear_divPaid = rim_data.last_dividend;
            rim_data.totalAsset = rim_data.total_assets  ./ rim_data.outstanding_shares;
            rim_data.B_0   = rim_data.bookValue;
            rim_data.FROE_T = rim_data.ind_ROE_avg ;
            
            Re = rim_data.HOLT_Re;
            rim_fairvalue = rim_myfints(rim_data,Re);
            
        end
        
        function [factorTS,fairValue,rim_data] = rim_factTS(secIds, startDate, endDate, targetFreq)
            
            %startDate='1990-01-01'; %talked to Bing Li... we fix the start date by hard code it
            % average of ROE will depend on the start date
            
            
            assert(isequal(targetFreq,'M') || isequal(targetFreq,'m'),'must use monthly targetFreq --RIM model is based on monthly data');
            
            
            % if( exist('rim_data_backfilled_aligned_1990.mat','file'))
            %     load rim_data_backfilled_aligned_1990;
            % else
            %load all the data and align
            % back_fill (get the most recent data available)
            [~,rim_data_backfilled_aligned] = o.load_RIM_data(secIds, startDate, endDate, targetFreq);
            %  save rim_data_backfilled_aligned_1990 rim_data_backfilled_aligned;
            % end
            
            
            %data_from_getLastItem= check_load_data_withGetLast( rim_data_backfilled_aligned );
            
            ind_ROE_median = o.ind_ROE_mean(rim_data_backfilled_aligned); % we might save this in a mat file.. later on
            %save ind_ROE_avg_1990 ind_ROE_avg
            
            rim_data = rim_data_backfilled_aligned;
            rim_data.T = 12;  % a parameter for number of periods (months) fade to ind avg ROE
            rim_data.ind_ROE_avg = ind_ROE_median;
            
            rim_fairvalue = o.rim_alpha( rim_data );
            
            a10 = rim_fairvalue ./ rim_data.adjClosePrice -1.0;
            % divergence
            a11 = ftsmovzscore(a10, 13);
            
            % set inf to nan
            tmp_ =fts2mat(a11);
            tmp_(isinf(tmp_)) = nan;
            a11 = myfints(a11.dates, tmp_, fieldnames(a11,1) );
            
            % the first 5 years of data not to be used% (because of ind_ROE_median need to be estimated)
            start_alpha_date = datestr(addtodate(datenum(startDate), 5, 'Y'), 'yyyy-mm-dd');
            str_sel = [start_alpha_date '::' datestr(endDate,'yyyy-mm-dd')];
            a11 = a11(str_sel) ;
            factorTS = a11 ;
            
            fairValue = rim_fairvalue(str_sel);
            % for test only
            %iret = write_facTS_to_csv( factorTS,'RIM_a11.csv' );
            %save RIM_a11 a11;
        end
    end
end
% courtesy of Peter's trick
% 12 month correction... but the avg does not include today
function fts = ftsmovzscore(fts, window)
fts = ftsmovfun(fts, window, @fun);
    function a = fun(a, ~)
        if size(a,1) > 1
            a = (a(end,:) - nanmean(a(1:end-1,:)) ) ./ nanstd( a(1:end-1,:) );
        end
    end
end
%
% industrucy sector median -- expanding window per sector
%
function ofts = csgroupfun_x(fun, ifts, group)
% FUNCTION: csgroupfun(fun, fts, group)
% DESCRIPTION: apply an crosssectional aggregate function to a myfints object according to
% certain grouping rule, and output the aggregated value in a myfints
% object.
%
% INPUTS:
%   fun     - a function handle specifying the type of functions to apply
%	ifts    - myfints object to which the group function is applied.
%	group	- myfints object which contains the group information, must
%	have the same dates and fields as ifts
%
% OUTPUT:
%	ofts    - the output myfints which has the same dates and fields as
%	ifts, but value replaced by the calculated group mean
%
% Author: louis Luo
% Last Revision Date: 2011-05-02
% Vertified by:
%
FTSASSERT(isa(fun,'function_handle'),'input fun has to be a function handle');
FTSASSERT(isaligneddata(ifts, group),'input myfints are not aligned');
groupData = fts2mat(group);
iftsData = fts2mat(ifts);
[r, c] = size(iftsData);
oftsData = nan(r,c);
for i = 1:r
    uniGroup = unique(groupData(i,~isnan(groupData(i,:))));
    nGroup = numel(uniGroup);
    %fprintf('i=%d\n',i);
    for j = 1:nGroup
        oftsData(i,groupData(i,:) == uniGroup(j)) = fun(iftsData(groupData(1:i,:) == uniGroup(j)));
    end
end
%ofts = ftsreturn(ifts,oftsData,fieldnames(ifts,1),ifts.fints.dates);
ofts = myfints(ifts.dates, oftsData, fieldnames(ifts,1) );
end
%#####################################
% back fill all the fileds
function rim_data_backfilled = backfill_all_fileds(rim_data_in)
fnmames = fieldnames(rim_data_in);
rim_data_backfilled =[];
for i=1:numel(fnmames)
    rim_data_backfilled.(fnmames{i}) = backfill(rim_data_in.(fnmames{i}),Inf,'entry');
end
end
%============
% code re-written from legacy code
%============
% interpolation FEPS
%
function [FEPS1,FEPS2,FEPS3] = interpolation_eps (rim_data)
today_ = rim_data.today_;
data_raw = rim_data;
target_day_1 = data_raw.FY1_targetDate;
target_day_2 = data_raw.FY2_targetDate;
target_day_3 = data_raw.FY3_targetDate;
f1=data_raw.FY1_targetValue;
f2=data_raw.FY2_targetValue;
f3=data_raw.FY3_targetValue;
%long term growth rate
Ltg =data_raw.LTG;
tmp_ = nanmedian(Ltg) ;
tmp1_ = nanmedian(tmp_);
assert( isscalar(tmp1_));
if(tmp1_ >1.0)
    Ltg= Ltg/100.0;
end
%make sure f3 has value, if nan replace it with f2*(1+Ltg);
%idx_f3_tmp = isnan(f3);
idx_f3_tmp = isnan(fts2mat(f3));
f3(idx_f3_tmp) =  f2(idx_f3_tmp) .*(1.0 + Ltg(idx_f3_tmp));
FEPS1 = data_raw.FY1_targetValue *nan;
FEPS2 = FEPS1;
FEPS3 = FEPS1;
% fill up the FEPS1,2,3 with avaliable data
% remember, (nan>1) is 0 and (nan<=1) is also 0
% this is the case where first year target date is ahead of today
% idx = today < target_day_1 & ( (target_day_2-today)>365 );
idx = bsxfun(@and, today_ < target_day_1, (target_day_2-today_)>365);
t1 = today_ + 365;
t2=  t1+365;
t3=  t2+365;
%t4=  t3+365;
idx=fts2mat(idx);
%linear interpolation to estimate forward one,two three years forward EPS
FEPS1(idx) = f1(idx) + (t1(idx)-target_day_1(idx)) ./(365) .*(f2(idx)-f1(idx));
FEPS2(idx) = f2(idx) + (t2(idx)-target_day_2(idx)) ./(365) .*(f3(idx)-f2(idx));
dT = t3 -  target_day_3;
FEPS3(idx) = f3(idx) .* (1+ Ltg(idx) .* (dT(idx)/365));
clear idx; % make sure code below this line no longer use variable idx
% in the case where
idxc =  (today_ >= target_day_1);
idxc=fts2mat(idxc);
% t1,t2 t3 t4 etc are still the same
% but f1 can no longer be used (it has past .. and next year not released
% yet)
f4 =f3 .*(1+Ltg);
FEPS1(idxc) = f2(idxc) + (t1(idxc)-target_day_2(idxc)) ./(365) .*(f3(idxc)-f2(idxc));
FEPS2(idxc) = f3(idxc) + (t2(idxc)-target_day_3(idxc)) ./(365) .*(f4(idxc)-f3(idxc));
FEPS3(idxc) =  FEPS2(idxc) .*( 1.0 + Ltg(idxc) );
end
%===========================
% modified from legacy code
%===========================
% write RIM value as function of Re explicitly
% scalar version for each stock
% we will need matlab function fzero to backout Re (cost of equity)
%
function v0 = rim_myfints(rim_data,Re)
Sin = rim_data;
TV = TV_rim_myfints(Sin,Re );
divPayout = divPayOut_rim_myfints(Sin );
B_0 = Sin.B_0; % book value t=0
B_1 = B_0 + Sin.FEPS_1 .*(1.0- divPayout); % book value t=1;
FROE_1 = Sin.FEPS_1 ./ B_0 ; % forcasted ROE for the first year
FROE_2 = Sin.FEPS_2 ./ B_1 ; % forcasted ROE for the second year
v0 = B_0 + ( FROE_1 -Re) ./ (1+Re) .* B_0 + ( FROE_2 -Re) ./ (1+Re) .^2  .* B_1 ...
    + TV;
end
% for RIM models, all the input is a structure
% with a vec of secid, and vecs of numericla values
% and also the date (month end)% the output is the input + calculated values
% and iStat is error code ( 0 means all OK)
% this version of Terminal Value is coded follow the paper
% by Lee and Swaminathan (1999,AIMR,p4)
%
function TV = TV_rim_myfints(Sin,Re )
divPayout = divPayOut_rim_myfints(Sin );
B_0 = Sin.B_0; % book value t=0
B_1 = B_0 + Sin.FEPS_1 *(1.0- divPayout); % book value t=1;
B_2 = B_1 + Sin.FEPS_2 .*(1.0- divPayout); % book value t=2;
T=Sin.T;
assert(T >=3);
FEPS_3 = Sin.FEPS_2 *(1+Sin.LTG);
FROE_3 = FEPS_3 /B_2;
% T=3 is special, no need for terminal value for ROE
if(T == 3)
    TV =  ( FROE_3 -Re) / ( Re * (1+Re)^2) *B_2;
    return;
end
% by this line T>3
% we will need FROE_T (estimated terminal value of ROE)
Book_im1 = B_2;
TV = 0;
% beyond year 3
% FEPS is estimated from FROE
% and FROE is modeled to fade to FROE_T (see the paper for details)
for i=3:T-1
    FROE_i = FROE_3 +(i-3)/(T-3) *(Sin.FROE_T - FROE_3); % faded value of ROE
    TV = TV + (FROE_i - Re)/( (1+Re) .^ i)  .* Book_im1; % discounted RIM from year 3 to T-1.
    Book_im1 = Book_im1 + (FROE_i .* Book_im1) .*(1.0- divPayout);   % this is the updated book value based on 'clean surplus' accounting
end
% add the term from period T to infinity
TV = TV + ( Sin.FROE_T -Re) ./ ( Re .* (1+Re) .^ (T-1)) .* Book_im1;
end
%=================
% for RIM models, all the input is a structurr
% with a vec of secid, and vecs of numericla values
% and also the date (month end)% the output is the input + calculated values
% and iStat is error code ( 0 means all OK)
% this version of payout raios is coded follow the paper
% by Lee and Swaminathan (1999,AIMR,p4)
%
function divPayout = divPayOut_rim_myfints(Sin )
divPayout = Sin.lastYear_divPaid ./ Sin.lastYear_earning;
% if earning is negative, divdends by 0.06*TotalAsset
idx= fts2mat(Sin.lastYear_earning) < 0;  % for stocks with negative earnings
divPayout(idx) = Sin.lastYear_divPaid(idx) ./ (0.06*Sin.totalAsset(idx));
% sanity check
% assert (  nanmedian(nanmedian(fts2mat(divPayout))) <=1);
%assert (  nanmedian(nanmedian(fts2mat(divPayout))) >=0);
divPayout(divPayout <= 0) =0;
divPayout(divPayout>=1.0)  =1.0;
end
% convert to percentage to decimal
function to_decimal = convert_to_decimal(fts_in)
to_decimal =fts_in;
tmp_ = nanmedian(fts_in) ;
tmp1_ = nanmedian(tmp_);
assert( isscalar(tmp1_));
if(tmp1_ >1.0)
    to_decimal = to_decimal /100.0;
end
end
