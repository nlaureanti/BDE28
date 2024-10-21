#!/home/nicole.laureanti/miniconda3/envs/obcic/bin/python

from glob import glob
from subprocess import run
from os import path
import xarray
from boundary import Segment
import os
import numpy

#import depths

# xarray gives a lot of unnecessary warnings
import warnings
warnings.filterwarnings('ignore')


def write_year(year, glorys_dir, segments, is_first_year=False):
    glorys = (
        xarray.open_mfdataset(sorted(glob(os.path.join(glorys_dir, f'{year}/glorys_{year}*.nc'))))
        .rename({'latitude': 'lat', 'longitude': 'lon', 'depth': 'z'})
#       .rename({'latitude': 'lat', 'longitude': 'lon'})
    )


    # Floor first time down to midnight so that it matches initial conditions
    if is_first_year:
       glorys.time.data[0] = numpy.datetime64(f'{year}-01-01T00:00:00.000000000')
    datef=numpy.datetime64(f'{year}-03-01T00:00:00.000000000')
    glorys=glorys.sel(time=slice(date,datef))

#    print('intep vertically (new!)')
#    glorys = glorys.interp(depth=ztarget, kwargs={'fill_value': 'extrapolate'}).ffill('z', limit=None)   

    for seg in segments:
        seg.regrid_velocity(glorys['uo'], glorys['vo'], suffix=year, flood=False)
        for tr in ['thetao', 'so']:
            seg.regrid_tracer(glorys[tr], suffix=year, flood=False)
        seg.regrid_tracer(glorys['zos'], suffix=year, flood=False)


# this is an xarray based way to concatenate the obc yearly files into one file (per variable of output)
# the former way to do this was based on ncrcat from NCO tools
def ncrcat_rename(nsegments, ncrcat_outdir,output_dir, delete_old_files=False):
    rename_dict={'thetao':'temp', 'so':'salt', 'zos':'zeta', 'uv':'uv'}
    for var in ['thetao', 'so', 'zos', 'uv']:
        for seg in range(1, nsegments+1):
            comb = xarray.open_mfdataset(f'{output_dir}{var}_00{seg}_*')
            if var!='uv':
                comb=comb.rename({f'{var}_segment_00{seg}':f'{rename_dict[var]}_segment_00{seg}'})
                if var!='zos':
                    comb=comb.rename({f'dz_{var}_segment_00{seg}':f'dz_{rename_dict[var]}_segment_00{seg}'})
            # Fix output metadata, including removing all _FillValues.
            all_vars = list(comb.data_vars.keys()) + list(comb.coords.keys())
            #encodings = {v: {'_FillValue': 1.0e20} for v in all_vars}
            #encodings['time'].update({'dtype':'float64', 'calendar': 'gregorian'})
            encodings = {'time': dict()}
            encodings['time'].update({'dtype':'float64', 'calendar': 'gregorian'})
            year1 = str(comb.time.values[2])[0:4]
            year_end = str(comb.time.values[-2])[0:4]
            print(year1,year_end)
            comb.to_netcdf(f'{ncrcat_outdir}{rename_dict[var]}_00{seg}.nc',
                           encoding=encodings,
                           unlimited_dims='time',
                           format='NETCDF3_64BIT')
            print(f'concatenated and renamed {rename_dict[var]}_00{seg}.nc')
            del(comb)
            if delete_old_files==True:
                os.remove(f'{output_dir}{var}_00{seg}_*')
def main():
    first_year = 1997

    #nicole
    glorys_dir = '/scratch/servicos/inpe2//nicole.laureanti/data/glorys/'
    output_dir = '/scratch/servicos/inpe2//nicole.laureanti/BDE28/boundary/'
    ncrcat_outdir = '/scratch/servicos/inpe2//nicole.laureanti/BDE28/boundary_final/'
    hgrid = xarray.open_dataset('/scratch/servicos/inpe2//nicole.laureanti/BDE28/grid/ocean_hgrid.nc')

#    vgrid_file = '/Volumes/A1/workdir/nicole/SWA14/vgrid/vgrid_75_2m.nc' #(new!)
#    vgrid=vgrid = xarray.open_dataarray(vgrid_file)
#    z = depths.vgrid_to_layers(vgrid)
#    global ztarget
#    ztarget = xarray.DataArray(
#        z,
#        name='z',
#        dims=['z'],
#        coords={'z': z},
#    )

    segments = [
        Segment(1, 'north', hgrid, output_dir=output_dir),
        Segment(2, 'south', hgrid, output_dir=output_dir),
        Segment(3, 'east', hgrid, output_dir=output_dir)
    ]
    global date
    import numpy as np
    date=np.datetime64('2022-01-01')
    for y in range(2022, 2023):
        print(y)
        write_year(y, glorys_dir, segments, is_first_year=y==first_year)
    
    # Nicole
    output_dir = '/scratch/servicos/inpe2//nicole.laureanti/BDE28/boundary/'
    ncrcat_outdir = '/scratch/servicos/inpe2//nicole.laureanti/BDE28/boundary_final/'
    #ncrcat_rename(3, ncrcat_outdir, output_dir)



if __name__ == '__main__':
    main()

