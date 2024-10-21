#!/Volumes/A1/workdir/nicole/envs/xesmf_env_test/bin/python

"""

    Scrip para remapear as condições de fronteira do SODA para o MOM6
    Inputs: arquivo netcdf
    Desenvolvido por Nicole C. Laureanti
    Baseado em: https://github.com/ESMG/regionalMOM6_notebooks/blob/master/creating_obc_input_files/panArctic_OBC_from_global_MOM6.ipynb
    nlaureanti@gmail.com
    
"""
#=================================================================================================================
#=================================================================================================================
def main():
    view_results=False

    var, ds_grid, depth_vector, ds_var, uv, fnt  = get_args(sys.argv)
                        
    if view_results:
        print(ds_var)
    fill_value=1.e20

    #verify coords
    xh=ds_grid.x[0,:][1::2] #igual a ds_grid.x[0,xpoints]
    yh=ds_grid.y[:,0][1::2] #igual a ds_grid.y[ypoints,0]       
    xq=ds_grid.x[0][0::2]
    yq=ds_grid.y[:,0][0::2]
    
    time=ds_var.time
    nt=len(ds_var.time)
    if var not in ['zos','ssh','SSH']:
        lev=ds_var.lev
        nz=len(ds_var.lev)


    #select xy grid    
    if var == 'vo':
        nlat=len(yq)*2; lon=xh; nlon=len(xh)*2
        xpoints=slice(1,nlon+1,2)  ; ypoints=slice(0,nlat+1,2)
    elif var =='uo':    
        nlat=len(yh)*2; lon=xq; nlon=len(xq)*2
        xpoints=slice(0,nlon+1,2)  ; ypoints=slice(1,nlat+1,2)              
    else:
        nlat=len(yh)*2; lon=xh; nlon=len(xh)*2
        xpoints=slice(1,nlon+1,2)  ; ypoints=slice(1,nlat+1,2)               
  
    lat_str='lat' ; lon_str='lon' 
    supergrid=True #não funciona no notebook
    if supergrid:     
        lon=ds_grid.x[0,:]    #igual a ds_grid.x[0,xpoints]
        lat=ds_grid.y[:,0]    #igual a ds_grid.x[0,xpoints] 
        xpoints=slice(0,nlon+1,1)  ; ypoints=slice(0,nlat+2,1)
        xpointsq=slice(0,nlon+1,1)  ; ypointsq=slice(0,nlat+1,1)                 
    else:
        lon=ds_grid.x[0,xpoints]    #igual a ds_grid.x[0,xpoints]
        lat=ds_grid.y[ypoints,0]    #igual a ds_grid.x[0,xpoints]
        xpointsq=slice(0,nlon+1,2)  ; ypointsq=slice(0,nlat+1,2) 
 
        
    if var not in ['zos','ssh','SSH']:        
         coord_obc={'north': {'time':time, 'lev':lev.data, lon_str:lon.data,lat_str:[lat.data[-1]]  }
    , 'east' : {'time':time, 'lev':lev.data, lat_str: lat.data,      lon_str:[lon.data[-1]]}
    , 'south': {'time':time, 'lev':lev.data, lat_str:[lat.data[0]],  lon_str:lon.data } }       
         coord_obc_dz={'north': {'time':time, 'lev':lev.data, lat_str:[lat.data[-1]], lon_str:lon.data}
             , 'east' : {'time':time, 'lev':lev.data, lat_str: lat.data, lon_str:[xh.data[-1]]}
             , 'south': {'time':time, 'lev':lev.data, lat_str:[lat.data[0]],  lon_str:lon.data } }                             
    else:
         coord_obc={'north': {'time':time, lon_str:lon.data, lat_str:[lat.data[-1]] }
    , 'east' : {'time':time, lat_str: lat.data, lon_str:[lon.data[-1]]}
    , 'south': {'time':time, lat_str:[lat.data[0]], lon_str:lon.data } }      
         nz=0 

    
    suffix={ 'north':'segment_001','east':'segment_003','south':'segment_002'}
    print('-----'*10)
    print('MAX '*5,f'LON {np.max(ds_grid.x.data)} LAT {np.max(ds_grid.y).data}')
    print('MIN '*5,f'LON {np.min(ds_grid.x.data)} LAT {np.min(ds_grid.y).data}')                       
    print('-----'*10)
    print('MAX '*5,f'LON {np.max(lon).data} LAT {np.max(lat).data}')
    print('MIN '*5,f'LON {np.min(lon).data} LAT {np.min(lat).data}')    
    print('LEN '*5,f'{lon_str} {len(lon)} {lat_str} {len(lat)}')        
    print('-----'*10)  
    #quit()
    sel_slice, dim, fill, shape_dz, shape_rgd, coord_rgd = segment_defaults(fnt, nt, lat, lon, nz, lat_str, lon_str)
    
    if var in ['temp','thetao','so','salt','ssh','SSH','zos']:
       strvar='h'
    else:
       strvar=var

    #creating dz
    print(f'*~ creating dz')
    if not os.path.isfile(f'dz_{fnt}_{strvar}.nc') and var not in ['zos','ssh','SSH']:    
	    use_depth_to_limit=False
	    if use_depth_to_limit:
	        print('use_depth_to_limit')
        	dz=np.zeros((len(lev.data),len(lat),len(lon))).isel(sel_slice)
	        nk = 50         # number of levels
	        Htot=5500       # deepest ocean point
	        Huniform = 0    # upper region of uniform resolution
	        dzTop = 5       # thickness of top level
	        fnPow = 1.42865 # ???
	        prec = .01      # precision to round thicknesses/depths todz = dzIter(nk, Htot, dzTop, Huniform, fnPow, prec)
	        for kx in range(len(depth_vector[0,:])):
	            for ky in range(len(depth_vector[:,0])):
	                dz[:,ky,kx] = dzIter(nk, depth_vector[ky,kx], dzTop, Huniform, fnPow,  prec)           
	        dz=np.tile(dz[np.newaxis,:,:,:],(nt, 1, 1, 1))        
	    else:
                dz=create_dz(lev.data,np.max(lev.data))
                #dz=np.tile(dz[np.newaxis,:,np.newaxis,np.newaxis],(nt,1, len(lat.data), len(lon.data)))
                dz=np.tile(dz[np.newaxis,:,np.newaxis,np.newaxis],shape_dz)
	    da_dz=xr.DataArray(dz,coords=coord_obc_dz[fnt], name='dz').isel(sel_slice).mean(dim)
	    da_dz.attrs=get_attrs('dz')
	    da_dz[fill[0]].attrs=get_attrs(fill[0])
                                       
	    if view_results: 
        	print('dz >>>>>>>>>>>',da_dz.dims, da_dz.shape)               
	        da_dz[0,:,0,:].plot(figsize=(10,7))
	        plt.title(f"DZ cross-section {da_dz.dims[1]} vs {da_dz.dims[3]}")
	        plt.savefig(f'OBC_dz_{var}_C-Gridbilinearinterp.png')
	        plt.show()
	    for v in da_dz.coords:
	        da_dz[v].encoding['_FillValue']=fill_value
	        da_dz[v].encoding['missing_value']=fill_value
	        da_dz[v].encoding['dtype']=np.float32    
	    da_dz.to_netcdf(f'dz_{fnt}_{strvar}.nc') 
	    print(f'> dz_{fnt}_{strvar}.nc')                                       
    else:
	    da_dz=xr.open_dataset(f'dz_{fnt}_{strvar}.nc')['dz']
	    print(f'Using dz_{fnt}_{strvar}.nc')
   

    print('*~ regriding: ', var, fnt)
    #applying regrid

    da_regrid=xr.DataArray(np.zeros(shape_rgd), 
                coords=coord_rgd,name=var)
    print(da_regrid.shape,da_regrid.dims)
    regridder = xe.Regridder(ds_var, da_regrid, "bilinear", 
            periodic=False, 
            filename=f'regrid_{fnt}_{strvar}.nc',
            reuse_weights=True,locstream_out=False)
    da_regrid = regridder(ds_var)
    
    print(da_regrid.shape,da_regrid.dims)
    if view_results:
        try:
            ds_regrid.isel(time=0,lev=0).plot(figsize=(10,7))
        except:
            ds_regrid.isel(time=0).plot(figsize=(10,7))    
        plt.title(f"Surface {var} from SODA - Regional C-Grid bilinear interp")
        plt.savefig(f'OBC_{var}_C-Gridbilinearinterp.png')
        plt.show()

    #make the ds_out, add dz
    print('*~ working on obc:', fnt) 
    newvar=f"{var}_{suffix[fnt]}"  #var
    ds_ = xr.Dataset({ f"{var}_{suffix[fnt]}": 
		(da_regrid.isel(sel_slice).dims , da_regrid.isel(sel_slice).values )},
		coords=coord_obc[fnt])                 
    ds_[f'dz_{var}_{suffix[fnt]}']=da_dz
    ds_[f'dz_{var}_{suffix[fnt]}'].attrs=get_attrs('dz') 
    ds_[f"{var}_{suffix[fnt]}"].attrs=get_attrs(var)

    if uv:
	#make dudy dvdx
        if supergrid:
             dx,dy=get_dxdy(fnt,ds_grid,xpoints,ypoints,supergrid) 
        else:
             dx,dy=get_dxdy(fnt,ds_grid,xpointsq,ypointsq,supergrid)

          
        if var in ['uo','u']:
                #print(fnt, ds_[newvar].shape,' x  ',dy.shape)     
                if fnt == 'south':
                    dudy=(da_regrid[:,:,1,:]-da_regrid[:,:,0,:]) / dy.values
                    dudy=dudy.expand_dims((lat_str),axis=2).assign_coords({lat_str:[lat.data[0]]}).rename({'lon':lon_str})
                    ds_['dudy_'+suffix[fnt]] = xr.DataArray( dudy.values, coords={'time':time, 'lev':lev.data, lat_str:[lat.data[0]],   lon_str:lon.data})
                elif fnt == 'north':    
                    dudy=(da_regrid[:,:,-1,:]-da_regrid[:,:,-2,:])/ dy.values
                    dudy=dudy.expand_dims((lat_str),axis=2).assign_coords({lat_str:[lat.data[-1]]}).rename({'lon':lon_str})
                    ds_['dudy_'+suffix[fnt]] = xr.DataArray( dudy.values, coords={'time':time, 'lev':lev.data, lat_str:[lat.data[-1]],   lon_str:lon.data})
                elif fnt == 'east':
                    dudy=(da_regrid[:,:,1:,-1]-da_regrid[:,:,1:,-2]) / dy.values
                    dudy=dudy.expand_dims((lon_str),axis=3).assign_coords({lon_str:[lon.data[-1]]}).rename({'lat':lat_str})
                    ds_['dudy_'+suffix[fnt]] = xr.DataArray( dudy.values, coords={'time':time, 'lev':lev.data, lat_str:lat.data[1:], lon_str:[lon.data[-1]]})
                    
                if fnt in ['south', 'north','east']: 
                    print(dudy.dims,dudy.shape)
                    ds_['dudy_'+suffix[fnt]].attrs=get_attrs('diff')
                    ds_['dz_dudy_'+suffix[fnt]]=da_dz
                    ds_['dz_dudy_'+suffix[fnt]].attrs=get_attrs('dz')
          
        elif var in ['vo','v']:
                print(fnt, ds_[newvar].shape,' x  ',dx.shape)
                print(fnt, ds_[newvar].dims,' x  ',dx.dims)  
                if fnt == 'south':
                    dvdx=(da_regrid[:,:,1,1:]-da_regrid[:,:,0,1:]) / dx.values
                    dvdx=dvdx.expand_dims((lat_str),axis=2).assign_coords({lat_str:[lat.data[0]]}).rename({'lon':lon_str})
                    ds_['dvdx_'+suffix[fnt]] = xr.DataArray( dvdx.values, coords={'time':time, 'lev':lev.data, lat_str:[lat.data[0]],   lon_str:lon.data[1:]})
                elif fnt == 'north':    
                    dvdx=(da_regrid[:,:,-1,1:]-da_regrid[:,:,-2,1:]) / dx.values
                    dvdx=dvdx.expand_dims((lat_str),axis=2).assign_coords({lat_str:[lat.data[-1]]}).rename({'lon':lon_str})
                    ds_['dvdx_'+suffix[fnt]] = xr.DataArray( dvdx.values, coords={'time':time, 'lev':lev.data, lat_str:[lat.data[-1]],   lon_str:lon.data[1:]} )
                elif fnt == 'east':
                    dvdx=(da_regrid[:,:,:,-1]-da_regrid[:,:,:,-2]) / dx.values
                    dvdx=dvdx.expand_dims((lon_str),axis=3).assign_coords({lon_str:[lon.data[-1]]}).rename({'lat':lat_str})
                    ds_['dvdx_'+suffix[fnt]] = xr.DataArray( dvdx.values, coords={'time':time, 'lev':lev.data, lat_str:lat.data, lon_str:[lon.data[-1]]})

                if fnt in ['south', 'north','east']:    
                    ds_['dvdx_'+suffix[fnt]].attrs=get_attrs('diff')
                    ds_['dz_dvdx_'+suffix[fnt]]=da_dz
                    ds_['dz_dvdx_'+suffix[fnt]].attrs=get_attrs('dz') 
              
                        
        if view_results:
                try:
                    dvdx.isel(time=0).plot(figsize=(10,7))
                    plt.title(f"{var} {fnt} Differentiation dv/dx")
                    plt.savefig(f'OBC_{fnt}_diff{var}.png')        
                    plt.show()
                except:
                    try:
                        dudy.isel(time=0).plot(figsize=(10,7)) 
                        plt.title(f"{var} {fnt} Differentiation du/dy")
                        plt.savefig(f'OBC_{fnt}_diff{var}.png')        
                        plt.show()   
                    except:
                        pass   
                
       #
        if var not in ['zos','ssh','SSH']:
            ds_out_obc=fill_obc(ds_, dim=fill)
        else: #if var in ['temp','thetao','so','salt']:
            ds_out_obc=fill_obc2d(ds_,dim=fill)
        write_obc(ds_out_obc.mean(dim),var,f"obc_{var}_{fnt}.nc",
				fill_value, lon=lon_str, lat=lat_str)
        
        if view_results:
            ds_out_obc[f"{var}_{suffix[fnt]}"].isel(time=0).plot(figsize=(10,7))
            plt.title(f"OBC {fnt} {var} from SODA - Regional C-Grid bilinear interp")
            plt.savefig(f'OBC_{fnt}_{var}.png')        
            plt.show()        
        
        
    print("natural end: ", var)

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
     else:
        attrs = {'standard_name' : "null",
                                'long_name' : "null",
                                'units' : "null"} 
     return attrs
