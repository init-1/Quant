function matdate = SQLDate2MatDate(sqldate)
    diff = 730486 - 36524;   % for 2000-01-01
    matdate = diff + sqldate;
end
