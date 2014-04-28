% this is the main function of the backtest tool
% Input 
%    datafile : string - name of the .mat file which contains necessary
%    data for beckatest
%    paramerer: struct - contains necessary parameters for backest, e.g.
%    pickup, atcive bet
%    result2fiel: logical - 1: output result and report to a file; 
%    varargin{1}: cell array - user defined asset level constraints
%    varargin{2}: cell array - user defined attribute level constraints

function [portfolio, analytics] = Main_Backtest(datafile, parameter, result2file, varargin)

%% Step 1: Load workspace (data, parameters, constraints)
[bmhd, signal, fwdret, price, freq, startpf, assetcons, attributecons] = LoadWorkSpace(datafile, parameter, varargin{:});

%% Step 2: Construct portfolio
portfolio = PFConstruction(bmhd, signal, fwdret, price, parameter, startpf, assetcons, attributecons);

%% Step 3: Analytics calculation
analytics = PFAnalytics(portfolio, bmhd, signal, fwdret, parameter.tcost, freq);

%% Step 4: Generate output file
if ~exist('result2file', 'var')
    result2file = 0;
end
if result2file == 1
    reportfile = [datafile, '_report'];
    resultfile = [datafile, '_result'];
    save(resultfile,'portfolio','analytics','parameter');
    PFReport(analytics, parameter, reportfile);
end

return;
