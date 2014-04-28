% fn = { 'ACCACRUI'...
% 'ACCACRUP'        'ACCACRUR'        'ASTABCF'         'CSHBRNRT' ...
% 'CAPEX2SAL'       'CAPEX2DEP'       'BKTOPRICE'        ...
% 'DD'              'DT2EQ'           'DIVYLD'          'DTVSP' ...
% 'EBITDAPEV'       'ENTVALS'         'ERNREL'          'ERNYLD' ...
% 'FSTHCOMP'        'GPROFMFF'        'HISERNM'         'INVSM1Q' ...
% 'NPMRGIN'         'OPCFTP'          'OPMRGIN'         'QCKRCHG' ...
% 'RESINCM'         'REVPEREMP'       'ROA'             'ROE' ...
% 'ROIC'            'RTRNCHM'         'SALESTP' ...
% 'STDUERN'         'TTMGRFLTP'  };
fn = {'ROE', 'ROEMOD'};
rundate = '2011-07-31';
secid = LoadIndexHoldingTS('0064106233', '2011-06-30', rundate, 0, 'M');
%
% secid = {'0058@AALBE4'    '0058@AAREA5'    '0058@ABCAM1'    '0058@ABCAR1'    '0058@ABENG3'...
%     '0059SWM'    '0059SWS'    '0059SWX'    '0059SXI'    '0059SYKE'};

fac = cell(length(fn),1);
old = cell(length(fn),1);
r = NaN(length(fn),1);
% for i = 1:length(fn)
%     try
%     disp(fn{i});
%     fid = runSP('QuantStrategy', ['select Id from fac.factormstr where matlabfunction=' '''' fn{i} ''''], {});
%     fid = fid.Id;
%     old{i} = LoadFactorTS(secid, fid, rundate, rundate, 0, 'M');
%     func = str2func(fn{i});
%     fac{i} = create(func(), secid, 1, rundate);
%     [n,o] = alignfields(fac{i}, old{i});
%     n = fts2mat(n);
%     o = fts2mat(o);
%     r(i) = corr(n', o', 'type','spearman','rows','complete');
%     catch e
%         disp(e.message);
%     end
% end

for i = 1:2 %[7 9 23 28]
    try
        disp(fn{i});
        fid = runSP('QuantStrategy', ['select Id from fac.factormstr where matlabfunction=' '''' fn{i} ''''], {});
        fid = fid.Id;
        func = str2func(fn{i});
        old{i} = create(func(), secid, 0, rundate, rundate, 'M');
        fac{i} = create(func(), secid, 1, rundate);
        [n,o] = alignfields(fac{i}, old{i});
        n = fts2mat(n);
        o = fts2mat(o);
        r(i) = corr(n', o', 'type','spearman','rows','complete');
    catch e
        disp(e.message);
    end
end


