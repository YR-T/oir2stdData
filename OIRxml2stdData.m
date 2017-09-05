function stdData = OIRxml2stdData(index,fullpath,meta,ref,varargin)

% input
% index: start index in total of separated files. 
% fullpath: fullpath of original file
% meta: metadata
% ref: reference
% varargin: number of image series

% stdData: (structure) containing fields below
%	Image{c*1} (x*y*z*t uint16)
%	Analog{n*1} ((x*y*z*t)*1 double or logical) or at a reduced resolution
% 	Metadata.
% 		creation_date (char)  %file, creation date
% 		identifier (char)
% 		frame_rate (double)
%       line_rate (double)
% 		pixel_rate (double)
% 		num_frame (double)
% 		pixel_size (double)
% 		name_of_Image{c*1} (char)
% 		name_of_Analog{n*1} (char)
% 		height_factor (double) (rate of calm scan)
% 		depth (double)
% 	AcqMetadata.
% 		AcqSystemName (char)
% 		AcqFileVersion (char)
% 		AcqSystemVersion (char)
% 		AcqDate (char)
% 		LaserWaveLength (uint16)
% 		PMT{c*1} (uint16)
% 		PMTVoltage{c*1} (uint16)
% 		ObjectiveLens_Name (char)
% 		ZoomValue (double)
% 		ScanDirection (char)
% 		ScanMode (char)
%       IntegrationMode (char)      :   2016/11/22 kondo added
%       IntegrationCount (double)   :   2016/11/22 kondo added
% 	RegMetadata.
% 		w_row_ori (double)
% 		w_col_ori (double)
% 		row_disp (double)
% 		col_disp (double)
% 		tr_reg_record{c*1}
% 		ln_reg_record{c*1}
% 	Log{char}(logged calling function and date)

% Copyright:
% 2014,Yasuhiro R. Tanaka; 
% 2017, Yasuhiro R. Tanaka, Masashi Kondo;
% License:
% This code is free software; you can redistribute it and/or modify it
% under the terms of the GNU General Public License as published
% by the Free Software Foundation; either version 2 of the License,
% or any later version. This work is distributed in the hope that it 
% will be useful, but without any warranty; without even the implied
% warranty of merchantability or fitness for a particular purpose. See
% version 2 and version 3 of the GNU General Public License for more
% details. You should have received a copy of the GNU General Public
% License along with this program;If not, see http://www.gnu.org/licenses/.

stdData = struct();

if nargin == 5
    stdData.Image{1}=varargin{1};
elseif nargin == 6
    stdData.Image{1,1}=varargin{1};
    stdData.Image{2,1}=varargin{2};
elseif nargin ==4
    stdData.Image{1,1}=0;
else
    disp('error:num of image must be smaller than 3!')
end
stdData.Analog{1} = 0;
stdData.Metadata.creation_date = date;
stdData.Metadata.identifier = fullpath;

% 各種metadataの位置
p_resonant = strfind(meta,'<lsmimage:scannerSettings type="Resonant">');
p_galvano = strfind(meta,'<lsmimage:scannerSettings type="Galvano">');
p_timelapse = strfind(meta,'<commonparam:axis>TIMELAPSE</commonparam:axis>');
p_piezo = strfind(meta,'<commonparam:paramName>Piezo</commonparam:paramName>');
p_range = strfind(meta,'<commonparam:paramName>Range</commonparam:paramName>');
p_startend = strfind(meta,'<commonparam:paramName>Start End</commonparam:paramName>');
p_channel_start = strfind(meta,'<lsmimage:channel ');
p_channel_end = strfind(meta,' </lsmimage:channel>');
p_pmtvol = strfind(meta,'<lsmparam:voltage>');

% for i=1:nargin-4
%     meta_ch{i} = meta(p_channel_start(i):p_channel_end(i)+20);
%     laser_id{i} = extract_xmldata(meta_ch{i},'lsmimage:laserDataId',1);
%     p_laser = strfind(meta,['laserDataId="',laser_id{i},'">']);
%     meta_laser{i} = meta(p_laser-70:p_laser+910);
% end

