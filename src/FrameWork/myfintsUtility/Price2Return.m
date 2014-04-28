function rtn = Price2Return(price, horizon)
rtn = price ./ lagts(price, horizon, NaN) - 1;
rtn(1,:) = [];
end