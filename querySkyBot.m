classdef querySkyBot
    % query skyBot by IMCCE
    % see http://vo.imcce.fr/webservices/skybot/?conesearch
    % for details , now it's a easy mode
    % only support for a box region !
    % fisrt version 2017/5/5 by lifan@pmo.ac.cn
    % useage:
    %         t=querySkyBot('2013-11-01 20:14:25',334.6567,-11.2531,10);
    %         t=t.cone_search();
    %         disp(t.fields)
    %         summary(t.data)
    properties
        epoch
        center
        squareFov
        location
        objFilter
        data
        originSrc
        url
    end
    
    methods % constructor methods
        function self = querySkyBot(epoch,ra,dec,squareFov,location,obj)
            % Input:
            % epoch:Epoch requested, expressed in Julian day 2411320.0- 2469880.0
            %       or formatted as any English textual datetime. string!
            % ra : RA of the center, unit: deg; double
            % dec : DEC of the center, unit: deg;  double
            % squareFov : square region,unit: arcmin; double
            % location : MPC code ; string ,default '500'
            % obj :Code composed of 3 integers (0|1) to specify if, respectively,
            %asteroids, planets and comets must be sought Default: '111'
            %(all objects),string
            if nargin==4
                location='500';
                obj='111';
            elseif nargin==5;
                obj='111';
            end
            self.epoch=epoch;
            self.center.ra=ra;
            self.center.dec=dec;
            self.squareFov=squareFov;
            self.location=location;
            self.objFilter=obj;
            self.data           = nan;
            self.originSrc       = nan;
            self.url='http://vo.imcce.fr/webservices/skybot/skybotconesearch_query.php?';
        end
    end
    properties (Dependent)
        fields
        queryUrl
        allNumber
    end
    % methods of properties !
    methods
        function tt=get.fields(self)
            % returns list of available properties for all epochs
            % example:
    %         t=querySkyBot('2013-11-01 20:14:25',334.6567,-11.2531,10);
    %         t=t.cone_search();
    %         disp(t.fields)
            try
                tt=self.data.Properties.VariableNames;
            catch
                tt=[];
            end
        end
        function tt=get.allNumber(self)
            % returns total number of stars that have been returned
            try
                tt=size(self.data,1);
            catch
                tt=0;
            end
        end
        function tt=get.queryUrl(self)
            % returns URL that has been used in calling VizieR
            try
                tt=self.url;
            catch
                tt=[];
            end
        end
        
        function tt=getitem(self,key,k)
            %
            %             provides access to query data
            %
            %         Parameters
            %         ----------
            %         key          : str/int
            %            epoch index or property key
            %
            %         Returns
            %         -------
            %         query data according to key
            %         example:
            %         t=querySkyBot('2013-11-01 20:14:25',334.6567,-11.2531,10);
            %         t=t.cone_search();
            %         disp(t.fields)
            %         myNeed=t.getitem({'RA','DE'});
            %
            
            if isempty(self.data)
                disp('queryVizieR ERROR: run cone_search() first');
                tt=nan;
            else
                if nargin>2&&max(k)<=self.starNo&&min(k)>0
                    tt=self.data{k,key};
                elseif nargin>2&&(max(k)>self.starNo||min(k)<0)&&k~=':'
                    error('out of index')
                else
                    tt=self.data{:,key};
                end
            end
        end
    end
    % the main query function !
    methods
        function self=cone_search(self)
            % cone search from skybot by imcce
            % example url is
            % http://vizier.u-strasbg.fr/viz-bin/asu-txt?-source=I/329/urat1&-c.ra=10.6847&-c.dec=41.2687&-c.bm=4/2
            % example:
            %         t=querySkyBot( '2013-11-01 20:14:25',334.6567,-11.2531,10);
            %         t=t.cone_search();
            %         disp(t.fields)
            %         summary(t.data)
            % Num	 object number (blank if unnumbered)
            % Name	 object name (official or preliminary designation)
            % RA,DE astrometric J2000 geocentric equatorial coordinates ra dec at the given epoch	degree
            % Class	 class	-
            % Mv	 visual magnitude	-
            % Err	error on the position	arcsec
            % d	     body-to-center angular distance	arcsec
            % dRA,dDE	motion on the celestial sphere ra*cos(de) de 	arcsec/h
            % Dg	geocentric distance	AU
            % Dh	heliocentric distance	AU
            tmpurl=strcat(self.url,...
                sprintf('&-ep=%s',self.epoch),sprintf('&-ra=%f&-dec=%f',self.center.ra,self.center.dec),...
                sprintf('&-bm=%f',self.squareFov),sprintf('&-loc=%s&-mime=text',self.location));
            self.url=tmpurl;
            %   disp(self.url);
            src=webread(self.url);
            self.originSrc=src;
            fieldnames={'Num','Name','RA','DE',...
                'Class','Mv','Err','d','dRA','dDE','Dg','Dh'};
            % get posizition of  data in origin source file
            pos1=regexp(src,'Dh','ONCE')+8;
            % read fixed width text
            formatSpec = '%s%s%s%s%s%s%s%s%s%s%s%s\n';
            try
                C= textscan(src(pos1:end),formatSpec, 'Delimiter', '|', 'WhiteSpace', '',  'ReturnOnError', false);
            catch
                error('check source file %s\n',src);
            end
            for k=[3,4,6:12 ]
                C{k}=cell2mat(cellfun(@str2double,C{k},'UniformOutput', false));
            end
            C{3}=C{3}*15;% from hour to degree;
            self.data=table(C{1:end},'VariableNames',fieldnames);
            % add unit and comments
            self.data.Properties.VariableDescriptions{1} = 'object number (blank if unnumbered)';
            self.data.Properties.VariableDescriptions{2}='object name (official or preliminary designation)';
            self.data.Properties.VariableUnits{3} = 'deg';self.data.Properties.VariableDescriptions{3}='astrometric J2000 geocentric equatorial coordinates ra at the given epoch';
            self.data.Properties.VariableUnits{4} = 'deg';self.data.Properties.VariableDescriptions{4}='astrometric J2000 geocentric equatorial coordinates dec at the given epoch';
            self.data.Properties.VariableDescriptions{5}='class';
            self.data.Properties.VariableUnits{6} = 'mag';self.data.Properties.VariableDescriptions{6}='visual magnitude';
            self.data.Properties.VariableUnits{7} = 'arcsec';self.data.Properties.VariableDescriptions{7}='error on the postion';
            self.data.Properties.VariableUnits{8} = 'arcsec';self.data.Properties.VariableDescriptions{8}='body-to-center angular distance';
            self.data.Properties.VariableUnits{9} = 'arcsec/h';self.data.Properties.VariableDescriptions{9}='motion on the celestial sphere ra*cos(dec)';
            self.data.Properties.VariableUnits{10} = 'arcsec/h';self.data.Properties.VariableDescriptions{10}='motion on the celestial sphere dec';
            self.data.Properties.VariableUnits{11} = 'AU';self.data.Properties.VariableDescriptions{11}='geocentric distance';
            self.data.Properties.VariableUnits{12} = 'AU';self.data.Properties.VariableDescriptions{12}='heliocentric distance';
        end
        
        
    end
    
    
end