#============================================================================= 
def get_dxdy(border,ds_grid,xpoints,ypoints,supergrid=False):
	if supergrid:
		dx={'north': ds_grid.dx[-1,:] ,  'east': ds_grid.dx[:,-1], 'south': ds_grid.dx[0,:]}
		dy={'north': ds_grid.dy[-1,:] ,  'east': ds_grid.dy[:,-1], 'south': ds_grid.dy[0,:]}
	else:
		dx={'north': ds_grid.dx[-1,xpoints]*2 ,  'east': ds_grid.dx[ypoints,-1]*2, 'south': ds_grid.dx[0,xpoints]*2}
		dy={'north': ds_grid.dy[-1,xpoints]*2 ,  'east': ds_grid.dy[ypoints,-1]*2, 'south': ds_grid.dy[0,xpoints]*2}
	return dx[border],dy[border]
#============================================================================= 
def segment_defaults(border, nt, lat, lon, nz, lat_str, lon_str):

    if border == 'north':
       sel_slice=dict(lat=slice(-2,-1)) ; dim='lat' ; fill=['lon']
       shape_dz=(nt,1, 1, len(lon.data))
       shape_rgd=(len(lon.data),2)
       coord_rgd={lon_str:lon.data, lat_str:[lat.data[-2],lat.data[-1]]}
    elif border == 'south':
       sel_slice=dict(lat=slice(0,1)) ; dim='lat' ; fill=['lon']
       shape_dz=(nt,1, 1, len(lon.data))
       shape_rgd=(len(lon.data), 2)
       coord_rgd={lon_str:lon.data, lat_str:[lat.data[0],lat.data[1]]}

    elif border == 'east':
       sel_slice=dict(lon=slice(-2,-1)) ; dim='lon' ; fill=['lat']
       shape_dz=(nt,1, len(lat.data),1)
       shape_rgd=(2, len(lat.data))
       coord_rgd={lon_str:[lon.data[-2],lon.data[-1]], lat_str: lat.data}

    elif border == 'west':
       sel_slice=dict(lon=slice(0,1)) ; dim='lon' ; fill=['lat']
       shape_dz=(nt,1, len(lat.data), 1)
       shape_rgd=(2, len(lat.data))
       coord_rgd={lon_str:[lon.data[0],lon.data[1]], lat_str: lat.data}

    return sel_slice, dim, fill, shape_dz, shape_rgd, coord_rgd
