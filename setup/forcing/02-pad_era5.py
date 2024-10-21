#!/home/nicole.laureanti/miniconda3/envs/obcic/bin/python
#Pad ERA5 Forcing File using Xarray

import xarray as xr
import os
import cftime
import numpy as np

datadir='/scratch/servicos/inpe2/nicole.laureanti/SWA14/forcing_subset_ERA5/'
outdir='/scratch/servicos/inpe2/nicole.laureanti/SWA14/forcing_final_ERA5/'


era5_dict = {#'ERA5_sea_ice_cover':'siconc',
            'ERA5_10m_u_component_of_wind':'u10',
            #'ERA5_sea_surface_temperature':'sst',
            'ERA5_10m_v_component_of_wind':'v10',
            'ERA5_2m_temperature':'t2m',
            'ERA5_surface_solar_radiation_downwards':'ssrd',
            'ERA5_surface_thermal_radiation_downwards':'strd',
            'ERA5_total_rain_rate':'trr',
            'ERA5_mean_sea_level_pressure':'msl',
            'ERA5_2m_specific_humidity':'huss'}

for year in range(2022,2023):        
        for f in era5_dict.keys():
            print(f)
            # open the file for current year
            current = xr.open_dataset(f"{datadir}/{f}_{year}.nc")
            try:
                previous = xr.open_dataset(f"{datadir}/{f}_{year-1}.nc").isel(time=-1)
                next_data = xr.open_dataset(f"{datadir}/{f}_{year+1}.nc").isel(time=0)
                out = xr.concat([previous, current, next_data], dim="time")
                previous.close();next_data.close()
            except:
                out = current
                current.close()
            print(out)
            all_vars = list(out.data_vars.keys()) + list(out.coords.keys())
            encodings = {v: {'_FillValue': 1.0e20} for v in all_vars}
            encodings['time'].update({'dtype':'float64', 'calendar': 'gregorian'})
            out['time'].attrs['long_name'] = 'time'
            out['time'].attrs['standard_name'] = 'time'
            out['time'].attrs['axis'] = 'T'
            out['latitude'].attrs['long_name'] = 'Latitude'
            out['latitude'].attrs['units'] = 'degrees_north'
            out['latitude'].attrs['axis'] = 'Y'
            out['longitude'].attrs['long_name'] = 'Longitude'
            out['longitude'].attrs['units'] = 'degrees_east'
            out['longitude'].attrs['axis'] = 'X'
            out=out.transpose("time", "latitude", "longitude")
            # latitude needs to be reindexed for some reason
            out=out.reindex(latitude=list(reversed(out.latitude)))
            out.to_netcdf(f'{outdir}{f}_{year}.nc', format="NETCDF4_CLASSIC", encoding=encodings, unlimited_dims='time')
            out.close()
