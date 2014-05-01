function pStruct = mergeIonGliderDatasets(ncFiles, glider, varargin)
%
% Usage:
%
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

pStruct = [];

if nargin < 2
    error(sprintf('%s:nargin', app),...
        'Please specify a cell array of filenames and a glider name');
end

meta = getIonGliderConfig();

REQUIRED_TYPES = {meta.type}';

DENS_VARS = {'sci_water_pracsal',...
    'sci_water_temp',...
    'sci_water_pressure',...
    };
GPS_VARS = {'m_gps_lon',...
    'm_gps_lat'}';

% Find the CTD file
m = regexp(ncFiles, 'ggldr_ctdgv_delayed');
if all(cellfun(@isempty, m))
    error(sprintf('%s:fileNotFound', app),...
        'ggldr_ctdgv_delayed product file not found');
end
ctdNc = ncFiles{~cellfun(@isempty, m)};
ctdNcI = ncinfo(ctdNc);
ctdVars = {ctdNcI.Variables.Name}';

% Make sure we have a metdata description
I = find(ismember(REQUIRED_TYPES, 'ggldr_ctdgv_delayed') == 1);
if isempty(I)
    error(sprintf('%s:missingMetaElement', app),...
        'ggldr_ctdgv_delayed: No metdata element found.');
end
% Make sure we have the required variables
if ~isequal(length(intersect(meta(I).vars, ctdVars)), length(meta(I).vars))
    warning(sprintf('%s:missingVariable', app),...
        'One or more required variables not found: %s',...
        ctdNc);
end

% Retrive the sensors we want to pull from meta(I).vars
TF = cellfun(@isempty, regexp(meta(I).vars, '^time$|sci_water_pressure'));
ctdSensors = meta(I).vars(TF);

% Find the row dimension
dims = {ctdNcI.Dimensions.Name};
numRows = ctdNcI.Dimensions(~cellfun(@isempty, regexp(dims, '^row$'))).Length;

% Initialize the data matrix
data = nan(numRows, length(ctdSensors)+2);

% Pull out the yo 
data(:,[1 2]) = [ncread(ctdNc, 'time')...
    ncread(ctdNc, 'sci_water_pressure')];
% Multiply pressure by 10 to convert from bars to decibars
data(:,2) = data(:,2)*10;

% Add the ctdSensors
for s = 1:length(ctdSensors)
    data(:,s+2) = ncread(ctdNc, ctdSensors{s});
end

% Add sci_water_pressure to ctdSensors
ctdSensors = ['sci_water_pressure'; ctdSensors];

% Eliminate bad depths
data(data(:,2) <= 0,:) = [];

% Sort by time
data = sortrows(data,1);
% Remove dups
dups = find(diff(data(:,1)) == 0);
data(dups+1,:) = [];

% Index the yo
[tsInds,r] = findYoExtrema(data(:,[1 2]));
% Filter the indices to eliminate "empty" profiles
[tsInds,r] = filterYoExtrema(data(:,[1 2]), tsInds,...
    'numpoints', 5,...
    'depthspan', 10,...
    'mindepth', 0.5);

% Convert the timestamps to datenums
data(:,1) = epoch2datenum(data(:,1));

% Initialize a structured array with the number of indexed profiles
pStruct(size(tsInds,1)).meta = []; 
for x = 1:length(pStruct)
    pStruct(x).meta = struct('glider', glider,...
        'startDatenum', [],...
        'endDatenum', [],...
        'lonLat', [NaN NaN]);
    % Profile start
    pStruct(x).meta.startDatenum = epoch2datenum(tsInds(x,1));
    % Profile start
    pStruct(x).meta.endDatenum = epoch2datenum(tsInds(x,2));
    % Add the timeSeries
    pStruct(x).timestamp = data(r(x,1):r(x,2),1);
    % Add the ctd data
    pData = data(r(x,1):r(x,2),:);
    for s = 1:length(ctdSensors)
        pStruct(x).(ctdSensors{s}) = pData(:,s+1);
    end
    
end