#=============================================================================                    
def get_args(args):
    if(len(args)<=1):
	    print(f"Abort. Erro no uso: {args[0]} <ocean_static_file> <global_file> <ocean_topog> <var> <lati, latf, loni, lonf>")
	    print(f'fornecido: {args} \n\n', '------\t'*10)
	    quit()
    else:
	    print('............. Generating OBC .............') 
	    print(f' {args[:]}')   
	  
    static_file=args[1]
    global_file=args[2]
    topog_file=args[3]    
    var=args[4]
    fnt=args[5]
    lati, latf, loni, lonf = [float(i) for i in args[6:] ]
    
    ds_grid=xr.open_dataset(static_file)
    depth=xr.open_dataset(topog_file)['depth']    
    
    try:
        ds_var=xr.open_dataset(global_file)[var].sel(longitude=slice(loni,lonf),
                                                    latitude=slice(lati,latf)).rename({'longitude': 'lon', 'latitude': 'lat','depth': 'lev'})  
        uv=True
    except:
        try:
            ds_var=xr.open_dataset(global_file)[var].sel(longitude=slice(loni,lonf),
                                                    latitude=slice(lati,latf)).rename({'longitude': 'lon', 'latitude': 'lat','depth': 'lev'})
            uv=False
        except: 
            ds_var=xr.open_dataset(global_file)[var].sel(longitude=slice(loni,lonf),
                                                    latitude=slice(lati,latf)).rename({'longitude': 'lon', 'latitude': 'lat'})
            uv=False
        
    return var, ds_grid, depth, ds_var, uv, fnt
