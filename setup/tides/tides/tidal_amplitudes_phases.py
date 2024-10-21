#!/Volumes/A1/workdir/nicole/envs/xesmf_env_test/bin/python




def main():
    # # Load TPXO data and MOM6 grid

    # In[5]:


    tpxo_h = xr.open_dataset("~/workdir/TIDES/h_tpxo9.v5a.nc").isel(nc=slice(0,10))
    tpxo_u = xr.open_dataset("~/workdir/TIDES/u_tpxo9.v5a.nc").isel(nc=slice(0,10))
    tpxo_grid = xr.open_dataset("~/workdir/TIDES/gridtpxo9v5a.nc")

    hgrid = xr.open_dataset("/home/nicole/workdir/SWA14/grid/ocean_hgrid.nc")
    
    print("lon", hgrid["x"].min().values, hgrid["x"].max().values)
    print("lat", hgrid["y"].min().values, hgrid["y"].max().values)


    # Define the segments for remapping

    # northern boundary
    north = xr.Dataset()
    north['lon'] = hgrid['x'].isel(nyp=-1)
    north['lat'] = hgrid['y'].isel(nyp=-1)

    # southern boundary
    south = xr.Dataset()
    south['lon'] = hgrid['x'].isel(nyp=0)
    south['lat'] = hgrid['y'].isel(nyp=0)

    # eastern boundary
    east = xr.Dataset()
    east['lon'] = hgrid['x'].isel(nxp=-1)
    east['lat'] = hgrid['y'].isel(nxp=-1)

    segments={'north':north, 'south':south, 'east':east}


    # ### Clean up the raw data from TPXO and make it xarray-friendly
    tpxo_h["lon"] = tpxo_grid["lon_z"]
    tpxo_h["lat"] = tpxo_grid["lat_z"]
    tpxo_h["mask"] = tpxo_grid["mz"]
    tpxo_h = tpxo_h.transpose(*("nc", "ny", "nx"))
    tpxo_h = tpxo_h.set_coords(["lon", "lat"])

    tpxo_u["lon"] = tpxo_grid["lon_u"]
    tpxo_u["lat"] = tpxo_grid["lat_u"]
    tpxo_u["mask"] = tpxo_grid["mu"]
    tpxo_u = tpxo_u.transpose(*("nc", "ny", "nx"))
    tpxo_u = tpxo_u.set_coords(["lon", "lat"])


    tpxo_h["ha"].isel(nc=0).where(tpxo_h["mask"] != 0.).plot(x="lon", y="lat")
    plt.savefig('tpxo_ha.png')
    tpxo_u["ua"].isel(nc=0).where(tpxo_u["mask"] != 0.).plot(x="lon", y="lat")
    plt.savefig('tpxo_ua.png')
    tpxo_u["va"].isel(nc=0).where(tpxo_u["mask"] != 0.).plot(x='lon',y='lat')
    plt.savefig('tpxo_va.png')

    # ### Subset to regional domain for compute efficiency

    horizontal_subset = dict(nx=slice(1700,2200), ny=slice(100,600)) #select the domain

    plt.cla();plt.clf()
    plt.figure(figsize=[12,12])
    ax=plt.axes()
    tpxo_h["ha"].where(tpxo_h["mask"] != 0.).sel(**horizontal_subset).isel(nc=0).plot(ax=ax,cmap='brg')
    plt.savefig('tpxo_ha_set.png')

    plt.figure(figsize=[12,12])
    ax=plt.axes()
    (tpxo_u["ua"]*1e-2).where(tpxo_u["mask"] != 0.).sel(**horizontal_subset).isel(nc=0).plot(ax=ax,cmap='brg')
    plt.savefig('tpxo_ua_set.png')

    ### 
    plt.figure(figsize=[12,12])
    ax = plt.axes()
    tpxo_h["hp"].where(tpxo_h["mask"] != 0.).sel( **horizontal_subset ).isel(nc=0).plot(ax = ax, cmap="hsv", x="lon", y="lat")
    ax.plot(north["lon"]+360, north["lat"], "k.")
    ax.plot(south["lon"]+360, south["lat"], "k.")
    ax.plot(east["lon"]+360, east["lat"], "k.")
    plt.savefig('tpxo_hphase_set.png')

    plt.figure(figsize=[12,12])
    ax = plt.axes()
    tpxo_u["up"].where(tpxo_u["mask"] != 0.).sel(**horizontal_subset).isel(nc=0).plot(ax=ax,    cmap="hsv", x="lon", y="lat")
    ax.plot(north["lon"]+360, north["lat"], "k.")
    ax.plot(south["lon"]+360, south["lat"], "k.")
    ax.plot(east["lon"]+360, east["lat"], "k.")
    plt.savefig('tpxo_uphase_set.png')


    tpxo_h_reg = tpxo_h.sel(**horizontal_subset)
    tpxo_u_reg = tpxo_u.sel(**horizontal_subset)


    # # Remap TPXO to various segments:


    regrid_north = xesmf.Regridder(tpxo_h_reg, north, 'bilinear', 
                                   locstream_out=True, periodic=False)

    regrid_south = xesmf.Regridder(tpxo_h_reg, south, 'bilinear', 
                                   locstream_out=True, periodic=False)

    regrid_east = xesmf.Regridder(tpxo_h_reg, east, 'bilinear', 
                                   locstream_out=True, periodic=False)



    # Dictionaries: practical use


    regrid={}; amplitude={}; phase={}; v_amplitude={}; u_amplitude={} ; u_phase ={} ; v_phase={}
    for b in segments:
        regrid[b] = xesmf.Regridder(tpxo_h_reg, segments[b], 'bilinear', 
                                   locstream_out=True, periodic=False)

        amplitude[b] = regrid[b](tpxo_h_reg["ha"])
        phase[b] = regrid[b](tpxo_h_reg["hp"])
        
        v_amplitude[b] = regrid[b](tpxo_u_reg["va"])
        v_phase[b] = regrid[b](tpxo_u_reg["vp"])
        
        u_amplitude[b] = regrid[b](tpxo_u_reg["ua"])
        u_phase[b] = regrid[b](tpxo_u_reg["up"])    

    for b in segments:
        u_phase[b] = np.radians(u_phase[b])
        v_phase[b] = np.radians(v_phase[b])
        phase[b] = np.radians(phase[b])
    # ## Prepare to create output


    for b in segments:
        amplitude[b].isel(nc=0).plot(size=6,label=b)
        plt.legend()
        plt.savefig(f'ha_{b}.png')
        phase[b].isel(nc=0).plot(size=6,label=b)
        plt.legend()
        plt.savefig(f'hp_{b}.png')
        (v_amplitude[b].isel(nc=0)*1e-2).plot(size=6,label=b)
        plt.legend()
        plt.savefig(f'va_{b}.png')
        (u_amplitude[b].isel(nc=0)*1e-2).plot(size=6,label=b)
        plt.legend()
        plt.savefig(f'ua_{b}.png')
        u_phase[b].isel(nc=0).plot(size=6,label=b) 
        plt.legend()
        plt.savefig(f'up_{b}.png')
        v_phase[b].isel(nc=0).plot(size=6,label=b)
        plt.legend()
        plt.savefig(f'vp_{b}.png')


    # In[79]:


    suffix={ 'north':'segment_001','east':'segment_003','south':'segment_002'}
    susuffix={ 'north':'001','east':'003','south':'002'}
    nz=len(amplitude['north'].nc)
    ny=len(amplitude['north'].lat)
    nx=len(amplitude['north'].lon)

    time = xr.DataArray(
            pd.date_range('2001-01-01', periods=1),
            dims=['time']
        )

    # ## Fix coords: Add time, fix some names, transpose to make time unlimited, remove locations and use nx, ny.
    for b in segments:
        #dic_rnm={'nc':'constituent','lat':f'lat_{suffix[b]}','lon':f'lon_{suffix[b]}'}
        dic_rnm={'nc':'constituent'}
        u_amplitude[b] , _ = xr.broadcast(u_amplitude[b]*10e-2, time)
        u_amplitude[b] = u_amplitude[b].rename(dic_rnm).transpose('time', 'constituent', 'locations')
        u_amplitude[b] = expand_dims(b,u_amplitude[b],suffix[b])
        u_amplitude[b] = rename_dims(b,u_amplitude[b],suffix[b])

        v_amplitude[b], _ = xr.broadcast(v_amplitude[b]*10e-2, time)
        v_amplitude[b] = v_amplitude[b].rename(dic_rnm).transpose('time', 'constituent', 'locations')
        v_amplitude[b] = expand_dims(b,v_amplitude[b],suffix[b])
        v_amplitude[b] = rename_dims(b,v_amplitude[b],suffix[b])

        u_phase[b], _ = xr.broadcast(u_phase[b], time)
        u_phase[b] = u_phase[b].rename(dic_rnm).transpose('time', 'constituent', 'locations')
        u_phase[b] = expand_dims(b,u_phase[b],suffix[b])
        u_phase[b] = rename_dims(b,u_phase[b],suffix[b])

        v_phase[b], _ = xr.broadcast(v_phase[b], time)
        v_phase[b] = v_phase[b].rename(dic_rnm).transpose('time', 'constituent', 'locations')
        v_phase[b] = expand_dims(b,v_phase[b],suffix[b])
        v_phase[b] = rename_dims(b,v_phase[b],suffix[b])

        amplitude[b], _ = xr.broadcast(amplitude[b], time)
        amplitude[b] = amplitude[b].rename(dic_rnm).transpose('time', 'constituent', 'locations')
        amplitude[b] = expand_dims(b,amplitude[b],suffix[b])
        amplitude[b] = rename_dims(b,amplitude[b],suffix[b]) 

        phase[b], _ = xr.broadcast(phase[b], time)
        phase[b] = phase[b].rename(dic_rnm).transpose('time', 'constituent', 'locations')
        phase[b] = expand_dims(b,phase[b],suffix[b])
        phase[b] = rename_dims(b,phase[b],suffix[b])

    print(amplitude[b])

    print('to_netcdf')
    for b in segments:
        u_dvars = { f'uamp_{suffix[b]}':u_amplitude[b], f'vamp_{suffix[b]}':v_amplitude[b],
                               f'uphase_{suffix[b]}':u_phase[b], f'vphase_{suffix[b]}':v_phase[b]}
        h_dvars = { f'zamp_{suffix[b]}':amplitude[b], f'zphase_{suffix[b]}': phase[b]}
        
        ds_h = xr.Dataset(h_dvars) 
        ds_u = xr.Dataset(u_dvars)
    
        write_obc(ds_u, f"tu{susuffix[b]}.nc")
        write_obc(ds_h, f"tz{susuffix[b]}.nc")

        print('done')


