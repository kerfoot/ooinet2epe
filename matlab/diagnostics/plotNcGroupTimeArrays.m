function plotNcGroupTimeArrays(metadata)
%
% plotNcGroupTimespans(metadata)
%
% Plot the unsorted timespan of each of the NetCDF files metadata elements 
% in metadata.
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
        'No NetCDF metadata structure specified');
elseif ~isstruct(metadata) || isempty(metadata)
    error(sprintf('%s:invalidArgument', app),...
        'The NetCDF metadata structure must be a non-empty structured array');
end

% Plot unsorted time arrays
figure('PaperPosition', [0 0 8.5 11],...
    'Tag', 'tsRaw');
N = length(metadata);
C = 2;
R = ceil(N/C);
axH = nan(N,1);
axes('NextPlot', 'add',...
    'Box', 'on',...
    'TickDir', 'out',...
    'LineWidth', 1,...
    'YTick', [],...
    'FontSize', 8);
for x = 1:N
    
    axH(x) = subplot(R,C,x);
    
    set(axH(x),...
        'Box', 'on',...
        'TickDir', 'out');
    
    ts = epoch2datenum(metadata(x).timestamps);
    
    h = plot(axH(x), ts);
    
    t = title(axH(x), metadata(x).product,...
        'Interpreter', 'None');
    
    datetick(axH(x), 'y', 'mm/dd', 'keeplimits');
    
end