#============================================================================= 
def dzIter(nk, Htot, dzTop, Huniform, fnPow, prec):
    import math
    """
    Optimizes the highest ratio dzFn so that the sum(dz)=Htot.
    https://github.com/NOAA-GFDL/MOM6-examples/blob/dev/gfdl/ice_ocean_SIS2/OM4_025/INPUT/vgrid.py
    """
    def dzFn(nk, Huniform, dzTop, fnPow, zFac):
        """
        Returns dz = dzTop * ( 1 + zFac \int \fn(k) dk ) and sum(dz).
        """
        dz = np.ones(nk) * dzTop
        k = math.ceil( Huniform/dzTop )
        dz = dzTop * np.cumprod( 1. + zFac * (fn( np.linspace(1, nk, nk).astype(np.float64), k, nk )**fnPow) )
        return dz, np.sum(dz)

    def fn(z, z0, z1):
        """
        Cosine bell function between z0 and z1 s.t. f(z<z0)=0 and f(z>z1)=0.
        """
        zStar = (z-z0)/(z1-z0) # non-dimensional coordinate 0..1
        zStar = np.maximum(0., zStar)
        zStar = np.minimum(1., zStar)
        return 0.5*(1. - np.cos(2.*math.pi*zStar))

    def optimizeZfac(nk, Htot, dzTop, Huniform, fnPow,  prec):
        """
        Optimizes the highest ratio dzFn() so that the sum(dz)=Htot.
        """
        it = 0
        zc0 = 0; dz, H0 = dzFn( nk, Huniform, dzTop, fnPow,  zc0 )
        zc2 = 2; dz, H2 = dzFn( nk, Huniform, dzTop, fnPow,  zc2 )
        while H2-H0 > prec/8  and it<200: # Binary search
            zc1 = (zc0 + zc2)/2; dz, H1 = dzFn( nk, Huniform, dzTop, fnPow,  zc1 )
            if Htot<H1: zc2, H2 = 1.*zc1, 1.*H1
            else: zc0, H0 = 1.*zc1, 1.*H1
            it += 1
        #print 'zFac=',zc1,'max ratio=',(dz[1:]/dz[:-1]).max()
        return dz

    def roundDz(nk, Htot, dzTop, Huniform, fnPow,  prec):
        """
        Returns dz = optimizeZfac() rounded to the precision "prec", and sum(dz).
        """
        dz = prec * np.rint( optimizeZfac(nk, Htot, dzTop, Huniform, fnPow,  prec)/prec ) # Round to a given precision
        return dz, np.sum(dz)

    dz, H = roundDz( nk, Htot, dzTop, Huniform, fnPow,  prec )
    return dz

