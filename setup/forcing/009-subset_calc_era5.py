#!/Volumes/A1/workdir/nicole/envs/xesmf_env_test/bin/python
#Subset ERA5 from Global grid to NWA25 domain and calculate Specific Huimdity & Total Rain Rate
# slice down the data
import xarray as xr
import os
import cftime
import numpy as np
from glob import glob
import os

lati=15
latf=-65
loni=281
lonf=355

# Functions for humidity borrowed and adapted from MetPy.calc: https://unidata.github.io/MetPy/latest/api/generated/metpy.calc.html
def mixing_ratio(partial_press, total_press, molecular_weight_ratio=0.622):
    return (molecular_weight_ratio * partial_press
                / (total_press - partial_press))


def specific_humidity_from_mixing_ratio(mr):
    return mr / (1 + mr)


def saturation_vapor_pressure(temperature):
    sat_pressure_0c = 6.112e2 # Pa
    return sat_pressure_0c * np.exp(17.67 * (temperature - 273.15) # K -> C
                                        / (temperature - 29.65))   # K -> C

def saturation_mixing_ratio(total_press, temperature):
    return mixing_ratio(saturation_vapor_pressure(temperature), total_press)



era5_dict = {'ERA5_sea_ice_cover':'siconc',
            'ERA5_10m_u_component_of_wind':'u10',
            'ERA5_sea_surface_temperature':'sst',
            'ERA5_10m_v_component_of_wind':'v10',
            'ERA5_2m_temperature':'t2m',
            'ERA5_surface_solar_radiation_downwards':'ssrd',
            'ERA5_surface_thermal_radiation_downwards':'strd',
            'ERA5_total_rain_rate':'trr',
            'ERA5_mean_sea_level_pressure':'msl',
            'ERA5_2m_specific_humidity':'huss'}

era5_dict = {'ERA5_sea_ice_cover':'siconc',
            'ERA5_surface_solar_radiation_downwards':'ssrd',
            'ERA5_surface_thermal_radiation_downwards':'strd',
            'ERA5_total_rain_rate':'trr'}

years=range(2001,2003)
#subset
rawdir = "/Volumes/A1/workdir/james/ERA5/raw/"
outdir="/home/nicole/workdir/SWA14/forcing2_subset_ERA5/"
for f in era5_dict.keys():
    print(f)
    for y in years:
        print(y)
        if f =='ERA5_surface_solar_radiation_downwards':
                ds=xr.open_dataset(str(rawdir + f + '_' + str(y) + ".nc")).sel(latitude=slice(lati,latf), longitude=slice(loni,lonf))
                print(ds.coords,ds.dims)
                ds['ssrd'] = (ds['ssrd']/3600).resample(time="3H").mean() #nicole: get 3h radiation
                ds=ds.dropna(dim='time')
                print(ds.coords,ds.dims)
                ds.to_netcdf(str(outdir + f + '_' + str(y) + ".nc"),format="NETCDF4_CLASSIC")
                ds.close()

        elif f =='ERA5_surface_thermal_radiation_downwards':
                ds=xr.open_dataset(str(rawdir + f + '_' + str(y) + ".nc")).sel(latitude=slice(lati,latf), longitude=slice(loni,lonf))
                ds['strd'] = (ds['strd']/3600).resample(time="3H").mean() #nicole: get 3h radiation
                ds=ds.dropna(dim='time')
                ds.to_netcdf(str(outdir + f + '_' + str(y) + ".nc"),format="NETCDF4_CLASSIC")
                ds.close()

        elif f=='ERA5_sea_ice_cover':
                ds=xr.open_dataset(str(rawdir + f + '_' + str(y) + ".nc")).sel(latitude=slice(lati,latf), longitude=slice(loni,lonf))
                ds['siconc'] = (ds['siconc']).resample(time="3H").sum() #nicole: get 3h accum.
                ds=ds.dropna(dim='time')
                ds.to_netcdf(str(outdir + f + '_' + str(y) + ".nc"),format="NETCDF4_CLASSIC")
                ds.close()

        elif f=='ERA5_total_rain_rate':
            crr = xr.open_dataset(str(rawdir + 'ERA5_convective_rain_rate_' + str(y) + '.nc')).sel(latitude=slice(lati,latf), longitude=slice(loni,lonf))
            lsrr = xr.open_dataset(str(rawdir + 'ERA5_large_scale_rain_rate_' + str(y) + '.nc')).sel(latitude=slice(lati,latf), longitude=slice(loni,lonf))
            trr = xr.Dataset()
            trr['trr'] = crr['crr'] + lsrr['lsrr']
            #trr['trr'] = trr['trr'].groupby(trr['trr'].time.dt.day).sum() #nicole: get daily ppt
            trr['trr'] = (trr['trr']).resample(time="3H").sum()
            trr=trr.dropna(dim='time')
            trr['trr'].attrs = {'units': 'kg m**-2 s**-1','long_name': 'Total Rainfall Rate (convective and large scale)'}
            trr.trr.encoding = {k: v for k, v in crr.crr.encoding.items() if k in {'_FillValue', 'missing_value', 'dtype'}}
            #trr.trr.encoding.update({'add_offset': None, 'scale_factor': None})
            all_vars = list(trr.data_vars.keys()) + list(trr.coords.keys())
            encodings = {v: {'_FillValue': 1.0e20} for v in all_vars}
            encodings['time'].update({'dtype':'float64', 'calendar': 'gregorian'})
            encodings['trr'].update({'dtype':'float32'})
            trr.to_netcdf(str(outdir + f + '_' + str(y) + ".nc"), mode='w', format='NETCDF4_CLASSIC', encoding=encodings, unlimited_dims='time')
            crr.close()
            lsrr.close()
            trr.close()
        elif f=='ERA5_2m_specific_humidity':
            pair = xr.open_dataset(str(rawdir + 'ERA5_surface_pressure_' + str(y) + '.nc'))['sp'].sel(latitude=slice(lati,latf), longitude=slice(loni,lonf)) # Pa
            tdew = xr.open_dataset(str(rawdir + 'ERA5_2m_dewpoint_temperature_' + str(y) + '.nc'))['d2m'].sel(latitude=slice(lati,latf), longitude=slice(loni,lonf)) # K

            smr = saturation_mixing_ratio(pair, tdew)
            sphum = specific_humidity_from_mixing_ratio(smr)

            sphum.name = 'huss'
            sphum = sphum.to_dataset()

            # Remove all _FillValue
            all_vars = list(sphum.data_vars.keys()) + list(sphum.coords.keys())
            encodings = {v: {'_FillValue': None} for v in all_vars}

            # Also fix the time encoding
            encodings['time'].update({'dtype':'float64', 'calendar': 'gregorian', 'units': 'hours since 1900-01-01 00:00:00'})
            
            fout=str(outdir + f + '_' + str(y) + ".nc")
            sphum.to_netcdf(
                fout,
                format='NETCDF4_CLASSIC',
                engine='netcdf4',
                encoding=encodings,
                unlimited_dims=['time']
            )
            sphum.close()
            
        #elif 'total_rain_rate' not in f and 'specific_humidity' not in f:
        else:
            ds=xr.open_dataset(str(rawdir + f + '_' + str(y) + ".nc")).sel(latitude=slice(lati,latf), longitude=slice(loni,lonf))
            ds.to_netcdf(str(outdir + f + '_' + str(y) + ".nc"),format="NETCDF4_CLASSIC")
            ds.close()
