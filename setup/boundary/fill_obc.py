#!/Volumes/A1/workdir/nicole/bin/python
def main():
        dir='/home/nicole/workdir/SWA14/boundary_final/'
        print(f'{dir}')
        files=os.listdir(f'{dir}')
        print(files)

        for f in files:
            print(f'{dir}{f}')
            a=xr.open_dataset(f'{dir}{f}')
            n=f.split('_')[1].split('.')[0]
            print(n)
            try:
                nz=len(a[f'nz_segment_{n}'].data)
                lev=True
            except:
                lev=False
                pass
            nx=len(a[f'nx_segment_{n}'].data)
            ny=len(a[f'ny_segment_{n}'].data)

            #a=a.isel(time=slice(0,60))

            for v in a.keys():
                print(v)
                if lev:
                        if nx > ny:
                                a=fill_obc(a,dim=[f'nx_segment_{n}'],fill='f')
                        else:
                                a=fill_obc(a,dim=[f'ny_segment_{n}'],fill='f')
                else:        
                        if nx > ny:
                                a=fill_obc(a,dim=[f'nx_segment_{n}'],fill='f')
                        else:
                                a=fill_obc(a,dim=[f'ny_segment_{n}'],fill='f')                
                
            #a.to_netcdf(f'{dir}/fix/{f}')
            write_obc(a,f'{dir}/fix/{f}')
        print('done')
        quit()
#=============================================================================
def get_attrs(var):
                  
     if var in ['ssh','SSH','zos']:
        attrs = {    'units' : "meter", 'long_name' : "effective sea level (eta_t + patm/(rho0*g)) on T cells" }
     elif var in ['temp','thetao']:
        attrs = {    'units' : "degrees C",'long_name' : "Potential thetaoerature" }
     elif var in [ 'salt', 'so']:
        attrs = {    'units' : "psu", 'long_name' : "Practical Salinity" } 
     elif var in ['u', 'uo']:
        attrs =  {    'units' : "m s-1",  'long_name' : "Barotropic-step Averaged Zonal Velocity" }
     elif var in [ 'v' , 'vo']:
        attrs =  {    'units' : "m s-1", 'long_name' : "Barotropic-step Averaged Zonal Velocity" }
     elif var in [ 'dz' ]:
        attrs = {    'units' : "meter" ,'long_name' : "Layer thicknesses"}
     elif var in ['diff']:
        attrs = { 'units' : "1/s", 'long_name' : "Part of vorticity" }
     elif var in ['lon'] :
        attrs = {'standard_name':"longitude",
                            'long_name' : "q point nominal longitude",
                            'axis' : "X",
                            'cartesian_axis' : "X",
                            'units' : "degrees"}  
     elif var in ['lat']:
        attrs = {'standard_name' : "latitude",
                                'long_name' : "h point nominal latitude",
                                'axis' : "Y",
                                'cartesian_axis' : "Y",
                                'units' : "degrees"}
     elif var in ['lev', 'depth', 'zl']:
        attrs={'axis' : "Z", 'cartesian_axis' : "Z",
                       'positive' : "down", 'units' : "meter", 'long_name' : "zstar depth"}
     elif var in ['Time', 'time']:
        attrs = { "units":'days since 1900-01-01 00:00:00', 
                'calendar' : "gregorian",  'modulo' : " ",
                'axis' : "T"}
     elif var in ['title']:                           
        attrs = {'title':"remap_obc_from_glorys_to_MOM6 v3 output file",
                "references":""""Nicole C. Laureanti (INPE/BR) nlaureanti@gmail.com
                    More examples: https://github.com/ESMG/regionalMOM6_notebooks/blob/master/creating_obc_input_files/panArctic_OBC_from_global_MOM6.ipynb""",
                "source": "Glorys" }
     else:
        attrs = {'standard_name' : "null",
                                'long_name' : "null",
                                'units' : "null"} 
     return attrs
#========================================================================    
def write_obc(ds_, fname='obc_teste.nc', fill_value=1e20):
    print(f'writing to {fname}')
    view_results=False
    if view_results:
        print(ds_)
    for v in ds_:
        ds_[v].encoding['_FillValue']=fill_value
        if 'dudy' in v  or 'dvdx' in v :
            ds_[v].encoding['dtype']=np.float64
        else:
            ds_[v].encoding['dtype']=np.float32            
        ds_[v].encoding['missing_value']=fill_value        
    for v in ds_.coords:
        ds_[v].encoding['_FillValue']=fill_value
        ds_[v].encoding['missing_value']=fill_value
        ds_[v].encoding['dtype']=np.float32
        if v not in ['time','Time']:
                ds_[v].attrs = get_attrs(v)
    
    ds_.attrs = get_attrs('title')   
    
    ds_['time'].encoding = get_attrs('time')

    ds_.to_netcdf( fname , unlimited_dims=('time')  )
    print(f'>{fname} saved')    
    
    return None
#=============================================================================                        
def fill_obc(ds_,dim=['lon','lat'], fill='b', fill_depth = 'f'):                        

    ds_fill = xr.Dataset()
    for v in ds_.keys():
        print('*~ filling xy ', v)
        for coord in dim:
            if fill == 'b':
                ds_fill[v] = ds_[v].bfill(coord)
            elif fill == 'f':
                ds_fill[v] = ds_[v].ffill(coord)       
        
             
        for coordz in ["lev","lev_2","z_l","depth"]:
            try:
                if fill_depth == 'b':
                     ds_fill[v] = ds_fill[v].bfill(coordz)
                elif fill_depth == 'f':
                     ds_fill[v] = ds_fill[v].ffill(coordz)	
            except:               
                pass


                     
    if len(ds_fill.dims) == 0:
        print(f"coords not found in {ds_.dims}") 
#            
    return ds_fill
     
#=============================================================================                        
def fill_obc2d(ds_,dim=['lon','lat'], fill='b'):                        

    ds_fill = xr.Dataset()
    for v in ds_.keys():
        print('*~ filling xy ', v)
        for coord in dim:
            if fill == 'b':
                ds_fill[v] = ds_[v].bfill(coord)
            elif fill == 'f':
                ds_fill[v] = ds_[v].ffill(coord) 
                     
    if len(ds_fill.dims) == 0:
        print(f"coords not found in {ds_.dims}") 
#            
    return ds_fill                   
            
import xarray as xr
import matplotlib.pyplot as plt
import os
import numpy as np

main()
