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


    if(len(sys.argv)<2):
	    print(f"uso: {sys.argv[0]} <arquivo> <dirout>*")
	    print(f'fornecido: {sys.argv} \n\n', '------\t'*10)
	    quit()
    else:
	    print(f"uso: {sys.argv}\n",'------\t'*13)

    tctl='01jan1900'
    tnc=pd.date_range("1900-01-01", freq="d", periods=1)
    undef=1e20
    selvar='grade'

    ds = xr.open_dataset(sys.argv[2])
     
    var=sys.argv[3]
    dirout='./'
    file_preffix=dirout+os.path.basename(sys.argv[1]).replace('nc','')
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

    if var not in ['ssh','zos'] and False:
       for ztmp in ['z_l','zl','st_ocean','depth','lev','Layer','zt']:
            if ztmp in ds.dims:
               z=ztmp
               break
    else:
            z='z'
            ds[z]=xr.DataArray( np.arange(0,1,1),
                         dims = ("z") ,
                 	 coords = { "z" : np.arange(0,1,1)})
    print('------\t'*13,regional_grid)
    try:
         time_values=ds.time[0:1]
    except:
         time_values=tnc
     
         
    if ocean_hgrid:
         p = np.empty(( len(time_values),
                             len(ds[z].values),
                             len(regional_grid.y.values[:,0]),
                             len(regional_grid.x.values[0]) ))
         p[:] = undef
         print(regional_grid.y.mean('nxp').values[0::len(regional_grid.y)-1])
         print(regional_grid.y.max('nxp').values[0::len(regional_grid.y)-1])
         v = xr.DataArray( p, name = selvar, 
                         dims = ("time","z","lat","lon") ,
                         coords = { "time" : time_values,
                                      "z" : abs(ds[z].values),
				     'lat': np.round(regional_grid.y.max('nxp').values, decimals=2),
                                     #'lon' : regional_grid.x.values[1]})
				     'lon' : np.round(regional_grid.x.mean('nyp').values, decimals=1)})
         print(v.lat.min().values,v.lat.max().values)
         print(v.lon.min().values,v.lon.max().values)
    else:
         p = np.empty(( len(time_values),
                             len(ds[z].values),
                             len(regional_grid['y'].values),
                             len(regional_grid['x'].values) ))
         p[:] = undef
         v = xr.DataArray( p, name = selvar, 
                         dims = ("time","z","lat","lon") ,
                         coords = { "time" : time_values[:],
                                     "z" : ds[z].values,
                                     'lat' : regional_grid['y'].values,
                                     'lon' : regional_grid['x'].values })
 
 
    campos = v   	


    if var not in ['ssh','zos'] :
        print(f'convertendo: {file_preffix}bin')
        
        print(f" vdims: {campos.dims}\n vshape : {campos.shape}")
        escreve_bin(campos, file_preffix)
        
        #Escrevendo o ctl
        criar_ctl(file_preffix+'ctl',file_preffix+'bin',undef,\
                        campos.shape[3],f"{np.array2string(campos[campos.dims[3]].data, precision=3, max_line_width=60)}",\
                        campos.shape[2],f"{np.array2string(campos[campos.dims[2]].data, precision=3, max_line_width=60)}",\
                        campos.shape[1],f"{np.array2string(campos[campos.dims[1]].data, precision=1, max_line_width=60)}",\
                        1,'1dy', tctl, [selvar], len([selvar])) 

        #Para cada fronteira:
        north = { 'file_preffix' : 'north.' ,
                                'nx' : campos.shape[3],
                                'dx' : campos[campos.dims[3]].data, 
                                'ny' : 1,
                                'dy' : np.array([-1]),
                                'campo' : \
                                campos.isel(lat=-1).data\
                            .reshape(len(time_values),
                        len(ds[z].values),1,len(regional_grid.x.values[0])), #if needed (31, 63, 1, 321)
                                   'create_ctl' : criar_ctl_bcx  }
        south = { 'file_preffix' : 'south.' ,
                                'nx' : campos.shape[3],
                                'dx' : campos[campos.dims[3]].data, 
                                'ny' : 1,
                                'dy' : np.array([-1]),
                                'campo' : campos.isel(lat=0).data\
                            .reshape(len(time_values),
                        len(ds[z].values),1,len(regional_grid.x.values[0])),
                                  'create_ctl' : criar_ctl_bcx   }
        east = { 'file_preffix' : 'east.' ,
                                'nx' : 1,
                                'dx' : np.array([-1]),
                                'ny' : campos.shape[2],
                                'dy' : campos[campos.dims[2]].data,
                                'campo' : campos.isel(lon=-1).data\
                            .reshape(len(time_values),
				len(ds[z].values),len(regional_grid.y.values[:,0]),1),
                                'create_ctl' : criar_ctl_bcy   }
 
        fronteira=[north,south,east]                     
        fronteira=[None]
        for b in fronteira:
            if b is None:
                 break
            print(f"convertendo: {b['file_preffix']}bin")
            print(f" shape : {b['campo'].shape}")
            escreve_bin(b['campo'],b['file_preffix'])            
            b['create_ctl'](b['file_preffix']+'ctl',b['file_preffix']+'bin',undef,\
                        b['nx'],f"{np.array2string(b['dx'], precision=3, max_line_width=60)}",\
                        b['ny'],f"{np.array2string(b['dy'], precision=3, max_line_width=60)}",\
                        campos.shape[1],
                f"{np.array2string(campos[campos.dims[1]].data, precision=1, max_line_width=60)}",\
                        1,'1dy', tctl, [selvar], len([selvar]))



    elif False: # para dim='2d'
        print(f'convertendo: {file_preffix}bin\n', '2d '*10)
        campos = v
        print(f" vdims: {campos.dims}\n vshape : {campos.shape}")
        escreve_bin(campos, file_preffix)
        
        #Escrevendo o ctl
        criar_ctl_2d(file_preffix+'ctl',file_preffix+'bin',undef,\
                        campos.shape[2],f"{np.array2string(campos[campos.dims[2]].data, precision=4, max_line_width=60)}",\
                        campos.shape[1],f"{np.array2string(campos[campos.dims[1]].data, precision=4, max_line_width=60)}",\
                        1,f" 1 1",\
                        1,'1dy', tctl, [selvar], len([selvar])) 

        #Para cada fronteira:
        north = { 'file_preffix' : 'north.' ,
                            'nx' : campos.shape[2],
                            'dx' : campos[campos.dims[2]].data, 
                            'ny' : 1,
                            'dy' : np.array([-1]),
                            'campo' : \
                            campos.isel(lat=-1).data,
            #.reshape(len(time_values),len(ds[z].values),1,len(regional_grid.x.values[0])), #if needed (31, 63, 1, 321)
                               'create_ctl' : criar_ctl_bcx  }
        south = { 'file_preffix' : 'south.' ,
                            'nx' : campos.shape[2],
                            'dx' : campos[campos.dims[2]].data, 
                            'ny' : 1,
                            'dy' : np.array([-1]),
                            'campo' : campos.isel(lat=0),
                              'create_ctl' : criar_ctl_bcx   }
        east = { 'file_preffix' : 'east.' ,
                            'nx' : 1,
                            'dx' : np.array([-1]),
                            'ny' : campos.shape[1],
                            'dy' : campos[campos.dims[1]].data,
                            'campo' : campos.isel(lon=-1),
                            'create_ctl' : criar_ctl_bcy   }
 
        fronteira=[north,south,east]                     
        fronteira=None
        for b in fronteira:
            print(f"convertendo: {b['file_preffix']}bin")
            print(f" shape : {b['campo'].shape}")
            escreve_bin(b['campo'],b['file_preffix'])            
            b['create_ctl'](b['file_preffix']+'ctl',b['file_preffix']+'bin',undef,\
                        b['nx'],f"{np.array2string(b['dx'], precision=4, max_line_width=60)}",\
                        b['ny'],f"{np.array2string(b['dy'], precision=4, max_line_width=60)}",\
                        1,
                f" 1 1",\
                        1,'1dy', tctl, [selvar], len([selvar]))                  



