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

    var, ds_grid, depth_vector, ds_var, uv, borders  = get_args(sys.argv)
                        
    if view_results:
        print(ds_var)
    
    #verify coords                                                    
    xh=ds_grid.x[0,:][1::2] #igual a ds_grid.x[0,xpoints]
    yh=ds_grid.y[:,0][1::2] #igual a ds_grid.y[ypoints,0]
        
    xq=ds_grid.x[0][0::2]
    yq=ds_grid.y[:,0][0::2]
    
    time=ds_var.time
    nt=len(ds_var.time)
    if var != 'ssh':
            lev=ds_var.lev
            nz=len(ds_var.lev)
    else:
	    lev=np.array(1,dtype='float64')
	    nz=1

    #select xy grid
    
    if var == 'v':
        lat=yq; nlat=len(yq)*2; lon=xh; nlon=len(xh)*2
        xpoints=slice(1,nlon+1,2)  ; ypoints=slice(0,nlat+1,2)
        lat_str='yq' ; lon_str='xh'
    elif var =='u':    
        lat=yh; nlat=len(yh)*2; lon=xq; nlon=len(xq)*2
        xpoints=slice(0,nlon+1,2)  ; ypoints=slice(1,nlat+1,2)              
        lat_str='yh' ; lon_str='xq'               
    else:
        lat=yh; nlat=len(yh)*2; lon=xh; nlon=len(xh)*2
        xpoints=slice(1,nlon+1,2)  ; ypoints=slice(1,nlat+1,2) 
        lat_str='yh' ; lon_str='xh'              
    xpointsq=slice(0,nlon+1,2)  ; ypointsq=slice(0,nlat+1,2)    
    
    supergrid=False #não funciona no notebook
    if supergrid:     
        lon=ds_grid.x[0,:]    #igual a ds_grid.x[0,xpoints]
        lat=ds_grid.y[:,0]    #igual a ds_grid.x[0,xpoints] 
        xpoints=slice(1,nlon,1)  ; ypoints=slice(1,nlat,1)         
    else:
        lon=ds_grid.x[0,xpoints]    #igual a ds_grid.x[0,xpoints]
        lat=ds_grid.y[ypoints,0]    #igual a ds_grid.x[0,xpoints]
 
        
    coords_obc={'north': {'time':time, 'lev':range(len(lev.data)), 'lat':range(len([lat.data[-1]])), 'lon':range(len(lon.data))}
             ,  'east' : {'time':time, 'lev':range(len(lev.data)), 'lat':range(len(lat.data)),       'lon':range(len([lon.data[-1]]))}
             ,  'south': {'time':time, 'lev':range(len(lev.data)), 'lat':range(len([lat.data[0]])),  'lon':range(len(lon.data)) } }
             
    coord_obc={'north': {'time':time, 'lev':lev.data, lat_str:[lat.data[-1]], lon_str:lon.data}
             , 'east' : {'time':time, 'lev':lev.data, lat_str: lat.data,      lon_str:[lon.data[-1]]}
             , 'south': {'time':time, 'lev':lev.data, lat_str:[lat.data[0]],  lon_str:lon.data } }      
             
    coord_obc_grad={'north': {'time':time, 'lev':lev.data, 'yq':[yq.data[-1]],   lon_str:lon.data}
                  , 'east' : {'time':time, 'lev':lev.data, lat_str:lat.data,         'xq':[xq.data[-1]]}
                  , 'south': {'time':time, 'lev':lev.data, 'yq':[yq.data[0]],   lon_str:lon.data} }                       
             
    coord_obc_ssh={'north':  {'time':time, lon_str:lon.data  }
                 , 'east' :  {'time':time, lat_str: lat.data }
                 , 'south':  {'time':time, lon_str:lon.data  } } 
                 
    coord_obc_dz={'north': {'time':time, 'lev':lev.data, lat_str:[lat.data[-1]], lon_str:lon.data}
             , 'east' : {'time':time, 'lev':lev.data, lat_str: lat.data,      'xh':[xh.data[-1]]}
             , 'south': {'time':time, 'lev':lev.data, lat_str:[lat.data[0]],  lon_str:lon.data } }                    
             
    attrs_dict= { 'ssh' :  {    'units' : "meter",      'long_name' : "effective sea level (eta_t + patm/(rho0*g)) on T cells" },
                  'temp' : {    'units' : "degrees C",  'long_name' : "Potential temperature" },
                  'salt' : {    'units' : "psu",        'long_name' : "Practical Salinity" },                  
                    'u' :  {    'units' : "m s-1",      'long_name' : "Barotropic-step Averaged Zonal Velocity" },
                    'v' :  {    'units' : "m s-1",      'long_name' : "Barotropic-step Averaged Zonal Velocity" },
                    'dz' : {    'units' : "meter" ,     'long_name' : "Layer thicknesses"} ,
                   'diff': {    'units' : "1/s",        'long_name' : "Part of vorticity" } , 'lon' : {'standard_name':"longitude",
                            'long_name' : "q point nominal longitude",
                            'axis' : "X",
                            'cartesian_axis' : "X",
                            'units' : "degrees"} , 
                'lat' :{'standard_name' : "latitude",
                                'long_name' : "h point nominal latitude",
                                'axis' : "Y",
                                'cartesian_axis' : "Y",
                                'units' : "degrees"}                 }
                   
    missval=1.e20                   
    fill_value=1.e20
             
    coord_ic={'time':time.data,'lev':lev.data,'lat':lat.data}
    coords_ic={'time':time,'lev':range(len(lev.data)),'lat':range(len(lat.data)),'lon':range(len(lon.data))}

    print('-----'*10)
    print('MAX '*5,f'LON {np.max(ds_grid.x.data)} LAT {np.max(ds_grid.y).data}')
    print('MIN '*5,f'LON {np.min(ds_grid.x.data)} LAT {np.min(ds_grid.y).data}')                       
    print('-----'*10)
    print('MAX '*5,f'LON {np.max(lon).data} LAT {np.max(lat).data}')
    print('MIN '*5,f'LON {np.min(lon).data} LAT {np.min(lat).data}')    
    print('LEN '*5,f'{lon_str} {len(lon)} {lat_str} {len(lat)}')        
    print('-----'*10)  
    #quit()   
    
    if not os.path.isfile(f'output_dz_h.nc'):
        print('*~ creating dz')
        #creating dz
        use_depth_to_limit=False
        if use_depth_to_limit:
            print('use_depth_to_limit')
            dz=np.zeros((len(lev.data),len(lat),len(lon)))
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
            dz=np.tile(dz[np.newaxis,:,np.newaxis,np.newaxis],(nt,1, len(lat.data), len(lon.data)))
        da_dz=xr.DataArray(dz,coords=[('time',time.data),('lev',lev.data), ('lat',lat.data),('lon',lon.data)], name='dz')
        da_dz.attrs=attrs_dict['dz'] 
        da_dz.lat.attrs=attrs_dict['lat']; da_dz.lon.attrs=attrs_dict['lon']
                 
                                       
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
        da_dz.to_netcdf(f'output_dz_h.nc')                             

    else:
        da_dz=xr.open_dataset('output_dz_h.nc')['dz']
                 
    print('*~ regriding: ', var)
    #applying regrid        
    da_regrid=xr.DataArray(np.zeros((len(lat),len(lon))),coords=[('lat',lat.data),('lon',lon.data)],name=var)
    regridder = xe.Regridder(ds_var, da_regrid, "bilinear", periodic=False)
    da_regrid = regridder(ds_var)
    
    
    if view_results:
        try:
            da_regrid.isel(time=0,lev=0).plot(figsize=(10,7))
        except:
            da_regrid.isel(time=0).plot(figsize=(10,7))    
        plt.title(f"Surface {var} from SODA - Regional C-Grid bilinear interp")
        plt.savefig(f'OBC_{var}_C-Gridbilinearinterp.png')
        plt.show()
              
    #filling 
    if var =='ssh':
	    ds_regrid=xr.Dataset({'time':time,'lon':lon.data,
                                            'lat':lat.data, var: da_regrid})
    else:
            ds_regrid=xr.Dataset({'time':time,'lev':lev.data,'lon':lon.data,
                                            'lat':lat.data, var: da_regrid})

    #ds_out=fill_obc(ds_regrid)
    ds_out=ds_regrid
    #write_obc(ds_out.isel(time=0),var,f"ic_{var}.nc",missval)                    
    
    
    fronteiras=['south','north','east']    
    suffix={ 'north':'segment_001','east':'segment_003','south':'segment_002'}
    
    for fnt in [borders]:
        print('*~ working on obc:', fnt)
        
        if var == 'ssh':
            if fnt == 'north':
                out_obc=ds_out.isel(lat=slice(-2,-1)).mean('lat')
                da_out_obc=out_obc.expand_dims((lat_str),axis=1).assign_coords({lat_str:[lat.data[-1]]}).rename({'lon':lon_str})    

            elif fnt == 'east':
                out_obc=ds_out.isel(lon=slice(-2,-1)).mean('lon')
                da_out_obc=out_obc.expand_dims((lon_str), axis=2).assign_coords({lon_str: [lon.data[-1]]}).rename({'lat':lat_str})

            elif fnt == 'south':
                out_obc=ds_out.isel(lat=slice(0,1)).mean('lat')
                da_out_obc=out_obc.expand_dims((lat_str),axis=1).assign_coords({lat_str:[lat.data[0]]}).rename({'lon':lon_str})     
                 
            ds_=xr.Dataset({ f"{var}_{suffix[fnt]}": (da_out_obc[var].dims , da_out_obc[var].values )}, coords=coord_obc[fnt])                 
        
        else: #not ssh
            if fnt == 'north':
                out_obc=ds_out.isel(lat=slice(-2,-1)).mean('lat')
                dz_obc=da_dz.isel(lat=slice(-2,-1)).mean('lat')  
                da_out_obc=out_obc.expand_dims((lat_str),axis=2).assign_coords({lat_str:[lat.data[-1]]}).rename({'lon':lon_str})
                da_dz_obc=dz_obc.expand_dims((lat_str),axis=2).assign_coords({lat_str:[lat.data[-1]]}).rename({'lon':lon_str})

            elif fnt == 'east':
                out_obc=ds_out.isel(lon=slice(-2,-1)).mean('lon')
                dz_obc=da_dz.isel(lon=slice(-2,-1)).mean('lon') 
                da_out_obc=out_obc.expand_dims((lon_str),axis=3).assign_coords({lon_str:[lon.data[-1]]}).rename({'lat':lat_str})
                da_dz_obc=dz_obc.expand_dims((lon_str),axis=3).assign_coords({lon_str:[lon.data[-1]]}).rename({'lat':lat_str})

            elif fnt == 'south':
                out_obc=ds_out.isel(lat=slice(0,1)).mean('lat')
                dz_obc=da_dz.isel(lat=slice(0,1)).mean('lat')
                da_out_obc=out_obc.expand_dims((lat_str),axis=2).assign_coords({lat_str:[lat.data[0]]}).rename({'lon':lon_str})
                da_dz_obc=dz_obc.expand_dims((lat_str),axis=2).assign_coords({lat_str:[lat.data[0]]}).rename({'lon':lon_str})

            ds_=xr.Dataset({ f"{var}_{suffix[fnt]}": (da_out_obc[var].dims , da_out_obc[var].data )}, coords=coord_obc[fnt])        
            ds_[f'dz_{var}_{suffix[fnt]}']=xr.DataArray( da_dz_obc.values, coords=coord_obc_dz[fnt] )
            ds_[f'dz_{var}_{suffix[fnt]}'].attrs=attrs_dict['dz'] 
        ds_[f"{var}_{suffix[fnt]}"].attrs=attrs_dict[var]                                                        
        if False:
            ds_[f"{var}_{suffix[fnt]}"].isel(time=0).plot(figsize=(10,7))
            plt.title(f"OBC {fnt} {var} from SODA - Regional C-Grid bilinear interp")
            plt.savefig(f'OBC_{fnt}_{var}.png')        
            plt.show()        

        #make dudy dvdx
        dx={'north': ds_grid.dx[-1,xpointsq]*2 ,  'east': ds_grid.dx[ypointsq,-1]*2, 'south': ds_grid.dx[0,xpointsq]*2}
        dy={'north': ds_grid.dy[-1,xpointsq]*2 ,  'east': ds_grid.dy[ypointsq,-1]*2, 'south': ds_grid.dy[0,xpointsq]*2}            
                   
        if uv:
            ds_out=fill_obc(ds_out,lon='lon', lat='lat')   
            if var == 'u':
                print(fnt, ds_out[var].shape,' x  ',dy[fnt].shape)     
                if fnt == 'south':
                    dudy=(ds_out[var][:,:,1,:]-ds_out[var][:,:,0,:]) / dy[fnt].values
                elif fnt == 'north':    
                    dudy=(ds_out[var][:,:,-1,:]-ds_out[var][:,:,-2,:])/ dy[fnt].values
                elif fnt == 'east':
                    dudy=(ds_out[var][:,:,:,-1]-ds_out[var][:,:,:,-2]) / dy[fnt].values                    
                if fnt in ['south', 'north','east']: 
                    print(dudy.dims,dudy.shape)
                    ds_['dudy_'+suffix[fnt]] = xr.DataArray( dudy.values.reshape(da_dz_obc.shape), coords=coord_obc_grad[fnt])
                    ds_['dudy_'+suffix[fnt]].attrs=attrs_dict['diff'] 
                    ds_['dz_dudy_'+suffix[fnt]]=xr.DataArray( da_dz_obc.values, coords=coord_obc[fnt])
                    ds_['dz_dudy_'+suffix[fnt]].attrs=attrs_dict['dz'] 
                print(f'hseg   dz_{var}_{suffix[fnt]}   ', ds_['dz_u_'+suffix[fnt]].shape, ds_['dz_u_'+suffix[fnt]].dims)
                print(f'hqseg  dz_dudy_{suffix[fnt]}    ', ds_['dz_dudy_'+suffix[fnt]].shape,ds_['dz_dudy_'+suffix[fnt]].dims)            
            elif var == 'v':
                print(da_out_obc[var].shape,' vs. ',dx[fnt].shape)            
                              
                if fnt == 'south':
                    dvdx=(ds_out[var][:,:,1,:]-ds_out[var][:,:,0,:]) / dx[fnt].values
                elif fnt == 'north':    
                    dvdx=(ds_out[var][:,:,-1,:]-ds_out[var][:,:,-2,:]) / dx[fnt].values
                elif fnt == 'east':
                    dvdx=(ds_out[var][:,:,:,-1]-ds_out[var][:,:,:,-2]) / dx[fnt].values
                if fnt in ['south', 'north','east']:    
                    print(dvdx.dims,dvdx.shape)  
                    ds_['dvdx_'+suffix[fnt]] = xr.DataArray( dvdx.values.reshape(da_dz_obc.shape), coords=coord_obc_grad[fnt])
                    ds_['dvdx_'+suffix[fnt]].attrs=attrs_dict['diff'] 
                    ds_['dz_dvdx_'+suffix[fnt]]=xr.DataArray( da_dz_obc.values, coords=coord_obc[fnt])
                    ds_['dz_dvdx_'+suffix[fnt]].attrs=attrs_dict['dz'] 
              
                print(f'hqseg  dz_{var}_{suffix[fnt]}   ',ds_['dz_v_'+suffix[fnt]].shape,ds_['dz_v_'+suffix[fnt]].dims)
                print(f'hqseg  dz_dvdx_{suffix[fnt]}    ', ds_['dz_dvdx_'+suffix[fnt]].shape,ds_['dz_dvdx_'+suffix[fnt]].dims)
            #print(f'sshseg zeta_{suffix[fnt]}   ',ds_['ssh_'+suffix[fnt]].shape)        
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
        if var not in ['ssh']:
            ds_out_obc=fill_obc(ds_, lon=lon_str, lat=lat_str)
            
        else:
            ds_out_obc=fill_obc2d(ds_,lon=lon_str, lat=lat_str)
        write_obc(ds_out_obc,var,f"obc_{var}_{fnt}.nc",missval, lon=lon_str, lat=lat_str)
        
        if view_results:
            ds_out_obc[f"{var}_{suffix[fnt]}"].isel(time=0).plot(figsize=(10,7))
            plt.title(f"OBC {fnt} {var} from SODA - Regional C-Grid bilinear interp")
            plt.savefig(f'OBC_{fnt}_{var}.png')        
            plt.show()        
        
        
    print("natural end: ", var)
    
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
    border=args[5]
    lati, latf, loni, lonf = [float(i) for i in args[6:] ]
    
    ds_grid=xr.open_dataset(static_file)
    depth=xr.open_dataset(topog_file)['depth']    
    
    try:
        ds_var=xr.open_dataset(global_file)[var].sel(xu_ocean=slice(loni,lonf),
                                                    yu_ocean=slice(lati,latf)).rename({'xu_ocean': 'lon', 'yu_ocean': 'lat','st_ocean': 'lev'})
        uv=True
    except:
        try:
                ds_var=xr.open_dataset(global_file)[var].sel(xt_ocean=slice(loni,lonf),
                                                    yt_ocean=slice(lati,latf)).rename({'xt_ocean': 'lon', 'yt_ocean': 'lat','st_ocean': 'lev'})
                uv=False
        except:
                ds_var=xr.open_dataset(global_file)[var].sel(xt_ocean=slice(loni,lonf),
                                                    yt_ocean=slice(lati,latf)).rename({'xt_ocean': 'lon', 'yt_ocean': 'lat'})
                uv=False	
    return var, ds_grid, depth, ds_var, uv, border
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
def fill_obc(ds_,lon=['lon'], lat=['lat']):                        

    ds_fill = xr.Dataset()
    for v in ds_.keys():
        print('*~ filling xy ', v)
        for coordx in lon:
            try:
                ds_fill[v] = ds_[v].ffill(coordx).bfill(coordx)
            except:
                ds_fill[v] = ds_[v] 
                pass         
        for coordy in lat:
            try:
                ds_fill[v] = ds_fill[v].ffill(coordy).bfill(coordy)
            except:
                ds_fill[v] = ds_fill[v] 
                pass
             
        for coordz in ["lev","lev_2","z_l","st_ocean"]:
            try:
                ds_fill[v] = ds_fill[v].ffill(coordz).bfill(coordz)
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
                ds_fill[v] = ds_[v].ffill(coordx).bfill(coordx)
            except:
                ds_fill[v] = ds_[v] 
                pass         
        for coordy in lat:
            try:
                ds_fill[v] = ds_fill[v].ffill(coordy).bfill(coordy)
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
               
    if 'ssh' not in varname:
        ds_.lev.attrs={'axis' : "Z", 'cartesian_axis' : "Z",
                       'positive' : "down", 'units' : "meter", 'long_name' : "zstar depth"}
                
    ds_.time.encoding={"units":'days since 1900-01-01 00:00:00', 'calendar' : "365_day", 'modulo' : " ",
                        '_FillValue':fill_value,'dtype':np.float32,'missing_value':fill_value,
                        'axis' : "T"}
    ds_.time.attrs['modulo']=' '                           
    ds_.attrs={'title': "remap_obc_from_soda_to_MOM6 v3 output file",    
            "references":""""remap_obc_from_soda_to_MOM6
                    Developed by: nlaureanti@gmail.com""","source":"SODA"}
    ds_.to_netcdf( fname , unlimited_dims=('time')  )
    print(f'>{fname} saved')    
    
    return None
    
if __name__ == "__main__":
    import pandas as pd
    import numpy as np
    import matplotlib.pyplot as plt
    import xarray as xr
    import sys, os
    import xesmf as xe
    import warnings
    
    warnings.filterwarnings("ignore")
    main()
    


