function ncStruct = selectOoiGliderFlatNcSensors(pStruct, varargin)
%
% ncStruct = selectGliderFlatNcSensors(pStruct, varargin)
%
% See also writeGliderFlatNc Dbd.toProfiles DbdGroup.toProfiles
% ============================================================================
% $RCSfile$
% $Source$
% $Revision$
% $Date$
% $Author$
% ============================================================================
%

app = mfilename;

sensorStruct = [];

% Validate args
if isequal(nargin,0)
    error(sprintf('%s:nargin', app),...
        'No profiles data structure specified');
elseif ~isstruct(pStruct)
    error(sprintf('%s:invalidArgument', app),...
        'pStruct must be a structured array representing individual profiles');
elseif ~isequal(mod(length(varargin),2),0)
    error(sprintf('%s:varargin', app),...
        'Invalid number of options specified');
end

% % % % % MAP_TYPE = 'ioos';
% % % % % % Process options
% % % % % for x = 1:2:length(varargin)
% % % % %     
% % % % %     name = varargin{x};
% % % % %     value = varargin{x+1};
% % % % %     
% % % % %     switch lower(name)
% % % % %         
% % % % %         case 'type'
% % % % %             if ~ischar(value)
% % % % %                 error(sprintf('%s:invalidOption', app),...
% % % % %                     'Value for option %s must be a string',...
% % % % %                     name);
% % % % %             end
% % % % %             
% % % % %             if ~ismember(value, VALID_MAP_TYPES)
% % % % %                 error(sprintf('%s:invalidMapType', app),...
% % % % %                     'Invalid sensor map type: %s',...
% % % % %                     value);
% % % % %             end
% % % % %             
% % % % %             MAP_TYPE = value;
% % % % %         otherwise
% % % % %             error(sprintf('%s:invalidOption', app),...
% % % % %                 'Invalid option specified: %s',...
% % % % %                 name);
% % % % %     end
% % % % % end

sMap = getOoiGliderFlatNcSensorMappings();
if isempty(sMap)
    return;
end

% Add 'time' and 'pressure' fields to mapped to dbd.timestampSensor and
% dbd.depthSensor
% % % % % sMap.time = {'timestamp'}';
% % % % % sMap.pressure = {'depth'}';

% Fieldnames (variables) from the sensor map
vars = fieldnames(sMap);
% Select the available fields from pStruct
pFields = fieldnames(pStruct);

% Select the sensor mappings
for v = 1:length(vars)
    
    % Intialize the entry
    sensorStruct(end+1).ncVarName = vars{v};
    sensorStruct(end).sensor = '';
    sensorStruct(end).data = [];
    
    if isempty(sMap.(vars{v}))
% % % % %         warning(sprintf('%s:unknownSensorMapping', app),...
% % % % %             'Sensor map field contains no sensor mappings: %s\n',...
% % % % %             vars{v});
        continue;
    end
    
    % Search for the specified sensor in the available sensor mapping for
    % this sensor
    [C,AI] = intersect(sMap.(vars{v}), pFields);
    if isempty(C)
% % % % %         warning(sprintf('%s:sensorsNotFound', app),...
% % % % %             '%s: No sensors found in the Dbd instance\n',...
% % % % %             vars{v});
       continue;
    end
    
    % Take the first sensor found in the Dbd instance that satisfies the
    % mapping
    [Y,I] = min(AI);
    sensorStruct(end).sensor = C{I};
    
end

% Initialize the output data structure
ncStruct(length(pStruct)).vars = struct([]);
% Loop through the profiles data structure and add the appropriate data
for p = 1:length(ncStruct)
    
    ncStruct(p).vars = sensorStruct;
    for v = 1:length(ncStruct(p).vars)
        
        ncVar = ncStruct(p).vars(v).sensor;
        
        if isempty(ncVar)
            continue;
        end
        
        % Convert any sensorStruct.ncVarName that ends with 'time' to unix
        % time if it's in Matlab time (datenum)
        ncStruct(p).vars(v).data = pStruct(p).(ncStruct(p).vars(v).sensor);
        
    end
    
    % Add the metadata field for this profile
    ncStruct(p).meta = pStruct(p).meta;
    
end
    