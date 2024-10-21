#Pad ERA5 Forcing file using Climate Data Operator (CDO) Mergetime
# using cdo
import xarray as xr
import os
import cftime
import numpy as np

datadir='/glade/scratch/jsimkins/ERA5/original/'
outdir='/glade/scratch/jsimkins/ERA5/padded/'
year=1996
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

for f in era5_dict.keys():
    # grab previous 2 timestamps and next 2 timestamps. We need 2 timestamps so time is stored as a dimension for each variable. This enables CDO mergetime to work properly.
    previous = xr.open_dataset(f"{datadir}/{f}_{year-1}.nc", decode_times=False).isel(time=slice(-3,-1))
    next_data = xr.open_dataset(f"{datadir}/{f}_{year+1}.nc", decode_times=False).isel(time=slice(0,2))

    previous.to_netcdf(f'{outdir}/prev.nc', format="NETCDF4",unlimited_dims='time')
    next_data.to_netcdf(f'{outdir}/next.nc', format="NETCDF4",unlimited_dims='time')
    previous.close()
    next_data.close()

    # make a system call to use CDO mergetime to concatenate our data
    os.system(str("cdo -b F32 -f nc4c mergetime " + outdir + "prev.nc " + datadir + f + "_" + str(year) + ".nc " + outdir + "next.nc " + outdir + f))


