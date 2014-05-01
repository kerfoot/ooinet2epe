function plotNcGroupTimespans(metadata)
%
% plotNcGroupTimespans(metadata)
%
% Plot the timespan of each of the NetCDF files metadata elements in
% metadata.
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

% Plot the time ranges for each file
figure('PaperPosition', [0 0 11 8.5],...
    'Tag', 'tsRange');
axes('NextPlot', 'add',...
    'Box', 'on',...
    'TickDir', 'out',...
    'LineWidth', 1,...
    'YTick', []);
N = length(metadata);
bounds = nan(N,2);
ylim([0 N+1]);
cmap = flipud(zeros(N,3));
for x = 1:N
    
    ts = epoch2datenum(metadata(x).timestamps);
    
    tRange = [min(ts); max(ts)];
    bounds(x,:) = tRange';
    tRange = [tRange repmat(x,2,1)];
    
    plot(tRange(:,1), tRange(:,2),...
        'Marker', '.',...
        'MarkerSize', 20,...
        'Color', cmap(x,:),...
        'LineStyle', '-',...
        'LineWidth', 2);
    
    % Add the label
    t = text(mean(tRange(:,1)), tRange(1,2)+0.1, metadata(x).product,...
        'HorizontalAlignment', 'center',...
        'VerticalAlignment', 'bottom',...
        'interpreter', 'none',...
        'color', cmap(x,:));
    
end

% Format the x-axis
datetick('x', 'mm/dd', 'keeplimits');

% Title the plot with the min/max times
t = title([metadata(1).platform ': ' datestr(min(bounds(:,1)), 'yyyy-mm-dd')...
    ' - '...
    datestr(max(bounds(:,2)), 'yyyy-mm-dd')]);
