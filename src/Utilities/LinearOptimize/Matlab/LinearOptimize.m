% linear optimization for portfolio construction (one period)

function optweight = LinearOptimize(alpha, bmweight, pfweight, pickup, maxto, lb, ub, varargin)

assert(pickup >= 0, 'invalid input: pickup is smaller than 0');
assert(length(alpha) == length(bmweight) & length(bmweight) == length(pfweight), 'invalid input: the size of alpha, portfolio and benchmark do not match')

%% input data cleaning
bmweight(isnan(bmweight)) = 0;
pfweight(isnan(pfweight)) = 0;
alpha(isnan(alpha)) = 0;

%% construct the constraints
Aeq = [];
A = [];
beq = [];
b = [];
for i = 1:length(varargin)
    con = varargin{i};
    con.A(isnan(con.A)) = 0;
    if isinf(con.b)
        continue;
    end
    switch con.type
        case '='
            Aeq = [Aeq; con.A];
            beq = [beq; con.b];
        case '>='
            A = [A; -con.A];
            b = [b; -con.b];            
        case '<='
            A = [A; con.A];
            b = [b; con.b]; 
    end
end

%% transform the objective and constraints to utilize pickup technique
newalpha = [alpha+pickup; alpha];
% w0 = [pfweight; zeros(size(pfweight))];

% lower bound and upper bound for 'Hold or Sell' portfolio
lb1 = min(pfweight, lb); % the lower bound of the position cannot exceed the original holding and upper bound
ub1 = min(pfweight, ub); % the upper bound of the position cannot exceed the original holding and upper bound
% ub1(~(bmweight > 0)) = 0;

% lower bound and upper bound for 'New Buy' portfolio
lb2 = max(lb - pfweight, 0);
ub2 = max(ub - pfweight, 0);
% ub2(~(bmweight > 0)) = 0;

% lower bound and upper bound for the combined portfolio
lb_combined = [lb1;lb2];
ub_combined = [ub1;ub2];

% attribute for the combined portfolio
A = [A, A];
Aeq = [Aeq, Aeq];

% enforce turnover constraint
maxto(isnan(maxto)|isinf(maxto)) = 2;
Ato = [zeros([1,size(lb1)]),ones([1,size(lb2)])];
bto = maxto/2;
A = [A;Ato];
b = [b;bto];

%% run linear optimization
options = optimset('LargeScale', 'off', 'Simplex', 'on');
[newweight,fval,exitflag,output,lambda] = linprog(-newalpha, A, b, Aeq, beq, lb_combined, ub_combined, [], options);

% [newweight,fval,exitflag,output,lambda] = linprog(-newalpha, A, b, Aeq, beq, lb_combined, ub_combined);

%% transform the weight back to the combined portfolio weight

optweight = newweight(1:numel(pfweight)) + newweight(numel(pfweight)+1:end);

return