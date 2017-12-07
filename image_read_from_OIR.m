function [image,meta,ref,index] = image_read_from_OIR(fid,sizeX,sizeY,n_tz,ref_sizeX,ref_sizeY,line_rate, flag,n_ch,accu_flag)
% flag==0 -> '.oir', flag==1 -> followed files
% accu_flag,

% Copyright:
% 2014, 2017, Yasuhiro R. Tanaka; 
%
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

frewind(fid)
image = zeros(sizeY,sizeX,n_tz,n_ch,'uint16');
num_line_once=ceil(30/line_rate);
num_divide=ceil(sizeY/num_line_once);

buf_all = fread(fid,[inf],'uint8=>uint8');


if accu_flag~=0
    loc_0 = buf_all==0|buf_all==32;
    loc_0_s1 = [false(1,1);buf_all(1:end-1)==0|buf_all(1:end-1)==32];
    loc_0_s2 = [false(2,1);buf_all(1:end-2)==0|buf_all(1:end-2)==32];
    loc_4_s3 = [false(3,1);buf_all(1:end-3)==4];
    loc_0_s4 = [false(4,1);buf_all(1:end-4)==0|buf_all(1:end-4)==32];
    loc_95_s9 = [false(9,1);buf_all(1:end-9)==95];
    
    if num_divide>10
        loc_49_s9 = [false(9,1);buf_all(1:end-9)==49];
        loc_95_s10 = [false(10,1);buf_all(1:end-10)==95];
    end
end
fstart_p=cell(num_divide,1);
determ_mat=false(length(buf_all),4);%frame_rate<300ms;

if accu_flag~=0
    
    for i=1:num_divide
        if i<11
            a=i;
            fstart_p{i}=find(all([loc_0,loc_0_s1,loc_0_s2,loc_4_s3,loc_0_s4,[false(8,1);buf_all(1:end-8)==47+a],loc_95_s9],2));%�����炪�m��,161102
        else
            a=mod(i,10);
            fstart_p{i}=find(all([loc_0,loc_4_s3,[false(8,1);buf_all(1:end-8)==47+a],loc_49_s9,loc_95_s10],2));
        end
        if flag==0
            fstart_p{i}(1:n_ch)=[];
        end
    end
else
    for i=1:num_divide
        if i<11
            a=i;
        else
            a=mod(i,10);
        end
        if i==1
            determ_mat = [[false(3,1);buf_all(1:end-3)==4],[false(8,1);buf_all(1:end-8)==47+a],[false(9,1);buf_all(1:end-9)==95]];
        else
            determ_mat(:,2) = [false(8,1);buf_all(1:end-8)==47+a];
        end
        fstart_p{i}= find(all(determ_mat,2));
        if flag==0
            fstart_p{i}(1:n_ch)=[];
        end
    end
end

for i = 1:n_ch:length(fstart_p{num_divide})   
    for j=1:num_divide
        for k=1:n_ch
            fseek(fid,fstart_p{j}(i+k-1),-1);
            image(num_line_once*(j-1)+1:min(num_line_once*j,sizeY),1:sizeX,(i-1)/n_ch+1,k) = fread(fid,[sizeX,min(num_line_once,sizeY-num_line_once*(j-1))],'uint16=>uint16')';
        end
    end
end

[meta,~] = meta_read_from_OIR(fid);
index = length(fstart_p{num_divide})/n_ch;
ref=zeros(ref_sizeY,ref_sizeX,n_ch,'uint16');