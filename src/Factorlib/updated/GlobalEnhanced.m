classdef GlobalEnhanced < FacBase
    properties (Constant)
        epsilon = 1e-12;
    end
    
    methods (Access = protected, Static)
        function fts = estGrowth(fts, step, hop)
        % hop indicates how many periods involved in estimation of growth rate
        % step indicates how many time points consist of a period (like 12 for year)
            if iscell(fts) && nargin == 1
                fts = multiftsfun(fts{:}, @est_3D);
            else
                win = step*(hop-1)+1;
                fts = ftsmovfun(fts, win, @(x)est(x,win,step));
            end
            
            function gth = est_3D(e3d)
                [T,N,K] = size(e3d);
                gth = NaN(T,N);
                for t = 1:T
                    e = reshape(e3d(t,:,:),N,K)';
                    gth(t,:) = est(e,K,1);  % win=K,step=1
                end
            end
            
            function gth = est(e,win,step)
                [T,N] = size(e);
                gth = NaN(1,N);
                
                if T < win, return; end
                FTSASSERT(win == T);
                
                e = e(1:step:end,:);
                T = size(e,1);
                nTPos = sum(e > 0, 1);
                e1 = e;
                e1(e1 < 0 | isnan(e1)) = 0;
                posAvg = sum(e1,1) ./ nTPos;
                T_ = (0:T-1)';
                egth = NaN(1,N);
                lgth = NaN(1,N);
                for i = 1:N
                    if nTPos(i) < 2, continue; end
                    e1 = e(:,i);
                    idx = e1 > 0;
                    t1 = T_(idx);
                    gth = regress(log(e1(idx)), [ones(size(t1)) t1]);
                    egth(i) = gth(2,1);

                    idx = ~isnan(e1);
                    if sum(idx) < 2, continue; end
                    t1 = T_(idx);
                    gth = regress(e1(idx), [ones(size(t1)) t1]);
                    lgth(i) = gth(2,1)./posAvg(i);
                end
                
                idx = (nTPos == T);
                lgth(idx) = 1/3*lgth(idx) + 2/3*egth(idx);
                
                idx = (egth == 0 | abs(lgth) < abs(egth) | lgth.*egth < 0);
                egth(idx) = lgth(idx);
                
                gth = 0.5*egth + 0.5*lgth;
                gth(gth < -1.01) = -1.01;
                gth(gth > 2.01)  = 2.01;
            end  % of embeded est() function
        end % if estGrowth()
        
        function fts = RIG(fts, gics)
            fts = neutralize(fts, gics, @(x)bsxfun(@minus,x,nanmedian(x,2)), 2);
        end
        
        function fts = retrofun(ftscell, fun)
            fts = fun(ftscell{end-1}, ftscell{end});
            if length(ftscell) > 2
                fts_ = fun(ftscell{end-2}, ftscell{end});
                idx = abs(fts) < GlobalEnhanced.epsilon;
                fts(idx) = fts_(idx);
            end
        end
        
        function fts = diff_(ftscell)  % differentiate it from xts.diff
            fts = GlobalEnhanced.retrofun(ftscell, @(x_prev,x)x-x_prev);
        end
        
        function fts = momentum_TL(ftscell)
            fts = GlobalEnhanced.retrofun(ftscell, @(x_prev,x)(x-x_prev)./max(abs(fts2mat(x)),abs(fts2mat(x_prev))));
        end
        
        function fts = momentum_TR(ftscell)
            fts = GlobalEnhanced.retrofun(ftscell, @(x_prev,x)(x-x_prev)./x_prev);
        end
        
        function FWD12 = IBES_FWD12(FY1Date, FY2Date, FY3Date, FY1Value, FY2Value, FY3Value)
            FWD12 = FY1Value;
            FWD12(:,:) = NaN;
            if isempty(FY1Date) || isempty(FY2Date) || isempty(FY3Date) ...
               || isempty(FY1Value) || isempty(FY2Value) || isempty(FY3Value)
                return;
            end
            
            MonthToFY1 = GlobalEnhanced.dateMonDiff(FY1Date);
            MonthToFY2 = GlobalEnhanced.dateMonDiff(FY2Date);
            
            Idx = MonthToFY1 >= 0;
            FWD12(Idx) = FY1Value(Idx).*MonthToFY1(Idx)./12 + FY2Value(Idx).*(12 - MonthToFY1(Idx))./12;
            FWD12(~Idx) = FY2Value(~Idx).*MonthToFY2(~Idx)./12 + FY3Value(~Idx).*(12 - MonthToFY2(~Idx))./12;
        end
        
        function TRAIL12 = IBES_TRAIL12(FY0Date, FY0Value, FY1Value)
            TRAIL12 = FY1Value;
            MonthToFY0 = abs(GlobalEnhanced.dateMonDiff(FY0Date));
            Idx = MonthToFY0 >= 0 & MonthToFY0 <= 12;
            TRAIL12(Idx) = FY1Value(Idx).*MonthToFY0(Idx)./12 + FY0Value(Idx).*(12 - MonthToFY0(Idx))./12;
        end
        
        function momentum = IBES_momentum(FY0, FY1, ~, FY0Value, FY1Value, FY2Value, Months)
        %  This function calcualtes IBES actual/estimate momentum during a centain number of months
        %  Inputs:
        %      1. FY0 (The target date corresponds to the FY0 reported value)
        %      2. FY1 (The target date corresponds to the FY1 forecast)
        %      3. FY2 (The target date corresponds to the FY2 forecast)
        %      4. FY0Value (The FY0 reported value)
        %      5. FY1Value (The FY1 forecast)
        %      6. FY2Value (The FY2 forecast)
        %      7. Months (The number of month to measure the momentum)
        %  Outputs:
        %	   momentum (The calculated momentum value)
            lagFY0Value = lagts(FY0Value, Months);
            lagFY1Value = lagts(FY1Value, Months);
            lagFY2Value = lagts(FY2Value, Months);
            FY0Value(1:Months,:) = [];
            FY1Value(1:Months,:) = [];
            FY2Value(1:Months,:) = [];
            lagFY0Value(1:Months,:) = [];
            lagFY1Value(1:Months,:) = [];
            lagFY2Value(1:Months,:) = [];
            yFY0 = year(fts2mat(FY0));
            yFY1 = year(fts2mat(FY1));

            momentum = FY1Value - lagFY2Value;
            
            idx = yFY1(Months+1:end,:) == yFY1(1:end-Months,:);
            m = FY1Value - lagFY1Value;
            momentum(idx) = m(idx);
            
            idx = yFY0(Months+1:end,:) ~= yFY0(Months:end-1,:);
            m = FY0Value - lagFY1Value;
            momentum(idx) = m(idx);
            
            idx1 = ftsmovfun(FY1Value, Months+15, @(x)all(isnan(x),1));
            idx2 = ftsmovfun(FY2Value, Months+15, @(x)all(isnan(x),1));
            idx = fts2mat(idx1) & fts2mat(idx2);
            m = FY0Value - lagFY0Value;
            momentum(idx) = m(idx);
            
