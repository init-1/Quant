function reg(srcFolder, pattern)
    if nargin < 2
        error('Usage: gen srcFolder pattern');    
    end
    
    if srcFolder(end) ~= '\' && srcFolder(end) ~= '/'
        srcFolder(end+1) = '/';
    end
    
    trace = TRACE('Scanning %s\n', srcFolder);
    files = dir(srcFolder);
    if isempty(files)
        trace.printf('Nothing in %s!\n', srcFolder);
        return;
    end
    
    counter = 0;
    for i = 1:length(files)
        f = files(i);    
        if f.isdir...
           || isempty(regexp(f.name, '\.m', 'ONCE'))... % not .m file
           || ~regexp(f.name(1:end-2), pattern, 'ONCE')
           continue;
        end
   
        counter = counter + 1;
        fname = f.name(1:end-2);
        Factory.Register2DB(fname, fname, fname, 1, 1, 1);
    end
    
    trace.printf('%s factors registered.\n', counter);
end
