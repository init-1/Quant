function [LastPeriod_EndDate,CurrentPeriod_BeginDate]  = PeriodBeginDate(DateNumber, Freq)

DateNumber = datenum(DateNumber);

switch Freq
    case 'Y'
        Y = year(DateNumber);
        CurrentPeriod_BeginDate = datenum(Y,1,1);
    case 'Q'
        Y = year(DateNumber);
        M = (ceil(month(DateNumber)./3)-1)*3+1;
        CurrentPeriod_BeginDate = datenum(Y,M,1);
    case 'M'
        Y = year(DateNumber);
        M = month(DateNumber);
        CurrentPeriod_BeginDate = datenum(Y,M,1);
    case 'W'
        WeekDay = weekday(DateNumber);
        CurrentPeriod_BeginDate = DateNumber - WeekDay;
    otherwise
        disp('Error: Freq is not supported by this function');
end

LastPeriod_EndDate = CurrentPeriod_BeginDate - 1;

return
