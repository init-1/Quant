function str = interval2str(nSeconds)
   unitstrs = {'day' 'hour' 'minute' 'second'};
   unitbase = [3600*24; 3600; 60];
   str = '';
   for i = 1:4
       if i == 4
           unitval = nSeconds;
       else
           unitval = floor(nSeconds / unitbase(i));
           nSeconds = mod(nSeconds, unitbase(i));
       end
       if unitval > 1
           str = [str num2str(unitval) ' ' unitstrs{i} 's ']; %#ok<*AGROW>
       elseif unitval > 0
           str = [str num2str(unitval) ' ' unitstrs{i} ' '];
       end
   end
end
