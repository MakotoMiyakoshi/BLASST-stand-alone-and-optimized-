function values = parseNumbers(s)
%PARSENUMBERS Parse a user-supplied numeric list, without eval/str2num.
% SPDX-License-Identifier: Apache-2.0
if ~(ischar(s) || isstring(s))
    error('BLASST:GUI','Numeric settings must be text.');
end
s = strtrim(char(s));
if isempty(s)
    values = [];
    return
end
if strcmpi(s,'Inf')
    values = Inf;
    return
end
s = strrep(s,',',' ');
if ~isempty(regexp(s,'[^0-9eE+\-.\s]','once'))
    error('BLASST:GUI','Use only numbers separated by spaces or commas.');
end
values = sscanf(s,'%f')';
if isempty(values)
    error('BLASST:GUI','Could not parse numeric setting.');
end
end
