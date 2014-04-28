%% This is a demo on how to run a backtest with a factor from database

% input 
filename = 'DEMO';
signal = 'F00001'; % note here the signal could also be a myfints prepared by user
aggid = '00053'; 
startdate = '2000-01-01';
enddate = '2011-05-31';
freq = 'M';

% load data
LoadData('DEMO', 'F00001', '00053', '2000-01-01', '2011-05-31', 'M');

% load parameter
parameter = LoadParameter('pickup',0.2,'actbet',0.01,'propactbet','signal');
parameter = LoadParameter();

% Run backtest 
[portfolio, analytics] = Main_Backtest('DEMO',parameter,1);