################################################################################
def criar_ctl(ctlout,nomebin,undef,nx,dx,ny,dy,nz,dz,nt,dt,t0,vvar,dvars):
    nomebin=nomebin.split('/')
    print(f"\n Criando ctl {ctlout}\n",'------\t'*10) 
    with open(ctlout,'w', encoding = 'utf-8') as f:
        f.write(f"dset ^{nomebin[-1]} \n\
title ^Criado automaticamente  \nundef {undef}\n\
xdef {nx} levels {str(dx).replace('[','').replace(']','')}\n\
ydef {ny} levels {str(dy).replace('[','').replace(']','')}\n\
zdef 1 linear 0 1\n\
tdef {nt} linear {t0} {dt}\n\
vars {dvars}\n")
        for vname in vvar:
            f.write(f"{vname}  0 99 t,z,y,x  {vname}\n")
        f.write("endvars")
    f.close()                  


def criar_ctl_2d(ctlout,nomebin,undef,nx,dx,ny,dy,nz,dz,nt,dt,t0,vvar,dvars):
    nomebin=nomebin.split('/')
    print(f"\n Criando ctl {ctlout}\n",'------\t'*10) 
    with open(ctlout,'w', encoding = 'utf-8') as f:
        f.write(f"dset ^{nomebin[-1]} \n\
title ^Criado automaticamente  \nundef {undef}\n\
xdef {nx} levels {str(dx).replace('[','').replace(']','')}\n\
ydef {ny} levels {str(dy).replace('[','').replace(']','')}\n\
zdef {nz} levels {str(dz).replace('[','').replace(']','')}\n\
tdef {nt} linear {t0} {dt}\n\
vars {dvars}\n")
        for vname in vvar:
            f.write(f"{vname}  {nz} 99 t,z,y,x  {vname}\n")
        f.write("endvars")
    f.close()


