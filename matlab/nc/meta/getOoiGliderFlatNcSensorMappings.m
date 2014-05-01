function sensorMap = getOoiGliderFlatNcSensorMappings(varargin)
%
% sensor_map = getFlatNcSensorMappings(varargin)
%
% See also writeGliderFlatNc selectFlatNcSensorMappings
% ============================================================================
% $RCSfile$
% $Source$
% $Revision$
% $Date$
% $Author$
% ============================================================================
%

app = mfilename;
sensorMap = [];

if ~isequal(mod(length(varargin),2),0)
    error(sprintf('%s:nargin', app),...
        'Invalid (odd) number of options specified');
end

% Process Options
for x = 1:2:length(varargin)
    
    name = varargin{x};
    value = varargin{x+1};
    
    switch lower(name)
        
        otherwise
            error(sprintf('%s:invalidOption', app),...
                'Invalid option specified: %s',...
                name);
    end
end

% Add defaults sensor mappings
sensorMap.time = {'timestamp',...
    }';

sensorMap.lat = {'m_gps_lat',...
    }';

sensorMap.lon = {'m_gps_lon',...
    }';

sensorMap.pressure = {'sci_water_pressure',...
    }';

sensorMap.depth = {'depth',...
    }';

sensorMap.temperature = {'sci_water_temp',...
    }';

sensorMap.conductivity = {'sci_water_cond',...
    }';

sensorMap.salinity = {'sci_water_pracsal',...
    }';

sensorMap.density = {'density',...
    }';

sensorMap.chla = {'sci_flbb_chlor_units',...
    }';

sensorMap.bb = {'sci_flbb_bb_units',...
    }';

sensorMap.oxygen_sat = {'sci_oxy4_saturation',...
    }';

sensorMap.oxygen_conc = {'sci_oxy4_oxygen',...
    };

% % % % %     sensorMap.u = {'drv_u',...
% % % % %         'm_water_vx',...
% % % % %         'm_final_water_vx',...
% % % % %         }';
% % % % % 
% % % % %     sensorMap.v = {'drv_v',...
% % % % %         'm_water_vy',...
% % % % %         'm_final_water_vy',...
% % % % %         }';
% % % % % 
% % % % %     sensorMap.time_uv = {}';
% % % % % 
% % % % %     sensorMap.lat_uv = {}';
% % % % % 
% % % % %     sensorMap.lon_uv = {}';

sensorMap.profile_id = {}';

sensorMap.profile_time = {}';

sensorMap.profile_lat = {}';

sensorMap.profile_lon = {}';
    


    