% See if we have a fluorescence data file
m = regexp(ncFiles, 'ggldr_flord_delayed');
TF = ~cellfun(@isempty, m);
if any(TF)
    flNc = ncFiles{TF};
    flNcI = ncinfo(flNc);
    flVars = {flNcI.Variables.Name}';
    
    % Make sure we have the required variables
    I = find(ismember(REQUIRED_TYPES, 'ggldr_flord_delayed') == 1);
    if ~isequal(length(intersect(meta(I).vars, flVars)), length(meta(I).vars))
         warning(sprintf('%s:missingVariable', app),...
            'One or more required variables not found: %s',...
            flNc);
    end
    
    % Retrive the sensor data from the NetCDF file
    [data, flSensors] = fetchIonNcVars(flNc,...
        'sensors', meta(I).vars);
    
    % Convert time to datenum
    data(:,1) = epoch2datenum(data(:,1));
    
    % Loop through the profiles structure array and find the 'data' records 
    % that belong in each profile
    for x = 1:length(pStruct)
        
% % % % %         if isequal(x,10)
% % % % %             keyboard;
% % % % %         end
        
        % Find the records that are part of this profile
        pData = data(data(:,1) >= pStruct(x).meta.startDatenum &...
            data(:,1) <= pStruct(x).meta.endDatenum,:);
        
        for s = 2:length(flSensors)
            % Remove NaNs
            sensorData = pData(all(~isnan(pData),2),[1 s]);
            
            iData = nan(length(pStruct(x).timestamp), 1);
            if size(sensorData,1) > 1
                % Interpolate the data to the profile time series
                try
                    iData = interp1(sensorData(:,1),...
                        sensorData(:,2),...
                        pStruct(x).timestamp);
                catch ME
                    warning(ME.identifier, ME.message);
                end
            end
            
            pStruct(x).(flSensors{s}) = iData;
            
        end
        
    end
    
else
    warning(sprintf('%s:fileNotFound', app),...
        'ggldr_flord_delayed product file not found');
end

% See if we have an oxygen data file
m = regexp(ncFiles, 'ggldr_dosta_delayed');
TF = ~cellfun(@isempty, m);
if any(TF)
    oxyNc = ncFiles{TF};
    oxyNcI = ncinfo(oxyNc);
    oxyVars = {oxyNcI.Variables.Name}';
    
    % Make sure we have the required variables
    I = find(ismember(REQUIRED_TYPES, 'ggldr_dosta_delayed') == 1);
    if ~isequal(length(intersect(meta(I).vars, oxyVars)), length(meta(I).vars))
        warning(sprintf('%s:missingVariable', app),...
            'One or more required variables not found: %s',...
            oxyNc);
    end
    
    % Retrive the sensor data from the NetCDF file
    [data, oxySensors] = fetchIonNcVars(oxyNc,...
        'sensors', meta(I).vars);
    
    % Convert time to datenum
    data(:,1) = epoch2datenum(data(:,1));
    
    % Loop through the profiles structure array and find the 'data' records 
    % that belong in each profile
    for x = 1:length(pStruct)
        
        % Find the records that are part of this profile
        pData = data(data(:,1) >= pStruct(x).meta.startDatenum &...
            data(:,1) <= pStruct(x).meta.endDatenum,:);
        
        for s = 2:length(oxySensors)
            % Remove NaNs
            sensorData = pData(all(~isnan(pData),2),[1 s]);
            
            iData = nan(length(pStruct(x).timestamp), 1);
            if size(sensorData,1) > 1
                % Interpolate the data to the profile time series
                try
                    iData = interp1(sensorData(:,1),...
                        sensorData(:,2),...
                        pStruct(x).timestamp);
                catch ME
                    warning(ME.identifier, ME.message);
                end
            end
            
            pStruct(x).(oxySensors{s}) = iData;
            
        end
        
    end
else
    warning(sprintf('%s:fileNotFound', app),...
        'ggldr_dosta_delayed product file not found');    
end