%             if all(isnan(FY1Value)) && all(isnan(FY2Value))
%                 momentum = FY0Value(end) - FY0Value(max(1,end-Months));
%             else    
%                 if year(FY0(end)) ~= year(FY0(max(1,end-1)))
%                     momentum = FY0Value(end) - FY1Value(max(1,end-Months));
%                 elseif year(FY1(end)) == year(FY1(max(1,end-Months)))
%                     momentum = FY1Value(end) - FY1Value(max(1,end-Months));
%                 elseif year(FY1(end)) ~= year(FY1(max(1,end-Months)))
%                     momentum = FY1Value(end) - FY2Value(max(1,end-Months));
%                 end
%             end
        end
        
        function surprise = IBES_Surprise(FY0Value, FY1Value, step)
            %  myfints version of this function calculates the IBES actual/estimate surprise
            %
            %  Inputs:
            %      1. TSDate (Standard monthly date time series)
            %      2. FY0DataDate (The release date corresponds to the FY0 reported value)
            %      3. FY1DataDate (The release date corresponds to the FY1 forecast)
            %      4. FY0 (The target date of the FY0 reported value)
            %      5. FY1 (The target date of the FY1 forecast)
            %      6. FY0Value (The FY0 reported value)
            %	   7. FY1Value (The FY1 forecast)
            %	   8. Months (number of months to measure the surprise
            %
            %  Outputs:
            %	   surprise: the calculated IBES surprise
            surprise = biftsfun(FY0Value, FY1Value, @fun);
             
            function surprise = fun(FY0V, FY1V)
                surprise = NaN(size(FY0V));
                [r,c] = size(FY0Value);
                for j = 1:c
                    for i = 1:r
                % for each entry in act: find the oldest observation in act where fy0value = current fy0value
                        fy0idx = find(FY0V(1:i,j) == FY0V(i,j),1,'first');
                % count back Months to find the fy1 forecast 
                        fy1idx = fy0idx - step;
                        if fy1idx > 0
                            surprise(i,j) = FY0V(fy0idx,j) - FY1V(fy1idx,j);
                        end
                    end
                end
            end
        end

        function d = dateMonDiff(datefts)
        % Note that the returned is NOT a myfints though input is.
            d = fts2mat(datefts);
            d = 12*bsxfun(@minus,year(d),year(datefts.dates)) ...
                 + bsxfun(@minus,month(d),month(datefts.dates));
        end
        
        function r = eynorm(E1,E2,E3,LTG,BY)
        % E1, E2 and E3 are the FY1, FY2, FY3 forecast estimates
        % LTG is the long term growth estimate
        % BY is the discount rate based on the country
        % P is the price
            FTSASSERT(isaligneddata(E1,E2,E3,LTG,BY));
            r = E1;
            LTG_est = fts2mat(GlobalEnhanced.estGrowth({E1 E2 E3}));
            LTG = fts2mat(LTG);
            idx = isnan(LTG);
            LTG(idx) = LTG_est(idx);
            LTG(LTG<-0.5) = -0.5;
            LTG(LTG> 1.0)  = 1.0;
            
            E1 = fts2mat(E1);
            E1(E1<-0.25) = -0.25;
            E1(E1> 0.25) =  0.25;

            E2 = fts2mat(E2);
            E2(E2<-0.3) = -0.3;
            E2(E2> 0.3) =  0.3;

            E3 = fts2mat(E3);
            E3(E3<-0.35) = -0.35;
            E3(E3>0.35)  =  0.35;

            idx = isnan(E2);
            E2(idx) = E1(idx) .* (1+LTG(idx));

            idx = isnan(E3);
            E3(idx) = E2(idx) .* (1+LTG(idx));

            BY = fts2mat(BY);
            df = bsxfun(@power, 1./(1+BY), reshape(1:50,1,1,50));
            cf = NaN([size(E1) 50]);

            cf(:,:,1) = E1;
            cf(:,:,2) = E2;
            cf(:,:,3) = E3;

            for p = 4:8;
                cf(:,:,p) = cf(:,:,3) .* (1+LTG).^(p-3);
            end;

            for p = 9:13;
                cf(:,:,p) = cf(:,:,8) .* (1+0.5*(LTG+BY)).^(p-8);
            end;

            for p = 14:50;
                cf(:,:,p) = cf(:,:,13) .* (1+BY).^(p-13);
            end;

            dcf = bsxfun(@times, cf, df); %reshape(df, size(df),1,50));

            dcf_sum = cumsum(dcf, 3);
            idx = find(dcf_sum > 1);
            [idx1,idx2,idx3] = ind2sub(size(dcf_sum),idx);

            r1 = NaN(size(E1));
            for i = 1:length(idx3)
                if isnan(r1(idx1(i),idx2(i)))
                    dcf_1 = idx3(i);
                    r1(idx1(i),idx2(i)) = dcf_1-1 + ...
                        (1-dcf_sum(idx1(i),idx2(i),dcf_1-1)) / (dcf_sum(idx1(i),idx2(i),dcf_1)-dcf_sum(idx1(i),idx2(i),dcf_1-1));
                end
            end
            r1 = 1 ./ r1;
            r1(isnan(r1)) = 0;
            r1(isnan(E1) | isnan(LTG) | isnan(BY)) = NaN;
            r(:,:) = r1;
        end
    end
end
