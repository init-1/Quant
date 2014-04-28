function FolderCls2FileCls(classFolder, destFolder)
    if nargin < 2
        destFolder = '.\';
    end
    
    if nargin < 1
        error('Sepcify a class folder, please');    
    end

    if classFolder(end) ~= '\' && classFolder(end) ~= '/'
        classFolder(end+1) = '\';
    end
    
    if destFolder(end) ~= '\' && destFolder(end) ~= '/'
        destFolder(end+1) = '\';
    end
    
    fprintf('Scanning %s\n', classFolder);
    
    subfolders = dir(classFolder);
    if isempty(subfolders)
        fprintf('nothing in there!\n');
        return;
    end
    
    counter = 0;
    for i = 1:length(subfolders)
        sf = subfolders(i);    
        if ~sf.isdir || sf.name(1) ~= '@'
            continue;
        end
        
        fprintf('%s\n', sf.name);
        className = sf.name(2:end);
        
        files = dir([classFolder sf.name]);
        idx = false(1,length(files));
        for k = 1:length(files)
            if ~files(k).isdir && ~isempty(regexp(files(k).name, '\.m$', 'ONCE'))
                idx(k) = true;
            end
        end
        files = files(idx);
        
        if isempty(files), continue; end

        counter = counter + 1;
        
        if length(files) == 1  % only one file in there
            assert(strcmpi(files.name, [className '.m']));
            copyfile([classFolder sf.name '\' files.name], destFolder, 'f');
            continue;
        end
        
        fr = fopen([classFolder sf.name '\' className '.m'], 'r');
        if fr < 1, continue; end
        
        fw = fopen([destFolder, className '.m'], 'w');
        if fw < 1
            fclose(fr);
            disp(['can not create ' destFolder className '.m']);
            continue;
        end
        enterMethod   = 0;
        enterFunction = 0;
        enterCompound = 0;
        everEnterMethod = false;
        line = fgets(fr);
        while ischar(line)
            if ~isempty(regexp(line, '^\s*methods\>.*\<Static\>', 'ONCE')) 
                if ~isempty(regexp(line, '\<protected\>', 'ONCE')) && ~everEnterMethod
                    enterMethod = enterMethod + 1;
                    everEnterMethod = true;
                    assert(enterMethod < 2);
                    fprintf(fw, line);
                    [s,e] = regexp(line, '^\s*',  'ONCE');
                    leadingSpace = [line(s:e) '    '];
                end
            elseif ~isempty(regexp(line, '^\s*function\>', 'ONCE')) && enterMethod
                enterFunction = enterFunction + 1;
            elseif ~isempty(regexp(line, '(^\s*if\>|^\s*while\>|^\s*for\>).*\<end\>', 'ONCE'))
                % nothing to do
            elseif ~isempty(regexp(line, '^\s*if\>|^\s*while\>|^\s*for\>', 'ONCE')) && enterFunction
                enterCompound = enterCompound + 1;
            elseif  ~isempty(regexp(line, '^\s*end\s*', 'ONCE'))
                if enterCompound
                    enterCompound = enterCompound - 1;
                elseif enterFunction
                    enterFunction = enterFunction - 1;
                    fprintf(fw, '%s', line);
                elseif enterMethod
                    enterMethod = enterMethod - 1;
                    for k = 1:length(files)
                        f = files(k);
                        if f.isdir || strcmpi(f.name, [className '.m'])
                            continue;
                        end
                        fid = fopen([classFolder sf.name '\' f.name], 'r');
                        s = fgets(fid);
                        while ischar(s)
                            fprintf(fw, '%s', [leadingSpace s]);
                            s = fgets(fid);
                        end
                        fclose(fid);
                        fprintf(fw, '\n');
                    end
                else
                    %warning('Wondering: extra end');
                end
            end
            if enterFunction || ~enterMethod
                fprintf(fw, '%s', line);
            end
            line = fgets(fr);
        end
        fclose(fr);
        fclose(fw);
    end
    
    fprintf('%d methods processed.\n', counter);
end