#========================================================================    
def write_obc(ds_, fname='obc_teste.nc', fill_value=1e20):
    import numpy as np
    print(f'writing to {fname}')
    view_results=False
    if view_results:
        print(ds_)
    for v in ds_:
        ds_[v].encoding['_FillValue']=fill_value
        ds_[v].encoding['dtype']=np.float64
        ds_[v].encoding['missing_value']=fill_value        
    for v in ds_.coords:
        ds_[v].encoding['_FillValue']=fill_value
        ds_[v].encoding['missing_value']=fill_value
        ds_[v].encoding['dtype']=np.float64
        if v not in ['time','Time']:
                ds_[v].attrs = get_attrs(v)
    
    ds_.attrs = get_attrs('title')

    encoding = {}
    encoding['time'] = get_attrs('time')    
    encoding.update({'time': dict(dtype=np.float64, _FillValue=1.0e20)})
#    ds_['time'].encoding = encoding
#    ds_['time'].encoding = get_attrs('time')
#    ds_['time'].attrs['modulo'] = ' '

    ds_.to_netcdf( fname , unlimited_dims=('time'),format='NETCDF3_64BIT', engine='netcdf4', encoding=encoding )
    print(f'>{fname} saved')    
    
    return None

def rename_dims(border, ds, segstr):
        """Rename dimensions to be unique to the segment.

        Args:
            ds (xarray.Dataset): Dataset that might contain 'lon', 'lat', 'z', and/or 'locations'.

        Returns:
            xarray.Dataset: Dataset with dimensions renamed to include the segment identifier and to 
                match MOM6 expectations.
        """
        ds = ds.rename({
            'lon': f'lon_{segstr}',
            'lat': f'lat_{segstr}'
        })
        if 'z' in ds.coords:
            ds = ds.rename({
                'z': f'nz_{segstr}'
            })
        if border in ['south', 'north']:
            return ds.rename({'locations': f'nx_{segstr}'})
        elif border in ['west', 'east']:
            return ds.rename({'locations': f'ny_{segstr}'})
