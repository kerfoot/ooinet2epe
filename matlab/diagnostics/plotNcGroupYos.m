function plotNcGroupYos(metadata)
%
% plotNcGroupYos(metadata)
%
% Plot the yo (depth time-series) from the PRESWAT NetCDF file contained
% in the metadata structure.
%
% See also getNcGroupMetadata
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
        'No NetCDF metadata structure specified');
elseif ~isstruct(metadata) || isempty(metadata)
    error(sprintf('%s:invalidArgument', app),...
        'The NetCDF metadata structure must be a non-empty structured array');
end

% PRESWAT plots
[~,I] = ismember('PRESWAT', {metadata.product}');
z = ncread(metadata(I).file, 'sci_water_pressure')*10;
yo = [metadata(I).timestamps z];
figure('PaperPosition', [0 0 11 8.5],...
    'Tag', 'tsRange');
axes('NextPlot', 'add',...
    'Box', 'on',...
    'TickDir', 'out',...
    'LineWidth', 1,...
    'YDir', 'reverse');
% Sort the timestamps in ascending order
[~,I] = sort(yo(:,1));
% Plot the sorted yo
plot(epoch2datenum(yo(I,1)), yo(I,2), 'k.-');

% Find dups
yo = yo(I,:);
dups = find(diff(yo(:,1)) == 0);
yo(dups+1,:) = [];
plot(epoch2datenum(yo(:,1)), yo(:,2), 'ro-');