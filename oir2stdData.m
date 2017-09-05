function [output_list,stdData]=oir2stdData(fullpath,mode,accu_flag)
%
% input variables
% fullpath='X:\...\...\*.oir', absolute path is needed. 
% all related files is required in the same folder with the target file.
% mode == 0 -> save in separate files (< 1GB saved in -v6)
% mode == 1 -> concatenate files, DO NOT save automatically! (in case the file is too big)
% accu_flag==0, by 1.3-fold faster than set at 1
% accu_flag = 0 can be lead an error to read file, then use accu_flag = 1
% default setting is mode =1, accu_flag=0
%
% output variables
% output_list is a file list of saved files when mode = 0
% stdData is a struct to contain, images and metadata
% images will be found in stdData.Image{1}, etc in x*y*z*t format
%
% Copyright:
% 2014, 2017, Yasuhiro R. Tanaka; 
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

if isempty(strfind(fullpath,'.oir'))
    disp('input *.oir file!');
    return
end

if nargin==1
    mode=1;
    accu_flag=0;
end

% search related files
c1 = strfind(fullpath,'\');
c2 = strfind(fullpath,'.oir');
filename = fullpath(c1(end)+1:c2-1);

filelist = dir(pwd);
search_ph = [filename '_[0-9]+[0-9]+[0-9]+[0-9]+[0-9]'];

for i=length(filelist):-1:1
    if isempty(regexp(filelist(i).name,search_ph,'ONCE'))
        filelist(i)=[];
    end
end

fid = fopen(fullpath);

% metadata
[meta,~] = meta_read_from_OIR(fid);
stdData = OIRxml2stdData(0,'',meta,0);
ref_sizeX = stdData.Metadata.sizeX; % full image size (e.g. 512 etc)
ref_sizeY = stdData.Metadata.sizeY;
line_rate = stdData.Metadata.line_rate;
stdData.Metadata.sizeY = sizeY_extract(fid); % ROI size
stdData.Metadata.sizeX = sizeX_extract(fid);
n_z = stdData.Metadata.sizeZ;
sizeX = stdData.Metadata.sizeX;
sizeY = stdData.Metadata.sizeY;
loc_channelId = strfind(meta,'pmt channelId');
n_ch = numel(loc_channelId);
n_tz = floor(1.08e9/sizeX/sizeY/2); 

switch n_ch
    case 1
        previous_index=0;
        for i = 0:1:length(filelist)
            if i==0
                flag=0;
            else
                flag=1;
                fid = fopen(filelist(i).name);
                fullpath=[pwd '\' filelist(i).name];
            end
            
            [image1,meta,ref,index] = image_read_from_OIR(fid,sizeX,sizeY,n_tz,ref_sizeX,ref_sizeY,line_rate,flag,n_ch,accu_flag);
            image1(:,:,index+1:n_tz) = [];
            
            if i~=0
                image1 = cat(3,image_res,image1);
                if ~isempty(image_res)
                    index = index+size(image_res,3);
                end
            end
            
            image_res = [];
            if n_z ~= 1
                image_res = image1(:,:,floor(index/n_z)*n_z+1:index);% residual image will be included into next series
            end
            image1(:,:,floor(index/n_z)*n_z+1:index) = [];
            image1 = reshape(image1,sizeY,sizeX,n_z,floor(index/n_z));
            if mode==0
                % make stdData for individual files
                stdData = OIRxml2stdData(previous_index+1,fullpath,meta,ref,image1);
                stdData.Metadata.sizeY = sizeY_extract(fid);
                stdData.Metadata.sizeX = sizeX_extract(fid);
                
                if i<10
                    numstr = ['0' num2str(i)];
                else
                    numstr = num2str(i);
                end
                
                save([pwd '\' filename '_' numstr '.mat'],'stdData','-v6');
                output_list(i+1,1).name = [pwd '\' filename '_' numstr '.mat'];
                previous_index = previous_index+size(image1,4);
                clear image1
                clear stdData
                fclose(fid);
            else
                if i==0
                    stdData = OIRxml2stdData(previous_index+1,fullpath,meta,ref,image1);
                    stdData.Metadata.sizeY = sizeY_extract(fid);
                    stdData.Metadata.sizeX = sizeX_extract(fid);
                else
                    stdData_tmp = OIRxml2stdData(1,fullpath,meta,ref,image1);
                    stdData.Image{1}=cat(4,stdData.Image{1},stdData_tmp.Image{1});
                    output_list(i+1,1).name=[];
                end
            end
        end
        
    case 2
        flag=0;
        [image_out,meta,ref,index] = image_read_from_OIR(fid,sizeX,sizeY,n_tz,ref_sizeX,ref_sizeY,line_rate,flag,n_ch,accu_flag);
       
        image1=image_out(:,:,:,1);
        image2=image_out(:,:,:,2);
        
        image1(:,:,index+1:n_tz) = [];
        image2(:,:,index+1:n_tz) = [];
        
        image1_res = [];
        if n_z ~= 1
            image1_res = image1(:,:,floor(index/n_z)*n_z+1:index);
        end
        
        image2_res = [];
        if n_z ~= 1
            image2_res = image2(:,:,floor(index/n_z)*n_z+1:index);
        end
        
        image1(:,:,floor(index/n_z)*n_z+1:index) = [];
        image1 = reshape(image1,sizeY,sizeX,n_z,floor(index/n_z));
        image2(:,:,floor(index/n_z)*n_z+1:index) = [];
        image2 = reshape(image2,sizeY,sizeX,n_z,floor(index/n_z));
        %   ref{1,1} = ref(:,:,1); % reference image is not acquired
        %  ref{2,1} = ref(:,:,2);
        stdData = OIRxml2stdData(1,fullpath,meta,ref,image1,image2);
        stdData.Metadata.sizeY = sizeY_extract(fid);
        stdData.Metadata.sizeX = sizeX_extract(fid);
        
        if mode ==0
            save([pwd '\' filename '_00.mat'],'stdData','-v6');
            output_list.name = [pwd '\' filename '_00.mat'];
            previous_index = size(image1,4);
            clear image1
            clear image2
            clear stdData
            fclose(fid);
        end
     
        for i = 1:length(filelist)
            
            fid = fopen(filelist(i).name);
            flag=1;

            [image_out,meta,~,index] = image_read_from_OIR(fid,sizeX,sizeY,n_tz,ref_sizeX,ref_sizeY,line_rate,flag,n_ch,accu_flag);

            image1=image_out(:,:,:,1);
            image2=image_out(:,:,:,2);
            image1(:,:,index+1:n_tz) = [];
            image1 = cat(3,image1_res,image1);
            image2(:,:,index+1:n_tz) = [];
            image2 = cat(3,image2_res,image2);
            if ~isempty(image1_res)
                index = index+size(image1_res,3);
            end
            if n_z ~= 1
                image1_res = image1(:,:,floor(index/n_z)*n_z+1:index);
            end
            if n_z ~= 1
                image2_res = image2(:,:,floor(index/n_z)*n_z+1:index);
            end
            image1(:,:,floor(index/n_z)*n_z+1:index) = [];
            image1 = reshape(image1,sizeY,sizeX,n_z,floor(index/n_z));
            image2(:,:,floor(index/n_z)*n_z+1:index) = [];
            image2 = reshape(image2,sizeY,sizeX,n_z,floor(index/n_z));
            
            if mode ==0
                stdData = OIRxml2stdData(previous_index+1,[pwd '\' filelist(i).name],meta,ref,image1,image2);
                stdData.Metadata.sizeY = sizeY_extract(fid);
                stdData.Metadata.sizeX = sizeX_extract(fid);
                
                if i<10
                    numstr = ['0' num2str(i)];
                else
                    numstr = num2str(i);
                end
                
                save([pwd '\' filename '_' numstr '.mat'],'stdData','-v6');% no compression, fast
                output_list(i+1,1).name = [pwd '\' filename '_' numstr '.mat'];
                previous_index = previous_index+size(image1,4);
                clear image1
                clear image2
                clear stdData
                fclose(fid);
            else
                stdData_tmp = OIRxml2stdData(1,[pwd '\' filelist(i).name],meta,ref,image1,image2);
                stdData.Image{1}=cat(4,stdData.Image{1},stdData_tmp.Image{1});
                stdData.Image{2}=cat(4,stdData.Image{2},stdData_tmp.Image{2});
                output_list(i+1,1).name=[];
            end
   
        end
end
end

function sizeY = sizeY_extract(fid)
% sizeY
frewind(fid);
char_test = fread(fid,5000000,'uint8=>char')';
loc_y = strfind(char_test,'<base:height');
frewind(fid);
fseek(fid,loc_y(1)-100,0);
meta_single = fread(fid,500,'uint8=>char')';
sizeY = extract_xmldata(meta_single,'base:height',0);
% sizeY
end

function sizeX = sizeX_extract(fid)
% sizeX
frewind(fid);
char_test = fread(fid,5000000,'uint8=>char')';
loc_x = strfind(char_test,'<base:width');
frewind(fid);
fseek(fid,loc_x(1)-100,0);
meta_single = fread(fid,500,'uint8=>char')';
sizeX = extract_xmldata(meta_single,'base:width',0);
% sizeX
end