def expand_dims(border, ds, segstr):
        """Add a length-1 dimension to the variables in a boundary dataset or array.
        Named 'ny_segment_{self.segstr}' if the border runs west to east (a south or north boundary),
        or 'nx_segment_{self.segstr}' if the border runs north to south (an east or west boundary).

        Args:
            ds: boundary array with dimensions <time, (z or constituent), y, x>

        Returns:
            modified array with new length-1 dimension.
        """
        # having z or constituent as second dimension is optional, so offset determines where to place
        # added dim
        if 'z' in ds.coords or 'constituent' in ds.dims:
            offset = 0
        else:
            offset = 1
        if border in ['south', 'north']:
            return ds.expand_dims(f'ny_{segstr}', 2-offset)
        elif border in ['west', 'east']:
            return ds.expand_dims(f'nx_{segstr}', 3-offset)
#=============================================================================
def get_attrs(var):                
     if var in ['ssh','SSH','zos']:
        attrs = {    'units' : "meter", 'long_name' : "effective sea level (eta_t + patm/(rho0*g)) on T cells" }
     elif var in ['temp','thetao']:
        attrs = {    'units' : "degrees C",'long_name' : "Potential temperature" }
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
                'calendar' : "gregorian",  
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

if __name__ == "__main__":
        import xarray as xr
        import xesmf
        import matplotlib.pyplot as plt
        import pandas as pd
        import numpy as np      
        import warnings
    
        warnings.filterwarnings("ignore")
        main()



