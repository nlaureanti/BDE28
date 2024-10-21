#!/home/nicole.laureanti/miniconda3/envs/obcic/bin/python

"""

    Scrip para converter arquivos de grade regional para binário/ctl.
    Inputs: arquivo netcdf
    Desenvolvido por Nicole C. Laureanti
    nlaureanti@gmail.com
    
"""
#=================================================================================================================
#=================================================================================================================
def main():
    import sys, os
    import matplotlib.pyplot as plt
    import numpy as np 
    import pandas as pd
    np.set_printoptions(suppress=True) #prevent numpy exponential 
                                   #notation on print, default False


    if(len(sys.argv)<1):
	    print(f"uso: {sys.argv[0]} <arquivo> <var>*")
	    print(f'fornecido: {sys.argv} \n\n', '------\t'*10)
	    quit()
    else:
	    print(f"uso: {sys.argv}\n",'------\t'*13)

    tctl='01jan1900'
    time_values=pd.date_range("1900-01-01", freq="d", periods=1)
    undef=1e20
    selvar='grade'
    var=None

    if len(sys.argv) >2:
	    var=sys.argv[2]
    dirout='./'
    file_preffix=dirout+os.path.basename(sys.argv[1]).replace('.nc','_regular.nc')
    print(sys.argv[1])
    if "ocean_hgrid" in sys.argv[1] :         
        regional_grid=open_grid(sys.argv[1],var=var) # com ocean_hgrid.nc
        ocean_hgrid=True
        print(f"ocean_hgrid? {ocean_hgrid}")
    else:
        regional_grid=xr.open_dataset(sys.argv[1])
        ocean_hgrid=False
        print(f"ocean_hgrid? {ocean_hgrid}")        
        if 'lat' not in regional_grid.dims or 'lon' not in regional_grid.dims:
            for (x,y) in [('longitude','latitude'),('xh','yh'),('xt_ocean','yt_ocean'),('nx','ny')]:
                    try:
                        regional_grid=regional_grid.rename({x:'x',y:'y'})
                        break
                    except:
                        pass

    print('------\t'*13,regional_grid)
    if ocean_hgrid==True:
            p = np.empty(( len(time_values),
			len(regional_grid.y.values[:,0]),
                        len(regional_grid.x.values[0]) ))
            p[:] = undef
            print(p.shape)
            v = xr.DataArray( p, name = selvar,
                         dims = ("time","lat","lon") ,
                         coords = { "time" : time_values[:],
                                     'lat' : regional_grid.y.values[:,0],
                                     'lon' : regional_grid.x.values[0] }) 
         
    v.to_netcdf(file_preffix)
    write_obc(v,fname=file_preffix)
    print(file_preffix,'\n', '------\t'*13)

#========================================================================
def write_obc(da, dadz=None, varname=None, fname='obc_teste.nc', fill_value=1e20):
    #not used
    print(f'writing {varname} to {fname}')
    ds_=da.assign_coords({'lat':da['lat'].data,'lon':da['lon']}).to_dataset(name=varname)
    if dadz is not None:
        ds_['dz_'+varname]=dadz
    for v in ds_:
        ds_[v].encoding['_FillValue']=fill_value
        ds_[v].encoding['dtype']=np.float32
    for v in ds_.coords:
        ds_[v]=xr.DataArray(ds_[v].data, dims=[v], coords= {v:(v,ds_[v].data)})
        ds_[v].encoding['_FillValue']=fill_value
        ds_[v].encoding['dtype']=np.float32
    if varname in ['uo','u']:
        xstr,ystr='lonq','lath'
    elif varname in ['vo','v']:
        xstr,ystr='lonh','latq'
    else:
        xstr,ystr='lonh','lath'
    ds_=ds_.rename({'lon':xstr,'lat':ystr})
    ds_[xstr].attrs={'standard_name':"longitude",
                        'long_name' : "geographic_longitude",
                        'axis' : "X",
                        'cartesian_axis' : "X",
                        'units' : "degrees_east"}
    ds_[ystr].attrs={'standard_name' : "latitude",
                            'long_name' : "geographic_latitude",
                            'axis' : "Y",
                            'cartesian_axis' : "Y",
                            'units' : "degrees_north"}

    if varname is not None:
           if 'ssh' not in varname:
              ds_.lev.attrs={'axis' : "Z", 'cartesian_axis' : "Z",
                       'positive' : "down", 'units' : "m", 'long_name' : "Layer pseudo-depth -z*"}

    ds_.to_netcdf( fname,unlimited_dims=('time')  )
    print(f'>{fname} saved')

#========================================================================
def open_grid(path,decode_times=False,var=None):
    
    """Return a grid object containing staggered grid locations"""
    grid={}
    grid['ds']=xr.open_dataset(path,decode_times=False)
    grid['ds']=grid['ds'].drop_dims(['ny','nx'])
    grid['ds']=grid['ds'].drop_vars(['tile'])
    for (x,y) in [('nxp','nyp'),('nxp1','nyp1')]:
       try:
        grid[x]=grid['ds'][y].data[-1]+1
        grid[y]=grid['ds'][x].data[-1]+1
        nxp=grid[x];nyp=grid[y]
        grid['h'] = grid['ds'].isel({x:slice(1,None,2),y:slice(1,None,2)})
        #The q grid is not symmetric, but Cu and Cv are
        grid['q'] = grid['ds'].isel({x:slice(2,None,2),y:slice(2,None,2)})
        grid['Cu'] = grid['ds'].isel({x:slice(0,None,2),y:slice(1,None,2)})
        grid['Cv'] = grid['ds'].isel({x:slice(1,None,2),y:slice(0,None,2)})
        break
       except:
        pass

    if var in ['u','uo']:
        grid=grid['Cu']
    elif var in ['v','vo']:
        grid=grid['Cv']
    else:
        grid=grid['h']

    return grid

if __name__ == "__main__":
    import xarray as xr
    import numpy as np
    main()



