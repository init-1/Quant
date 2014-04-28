factorid   = 'F00001';
aggId      = '00053';
isUpdateDB = 1;
isLive     = 0;
startDate  = '2010-06-01';
endDate    = '2011-03-31';
targetFreq = 'M';
 
F1 = Factory.RunRegistered(factorid, aggId, isUpdateDB, isLive, startDate, endDate, targetFreq);
