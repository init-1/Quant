s = RandStream('mt19937ar', 'Seed',20101213);
counter = 0;

m = nan(6,1);
while counter < 6
    x = randi(s,49);
    if ~ismember(x, m)
        counter = counter + 1;
        m(counter) = x;
    end
end