def zFromDz(dz):
    """
    Sums dz to return zInterface and zCenter.
    
    """
    zInt = zeros(dz.shape[0]+1)
    zInt[1:] = -np.cumsum(dz)
    zCenter = 0.5*( zInt[:-1] + zInt[1:] )
    return zInt, zCenter
#============================================================================= 
def create_dz(z,zmax):
    view_results=False
    if view_results:
        print('z original   >>>>>>>>>>>',z.values)
    zi=0.5*(np.roll(z,shift=-1)+z)
    zi[-1]=zmax
    if view_results:
        print('z modificado >>>>>>>>>>>',zi.values)
    #        
    #criar dz: valores positivos, da diferença da altura da coluna com relação ao fundo
    dz=np.roll(zi,shift=-1)-zi
    #dz[-1] = (   dz[-2]   )
    dz[-1] = (   zmax-zi[-2]   )

    dz[1:] = dz[0:-1]
    dz[0] = zi[0]
    if view_results:
        print('dz           >>>>>>>>>>>',dz)
    #
    #  
    return dz

#=============================================================================                        
def fill_obc(ds_,dim=['lon'], fill='b'):                        

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
                if fill == 'b':
                     ds_fill[v] = ds_fill[v].bfill(coordz)
                elif fill == 'f':
                     ds_fill[v] = ds_fill[v].ffill(coordz)	
            except:               
                pass


                     
    if len(ds_fill.dims) == 0:
        print(f"coords not found in {ds_.dims}") 