if strfind(meta,'<commonparam:axis xsi:type="commonparam:ZAxisParam"')
    
    % chop metafile（secure uniqueness of fieldname）
    % scanner
    if strcmp(extract_xmldata(meta,'lsmimage:scannerType',1),'Resonant')~=0
        meta_scan = meta(p_resonant:end);
    else
        meta_scan = meta(p_galvano:p_resonant);
    end
    
    %timelapse
    meta_timelapse = meta(p_timelapse-47:p_timelapse+318);
    
    %zstack
    if strfind(meta(p_startend-400:p_startend+160),'paramEnable="true"')&strfind(meta(p_startend-400:p_startend+160),'enable="true"')
        meta_z = meta(p_startend-400:p_startend+160);
    elseif strfind(meta(p_range-400:p_range+160),'paramEnable="true"')&strfind(meta(p_range-400:p_range+160),'enable="true"')
        meta_z = meta(p_range-400:p_range+160);
    elseif strfind(meta(p_piezo-400:p_piezo+160),'paramEnable="true"')&strfind(meta(p_piezo-400:p_piezo+160),'enable="true"')
        meta_z = meta(p_piezo-400:p_piezo+160);
    else
        meta_z = '<commonparam:step>0</commonparam:step> <commonparam:maxSize>1</commonparam:maxSize>';
    end

    % Metadata
     stdData.Metadata.sizeX = extract_xmldata(meta_scan,'commonparam:width',0);     % size of reference image. modified by MK, 20161122
     stdData.Metadata.sizeY = extract_xmldata(meta_scan,'commonparam:height',0);    % size of reference image. modified by MK, 20161122
  %   stdData.Metadata.sizeX = extract_xmldata(meta_scan,'commonimage:width',1);      % size of ROI scan image. modified by MK, 20161122
  %   stdData.Metadata.sizeY = extract_xmldata(meta_scan,'commonimage:height',1);     % size of ROI scan image. modified by MK, 20161122
     stdData.Metadata.sizeZ =  extract_xmldata(meta_z,'commonparam:maxSize',0);
    if strfind(meta_timelapse,'<commonparam:axis enable="true">')
        stdData.Metadata.sizeT_all = extract_xmldata(meta_timelapse,'commonparam:maxSize',0);
    else
        stdData.Metadata.sizeT_all = 1;
    end
    stdData.Metadata.sizeT = size(stdData.Image{1},4);
    stdData.Metadata.starting_frame = index;
    stdData.Metadata.pixel_rate = extract_xmldata(meta_scan,'commonparam:pixelSpeed',0);
    stdData.Metadata.line_rate = extract_xmldata(meta_scan,'commonparam:lineSpeed',0);
    stdData.Metadata.frame_rate = extract_xmldata(meta_scan,'commonparam:frameSpeed',0);
    stdData.Metadata.series_interval = extract_xmldata(meta_scan,'commonparam:seriesInterval',0);
    stdData.Metadata.pixel_size = extract_xmldata(meta,'commonparam:x',0);
    stdData.Metadata.z_step = extract_xmldata(meta_z,'commonparam:step',0);
    stdData.Metadata.name_of_Image = [];%cell(length(stdData.Image),1);
    stdData.Metadata.name_of_Analog = [];%cell(length(stdData.Analog),1);
    stdData.Metadata.height_factor = 1;
    stdData.Metadata.depth = [];%cortical_depth
    
    % AcquisitionMetadata
    stdData.AcqMetadata.AcqSystemName = extract_xmldata(meta,'base:systemName',1);
    stdData.AcqMetadata.AcqFileVersion = extract_xmldata(meta,'fileinfo:version',1);
    stdData.AcqMetadata.AcqSystemVersion = extract_xmldata(meta,'base:systemVersion',1);
    stdData.AcqMetadata.AcqDate = extract_xmldata(meta,'base:creationDateTime',1);
    for c=1:nargin-4
%        if strfind(laser_id{c},'(sub)')
 %   stdData.AcqMetadata.LaserWaveLength{c,1} = 1040; %system依存
  %      else
  %          stdData.AcqMetadata.LaserWaveLength{c,1} = extract_xmldata(meta,'commonimage:wavelength',0);
  %      end
%    stdData.AcqMetadata.LaserPower{c,1} = extract_xmldata(meta_laser{c},'commonimage:wavelength',0);
%    stdData.AcqMetadata.PMT{c,1} = extract_xmldata(meta_ch{c},'commonimage:deviceName',1);
    stdData.AcqMetadata.PMTVoltage{c,1} = extract_xmldata(meta(p_pmtvol(c):p_pmtvol(c)+40),'lsmparam:voltage',0);
    end
    stdData.AcqMetadata.ObjectiveLens_Name = extract_xmldata(meta,'opticalelement:name',1);
    stdData.AcqMetadata.ZoomValue = extract_xmldata(meta,'lsmparam:zoom',1);
    
    if strcmp(extract_xmldata(meta_scan,'commonparam:roundtrip',1),'true')==1
        stdData.AcqMetadata.ScanDirection = 'roundtrip';
    else
        stdData.AcqMetadata.ScanDirection = 'one-way';
    end
    if strcmp(extract_xmldata(meta,'lsmparam:sequentialType',1),'None')==1
        stdData.AcqMetadata.ScanMode = 'None';
    else
        stdData.AcqMetadata.ScanMode = 'Sequential';
    end
    
    %%% 2016/11/22 added by MK
    if strfind(extract_xmldata(meta,'lsmparam:integration',1),'None')>0
        stdData.AcqMetadata.IntegrationMode = 'None';
        stdData.AcqMetadata.IntegrationCount = 0;
    elseif strfind(extract_xmldata(meta,'lsmparam:integration',1),'Frame')
        stdData.AcqMetadata.IntegrationMode = 'Frame';
        temp = extract_xmldata(meta,'lsmparam:integration',1);
        stdData.AcqMetadata.IntegrationCount = extract_xmldata(temp,'commonparam:count',0);
    elseif strfind(extract_xmldata(meta,'lsmparam:integration',1),'Line')  % for line scan, no check
        stdData.AcqMetadata.IntegrationMode = 'Line';
        temp = extract_xmldata(meta,'lsmparam:integration',1);
        stdData.AcqMetadata.IntegrationCount = extract_xmldata(temp,'commonparam:count',0);
    end
    %%% 
    
    %RegistrationMetadata
    stdData.RegMetadata.w_row_ori = stdData.Metadata.sizeY;
    stdData.RegMetadata.w_col_ori = stdData.Metadata.sizeX;
    stdData.RegMetadata.row_disp = [];
    stdData.RegMetadata.col_disp = [];
    stdData.RegMetadata.tr_reg_record = cell(length(stdData.Image),1);
    stdData.RegMetadata.ln_reg_record = cell(length(stdData.Image),1);
    stdData.Log = cell(1);%(logged calling function and date)
    stdData.Log{1}=['Created with "' mfilename '" at ' datestr(clock)];
    
    %Analysis
    stdData.Analysis = struct();
    stdData.Analysis.ref = ref;

end