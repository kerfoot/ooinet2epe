function datasets = getNcGroupMetadata(ncFiles)
%
% datasets = getNcGroupMetadata(ncFiles)
%
% Parse the list of files in ncFiles and return metadata structure.
%
% ============================================================================
% $RCSfile$
% $Source$
% $Revision$
% $Date$
% $Author$
% ============================================================================
%

app = mfilename;

if isequal(nargin,0)
    error(sprintf('%s:nargin', app),...
        'No NetCDF files specified');
elseif ~iscellstr(ncFiles) || isempty(ncFiles)
    error(sprintf('%s:invalidArgument', app),...
        'The list of NetCDF files must be a non-empty cell array of strings');
end

datasets = [];

for f = 1:length(ncFiles)
    
    [~, fName] = fileparts(ncFiles{f});
    
    tokens = split(fName, '-');
    if ~isequal(length(tokens), 5)
        warning(sprintf('%s:invalidFilename', app),...
            'Filename has invalid # of tokens: %s\n',...
            fName);
        continue;
    end
    
    datasets(end+1).file = ncFiles{f};
    datasets(end).platform = [tokens{1} '-' tokens{2} '-' tokens{3}];
    datasets(end).product = tokens{4};
    
    ts = ncread(ncFiles{f}, 'time');
    
    datasets(f).timestamps = ts;
    
end
