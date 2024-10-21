import numpy as np
import math
import matplotlib.pyplot as plt
import scipy.io
import xarray as xr

def open_grid(path,decode_times=False):
    
    """Return a grid object containing staggered grid locations"""
    grid={}
    grid['ds']=xr.open_dataset(path,decode_times=False)
    grid['ds']=grid['ds'].drop_dims(['ny','nx'])
    grid['ds']=grid['ds'].drop_vars(['tile'])
    try:
        grid['nyp']=grid['ds'].nyp.data[-1]+1
        grid['nxp']=grid['ds'].nxp.data[-1]+1
        nxp=grid['nxp'];nyp=grid['nyp']
        grid['h'] = grid['ds'].isel(nxp=slice(1,nxp+1,2),nyp=slice(1,nyp+1,2))
        #The q grid is not symmetric, but Cu and Cv are
        grid['q'] = grid['ds'].isel(nxp=slice(2,nxp+1,2),nyp=slice(2,nyp+1,2))
        grid['Cu'] = grid['ds'].isel(nxp=slice(0,nxp+1,2),nyp=slice(1,nyp+1,2))
        grid['Cv'] = grid['ds'].isel(nxp=slice(1,nxp+1,2),nyp=slice(0,nyp+1,2))
    except:
        grid['nyp1']=grid['ds'].nyp1.data[-1]+1
        grid['nxp1']=grid['ds'].nxp1.data[-1]+1
        nxp1=grid['nxp1'];nyp1=grid['nyp1']

        grid['h'] = grid['ds'].isel(nxp1=slice(1,nxp1+1,2),nyp1=slice(1,nyp1+1,2))
        #The q grid is not symmetric, but Cu and Cv are
        grid['q'] = grid['ds'].isel(nxp1=slice(2,nxp1+1,2),nyp1=slice(2,nyp1+1,2))
        grid['Cu'] = grid['ds'].isel(nxp1=slice(0,nxp1+1,2),nyp1=slice(1,nyp1+1,2))
        grid['Cv'] = grid['ds'].isel(nxp1=slice(1,nxp1+1,2),nyp1=slice(0,nyp1+1,2))
    return grid['h']   

def dzIter(nk, Htot, dzTop, Huniform, fnPow, prec):
    """
    Optimizes the highest ratio dzFn so that the sum(dz)=Htot.
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
    zInt = np.zeros(dz.shape[0]+1)
    zInt[1:] = np.cumsum(dz)
    zCenter = 0.5*( zInt[:-1] + zInt[1:] )
    return zInt, zCenter

def main():
    nk = 75         # number of levels
    Htot=6500       # deepest ocean point
    Huniform = 5    # upper region of uniform resolution
    dzTop = 5       # thickness of top level
    fnPow = 1.42865 # ???
    prec = .01      # precision to round thicknesses/depths todz = dzIter(nk, Htot, dzTop, Huniform, fnPow, prec)
    fname = 'vgrid_75_5m.nc'
    fileout='layer.nc'
    
    
    dz = dzIter(nk, Htot, dzTop, Huniform, fnPow,  prec)


    print('saving')    
    nc = scipy.io.netcdf_file(fname,'w')
    nc.createDimension('nz',dz.shape[0])
    nc.filename = fname
    v = nc.createVariable('dz','double',('nz',))
    v.units = 'm'
    v.long_name = 'z* coordinate level thickness'
    v[:] = dz[:]
    nc.close()
    print('ok', fname)

    zt=zFromDz(dz)[0]
    zw=zFromDz(dz)[1]

    view_results=True
    if view_results:
        print('dz=',dz)
        print('sum(dz)=',np.sum(dz))
        print('max ratio=',(dz[1:]/dz[:-1]).max())
        plt.plot(dz)
        plt.title('dz=f(z)')
        plt.show()
        print('zt=',len(zt),zt)
        print('zw=',len(zw),zw)

    make_z=True
    if make_z:
        
        
        
        ds = xr.open_dataset('/home/nicole/Documentos/INPE/dados_tese/SODA/soda3.15.2_5dy_ocean_reg_2000_12_28.nc')
        grid = open_grid('/home/nicole/Documentos/INPE/mom/exps_mom6/exp_AScoast_cdo/workdir/INPUT/ocean_hgrid.nc')

        nz = ds.st_ocean.values.shape[0]  
        nk = ds.st_ocean.values
        
        nz=len(dz)
        nk=zFromDz(dz)[1]
        
        nx=grid.x[0,:].shape[0]
        ny=grid.y[:,0].shape[0]
        
        #Criar interfaces: eixo z
        print(f"z = {nk}") 
        #nkmax=5500
        nkmax=np.max(nk)

        interf=np.zeros(len(nk)+1)
        print(interf.shape,interf[1:].shape,nk.shape)
        interf[1:]=0.5*(np.roll(nk,shift=-1)+nk)
        interf[-1] = nkmax
        interf[0] = 0
             
        if view_results:
            da_interf=xr.DataArray(interf,coords=[('Interface',interf)], name='interface')
            print("interface_z: ", interf.shape, interf)             
            plt.plot(range(interf.shape[0]),interf)
            plt.title('interface_z=f(z)')
            plt.show()   
            
        ds_=xr.Dataset( 
            data_vars=dict(
                Layer=(["Layer"], nk))
            )        
        ds_["Interface"]=interf
        
        
    #!==============================================    
        #criar eta: variação da altura em metros
        topog = xr.open_dataset('/home/nicole/Documentos/INPE/mom/exps_mom6/exp_AScoast002/workdir/INPUT/ocean_topog.nc')
        depth_vector = topog.depth      
        eta=np.zeros(interf.shape)
        print(eta.shape)      
        eta[0:] = -0.5*(np.roll(interf,shift=-1)+interf)
        eta[-1] = -0.5*(max(nk) - nkmax)
        #eta[0]=0  

        eta0 = np.empty((len(nk)+1, ny, nx))
        nk0= np.empty((nk.shape[0], ny, nx))
        for kz in range(len(interf)):
            eta0[kz,:,:]=eta[kz]
            try:
                nk0[kz,:,:]=nk[kz]
            except:
                pass
        
        da_eta=xr.DataArray(eta0,coords=[('Interface',interf),
                                    ('ny',grid.y[:,0].data),('nx', grid.x[0,:].data)], name='eta')
        use_depth_to_limit=True
        if use_depth_to_limit:
                for k in range(nz):
                    da_eta[k,:,:] = xr.where(abs(eta0[k,:,:])>abs(depth_vector), -1.0*depth_vector, eta0[k,:,:])  
        #ds_["eta"]=da_eta
        if view_results:
                print('eta >>>>>>>>>>>',da_eta.isel(ny=0))               
                da_eta.isel(ny=0).plot()
                plt.show()
    #!==============================================

        for v in ds_.coords:
            ds_[v].encoding['_FillValue']=1.e20
            ds_[v].encoding['dtype']=np.float32
        for v in ds_:
            ds_[v].encoding['_FillValue']=1.e20
            ds_[v].encoding['dtype']=np.float32        
            
        ds_['Layer'].attrs={'units' : "m", "positive" : "down", "axis":"Z",
                            'long_name' : "Layer Target"}
        ds_.attrs={'title': "vgrid output file"}           
                                      
        ds_.to_netcdf(fileout)

        print("> ",fileout)    

main()        
