function output=extract_xmldata(xml,fieldname,outformat)
% outformat==0 -> extract as number
% outformat==1 -> extract as string

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

len_name=length(fieldname);

a=strfind(xml,['<' fieldname '>']);
b=strfind(xml,['</' fieldname '>']);

output = xml(a+len_name+2:b-1);
if outformat==0
    output = str2double(output);
end