def criar_ctl_bcy(ctlout,nomebin,undef,nx,dx,ny,dy,nz,dz,nt,dt,t0,vvar,dvars):
    nomebin=nomebin.split('/')
    print(f"\n Criando ctl {ctlout}\n",'------\t'*10) 
    with open(ctlout,'w', encoding = 'utf-8') as f:
        f.write(f"dset ^{nomebin[-1]} \n\
title ^Criado automaticamente  \nundef {undef}\n\
xdef {nx} linear {str(dx).replace('[','').replace(']','')} 1\n\
ydef {ny} levels {str(dy).replace('[','').replace(']','')}\n\
zdef {nz} levels {str(dz).replace('[','').replace(']','')}\n\
tdef {nt} linear {t0} {dt}\n\
vars {dvars}\n")
        for vname in vvar:
            f.write(f"{vname}  {nz} 99 t,z,y,x  {vname}\n")
        f.write("endvars")
    f.close()
def criar_ctl_bcx(ctlout,nomebin,undef,nx,dx,ny,dy,nz,dz,nt,dt,t0,vvar,dvars):
    nomebin=nomebin.split('/')
    print(f"\n Criando ctl {ctlout}\n",'------\t'*10) 
    with open(ctlout,'w', encoding = 'utf-8') as f:
        f.write(f"dset ^{nomebin[-1]} \n\
title ^Criado automaticamente  \nundef {undef}\n\
xdef {nx} levels {str(dx).replace('[','').replace(']','')}\n\
ydef {ny} linear {str(dy).replace('[','').replace(']','')} 1\n\
zdef {nz} levels {str(dz).replace('[','').replace(']','')}\n\
tdef {nt} linear {t0} {dt}\n\
vars {dvars}\n")
        for vname in vvar:
            f.write(f"{vname}  {nz} 99 t,z,y,x  {vname}\n")
        f.write("endvars")
    f.close()


def escreve_bin(campos, nome):
    print(f"\n Escreve binário {nome}bin\n") 
    from scipy.io import FortranFile
    import numpy as np
    np.set_printoptions(suppress=True) #prevent numpy exponential 
                                   #notation on print, default False

    f = FortranFile(nome+'bin', 'w')
    for t in range(len(campos.data)):
            try:
                for zsel in range(len(campos[t,:,:,:].data)):
        #                print(f'shape at t {t} {zsel} {campos[t,zsel,:,:].shape}')
                        
                        matrix=np.array( campos[t,zsel,:,:].data, dtype=np.float32).reshape(campos[0,0,:,:].shape)
                        f.write_record(  matrix   )

            except:
                for zsel in range(len(campos[t,:,:].data)):
        #                print(f'shape at t {t} {zsel} {campos[t,zsel,:,:].shape}')
                        
                        matrix=np.array( campos[t,:,:].data, dtype=np.float32).reshape(campos[0,:,:].shape)
                        f.write_record(  matrix   )
    try:
        print(f"bin size = {campos.shape[0]*campos.shape[1]*campos.shape[2]*campos.shape[3]*4}")
    except:
        print(f"bin size = {campos.shape[0]*campos.shape[1]*campos.shape[2]*4}")





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
    main()



