function fts = removedates(fts, ivecDates)
% remove vecDates rows from ifts
fts = setfield(fts, ':', ivecDates, []);
end
