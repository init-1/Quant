function o_sub = GetSubUniverse(o, custuniv)
% this function create a factor analyzer object with subuniverse from original factor analyzer object 
% custuniv.name = {}; % the string name of the universe
% custuniv.data = {}; % data - a myfints with numeric data

% create copy of object
o_sub = o;

% clean the input data
delidx = all(isnan(fts2mat(custuniv.data)),1);
o_sub.bmhd = custuniv.data(:,~delidx);
o_sub.univname = custuniv.name;
o_sub.statistics = [];
o_sub.corrmat = [];


[o_sub.factorts{:}, o_sub.gics, o_sub.ctry, o_sub.ctrysect, o_sub.ctryb2p, o_sub.mcap, o_sub.b2p, o_sub.beta, o_sub.brcost, o_sub.adv, o_sub.fwdret, o_sub.fwdretByDay{:}] = ...
    alignto(o_sub.bmhd, o_sub.factorts{:}, o_sub.gics, o_sub.ctry, o_sub.ctrysect, o_sub.ctryb2p, o_sub.mcap, o_sub.b2p, o_sub.beta, o_sub.brcost, o_sub.adv, o_sub.fwdret, o_sub.fwdretByDay{:});



end