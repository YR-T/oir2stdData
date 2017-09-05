function [meta,metastart] = meta_read_from_OIR(fid)

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

frewind(fid)
buf=fread(fid,[10000000],'uint8=>uint8');
loc_110=find(buf==110);
loc_105_s1=find(buf==105)+1;
loc_101_s2=find(buf==101)+2;
loc_108_s3=find(buf==108)+3;
loc_105_s4=find(buf==105)+4;
loc_102_s5=find(buf==102)+5;
loc_60_s6=find(buf==60)+6;
metastart=intersect(intersect(intersect(intersect(intersect(intersect(loc_110,loc_105_s1),loc_101_s2),loc_108_s3),loc_105_s4),loc_102_s5),loc_60_s6);

if isempty(metastart)~=0
    disp('metadata is not found')
end
metastart=metastart(1)-6;

meta=char(buf(metastart:metastart+29999))';
i=0;
while isempty(strfind(meta,'<annotation'))
    i=i+1;
    meta=[meta char(buf(metastart+30000+(i-1)*1000:metastart+29999+i*1000))'];
end