#            
    return ds_fill
     
#=============================================================================                        
def fill_obc2d(ds_,lon=['lon'], lat=['lat']):                        

    ds_fill = xr.Dataset()
    for v in ds_.keys():
        print('*~ filling xy ', v)
        for coordx in lon:
            try:
                ds_fill[v] = ds_[v].ffill(coordx)
            except:
                ds_fill[v] = ds_[v] 
                pass         
        for coordy in lat:
            try:
                ds_fill[v] = ds_fill[v].bfill(coordy)
            except:
                ds_fill[v] = ds_fill[v] 
                pass
                     
    if len(ds_fill.dims) == 0:
        print(f"coords not found in {ds_.dims}") 
#            
    return ds_fill                   
            
#========================================================================    
def write_obc(ds_, varname, fname='obc_teste.nc', fill_value=1e20, lon='lon', lat='lat'):
    print(f'writing {varname} to {fname}')
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
    
    try:
        if lon == 'xh':    
            ds_[lon].attrs={'standard_name':"longitude",
                            'long_name' : "h point nominal longitude",
                            'axis' : "X",
                            'cartesian_axis' : "X",
                            'units' : "degrees"}
        else:
            ds_[lon].attrs={'standard_name':"longitude",
                            'long_name' : "q point nominal longitude",
                            'axis' : "X",
                            'cartesian_axis' : "X",
                            'units' : "degrees"} 
    except:
        pass                        
    try:                              
        if lat == 'yh':      
            ds_[lat].attrs={'standard_name' : "latitude",
                                'long_name' : "h point nominal latitude",
                                'axis' : "Y",
                                'cartesian_axis' : "Y",
                                'units' : "degrees"} 
        else:                                                      
            ds_[lat].attrs={'standard_name' : "latitude",
                                'long_name' : "q point nominal latitude",
                                'axis' : "Y",
                                'cartesian_axis' : "Y",
                                'units' : "degrees"} 
    except:
        pass                                                        
               
    if 'zos' not in varname:
        ds_.lev.attrs={'axis' : "Z", 'cartesian_axis' : "Z",
                       'positive' : "down", 'units' : "meter", 'long_name' : "zstar depth"}
                
    ds_.time.encoding={"units":'days since 1900-01-01 00:00:00', 'calendar' : "365_day", 'modulo' : " ",
                        '_FillValue':fill_value,'dtype':np.float32,'missing_value':fill_value,
                        'axis' : "T"}
    ds_.time.attrs['modulo']=' '                           
    ds_.attrs={'title': "remap_obc_from_soda_to_MOM6 v3 output file",    
            "references":""""remap_obc_from_soda_to_MOM6
                    Developed by: por Nicole C. Laureanti (INPE/BR)
                    nlaureanti@gmail.com
                    More examples: https://github.com/ESMG/regionalMOM6_notebooks/blob/master/creating_obc_input_files/panArctic_OBC_from_global_MOM6.ipynb""","source":"SODA"}
    ds_.to_netcdf( fname , unlimited_dims=('time')  )
    print(f'>{fname} saved')    
    
    return None
    
if __name__ == "__main__":
    import pandas as pd
    import numpy as np
    import matplotlib.pyplot as plt
    import xarray as xr
    import sys,os
    import xesmf as xe
    import warnings
    
    warnings.filterwarnings("ignore")
    main()
    


