function setting = LoadAXSetting(dsparam,varargin)

setting = Defaults.setting(dsparam);

% Input params
inputparam = varargin(1:2:end-1);
inputvalue = varargin(2:2:end);

% display illegal parameter names detected
if ~isempty(inputparam(~ismember(inputparam,fieldnames(setting))))
    illegal = inputparam(ismember(inputparam,fieldnames(setting)));
    warning(['The following parameter(s) are illegal and will not be used:',sprintf(' %s',illegal{:}) '.']);
end

% updates setting if they exist in varargin
for i=1:length(inputparam)
    if ~isempty(inputvalue{i})
        setting.(inputparam{i}) = inputvalue{i};
    end
end

end