% See if we have an engineering data file
m = regexp(ncFiles, 'ggldr_eng_delayed');
TF = ~cellfun(@isempty, m);
if any(TF)
    engNc = ncFiles{TF};
    engNcI = ncinfo(engNc);
    engVars = {engNcI.Variables.Name}';
    
    % Make sure we have the required variables
    I = find(ismember(REQUIRED_TYPES, 'ggldr_eng_delayed') == 1);
    if ~isequal(length(intersect(meta(I).vars, engVars)), length(meta(I).vars))
        warning(sprintf('%s:missingVariable', app),...
            'One or more required variables not found: %s',...
            engNc);
    end
    
    % Retrive the sensor data from the NetCDF file
    [data, engSensors] = fetchIonNcVars(engNc,...
        'sensors', meta(I).vars);
    
    % Convert time to datenum
    data(:,1) = epoch2datenum(data(:,1));
    
    % Set _FillValues (-9999999) to NaN
    data(data == -9999999) = NaN;
    % Set invalid lat/lon (columns 2 and 3, respectively) to NaN
    data(abs(data(:,2)) > 90,2) = NaN;
    data(abs(data(:,3)) > 180,3) = NaN;
    
    % Linearly interpolate columsn 2:end to fill in the missing values
    % since they're likely on different sampling cycles and interpolating
    % the entire matrix will result in lots of missing values
    for x = 2:size(data,2)
        data(:,x) = interpTimeSeries(data(:,[1 x]), 'method', 'linear');
    end
    
    % Loop through the profiles structure array and find the 'data' records 
    % that belong in each profile
    for x = 1:length(pStruct)
        
        % Find the records that are part of this profile
        pData = data(data(:,1) >= pStruct(x).meta.startDatenum &...
            data(:,1) <= pStruct(x).meta.endDatenum,:);
        
        for s = 2:length(engSensors)
            % Remove NaNs
            sensorData = pData(all(~isnan(pData),2),[1 s]);
            
            iData = nan(length(pStruct(x).timestamp), 1);
            if size(sensorData,1) > 1
                % Interpolate the data to the profile time series
                try
                    iData = interp1(sensorData(:,1),...
                        sensorData(:,2),...
                        pStruct(x).timestamp);
                catch ME
                    warning(ME.identifier, ME.message);
                end
            end
            
            pStruct(x).(engSensors{s}) = iData;
            
        end
        
        gpsSensors = fieldnames(pStruct);        
        % Add the profile center lat/lon if it can be calculated
        [~,AI] = intersect(gpsSensors, GPS_VARS);    
        if isequal(length(GPS_VARS), length(AI)) 
            latLon = [pStruct(x).(GPS_VARS{1}) pStruct(x).(GPS_VARS{2})];
            latLon(any(isnan(latLon),2),:) = [];
            if isempty(latLon)
                continue;
            end
            pStruct(x).meta.lonLat = [mean(latLon(:,1))...
                mean(latLon(:,2))];
        end
        
    end
else
    warning(sprintf('%s:fileNotFound', app),...
        'ggldr_eng_delayed product file not found');        
end

structFields = fieldnames(pStruct);
for x = 1:length(pStruct)
    
    % Add 'sci_water_density' to the p(x).sensors cell array and initialize
    % the data array with NaNs
    pStruct(x).density = nan(length(pStruct(x).timestamp),1);
    
    % See if we have the parameters to calculate density
    [~,AI] = intersect(DENS_VARS, structFields);    
    if isequal(length(DENS_VARS), length(AI))   
        AI = sort(AI);
        pStruct(x).density = sw_dens(pStruct(x).(DENS_VARS{AI(1)}),...
            pStruct(x).(DENS_VARS{AI(2)}),...
            pStruct(x).(DENS_VARS{AI(3)}));
    end
    
%     % Check each profile for latitude and pressure.  If they exist, calculate
%     % the depth (if not already present) and add it to the profile data
%     if ismember('depth', p(x).sensors)
%         continue;
%     end
%     
%     % Add the 'depth' sensor
%     p(x).sensors{end+1} = 'depth';
%     p(x).data(:,end+1) = nan(size(p(x).data,1),1);
%     
%     [~,ZI] = ismember('sci_water_pressure', p(x).sensors);
%     if isempty(ZI)
%         warning(sprintf('%s:missingSensor', app),...
%             'Skipping depth calculation: Profile %d does not contain sci_water_pressure',...
%             x);
%         continue;
%     end
%     
%     [~,LATI] = ismember('m_gps_lat', p(x).sensors);
%     if isempty(LATI)
%         warning(sprintf('%s:missingSensors', app),...
%             'Skipping depth calculation: Profile %d does not contain lat',...
%             x);
%         continue;
%     end
%     
%     meanLat = mean(p(x).data(~isnan(p(x).data(:,LATI)),LATI));
%     if isnan(meanLat)
%          warning(sprintf('%s:missingSensors', app),...
%             'Skipping depth calculation: Profile %d contains no valid latitudes',...
%             x);
%         continue;
%     end
    
    pStruct(x).depth = sw_dpth(pStruct(x).sci_water_pressure,...
        pStruct(x).meta.lonLat(2));
    
end
