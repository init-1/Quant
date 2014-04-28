classdef TRACE < handle
    properties (Constant, GetAccess = private)
        singularity = TRACE;
    end
    
    properties (Access = private)
        count = 0;
        fid = 0;
        isOwner = false;

        % Related to DB log
        isToDB = false;
        appName
        funName
        vdate
    end
    
    methods 
        function o = TRACE(varargin)
            if isa(TRACE.singularity, 'TRACE') % already there, use existing one
                o = TRACE.singularity;
            end
            if nargin > 0
                o.printf(varargin{:});
            end
        end
        
        function attach(o, fid)
            if ischar(fid)
                o.fid = fopen(fid, 'w');
                o.isOwner = true;
            else
                o.fid = fid;
                o.isOwner = false;
            end
        end
        
        function detach(o)
            if o.isOwner && o.fid > 2
                fclose(o.fid);
            end
            o.fid = 0;
            o.isOwner = false;
        end
        
        function attachDB(o, appName, funcName, vdate)
            o.appName = appName;
            o.funName = funcName;
            o.vdate = datestr(vdate, 'yyyy-mm-dd');
            o.isToDB = true;
        end
        
        function detachDB(o)
            o.isToDB = false;
        end
        
        function run(o, varargin)
            back = repmat('\b', 1, o.count);
            blank = repmat(' ', 1, o.count);
            fprintf(1, [back blank back]);
            o.count = o.engine(varargin{:});
        end
        
        function len = printf(o, varargin)
            len = o.engine(varargin{:});
            if o.isToDB
                o.logDB(0, varargin{:});
            end
        end
        
        function err(o, varargin)
            o.engine(2, varargin{:});  % output in red
            if o.isToDB
                o.logDB(1, varargin{:});
            end
        end
        
        function warn(o, varargin)
            o.engine(1, varargin{:});  % output in red
            if o.isToDB
                o.logDB(2, varargin{:});
            end
        end
        
        function done(o)
            o.printf(' done!\n');
        end
    end
    
    methods (Access = private)
        function len = engine(o, varargin)
            o.count = 0;
            len = fprintf(varargin{:});
            if o.fid > 2
                fprintf(o.fid, ['[' datestr(now,31) '] ']);
                if isnumeric(varargin{1})
                    varargin(1) = [];
                end
                s = sprintf(varargin{:});
                if s(end) ~= 10
                    s = [s char(10)];
                end
                fprintf(o.fid, '%s', s);
            end
        end
        
        function logDB(o, varargin)
            error = 0;
            if isnumeric(varargin{1})
                error = varargin{1};
                varargin(1) = [];
            end
            msg = sprintf(varargin{:});
            if error == 1
                type = 'error';
            elseif error == 2
                type = 'warning';
            else
                type = 'info';
            end
            
            runSP('quantsyslog', 'log.usp_InsertLog', {o.vdate, o.appName, o.funName, msg, type, '', ''});
        end
    end
    
    methods (Static)
        function Err(varargin)
            TRACE.singularity.err(varargin{:});
        end
        
        function Warn(varargin)
            TRACE.singularity.warn(varargin{:});
        end
        
        function Attach(fid)
            TRACE.singularity.attach(fid);
        end

        function AttachDB(appName, funcName, vdate)
            TRACE.singularity.attachDB(appName, funcName, vdate);
        end
        
        function Detach
            TRACE.singularity.detach;
        end

        function DetachDB
            TRACE.singularity.detachDB;
        end
    end        
end

