#!/Volumes/A1/workdir/nicole/bin/python
import xarray as xr
import matplotlib.pyplot as plt
import os
import numpy as np
from MOMdefault_pplot_diags import *

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
    except:
        pass
    nx=len(a[f'nx_segment_{n}'].data)
    ny=len(a[f'ny_segment_{n}'].data)

    at=a.isel(time=range(0,365,30))
    a=a.isel(time=range(0,365,30))
    try:
        a[f'speed_segment_{n}']=np.sqrt(a[f'u_segment_{n}']**2+a[f'v_segment_{n}'])
    except:
        print(f'{f} no uv')
        pass
    

    for v in a.keys():
        try:
                Y = np.zeros(nz)
                Y[:] = np.cumsum(at[f"dz_{v.split('_')[0]}_segment_{n}"][0,:,0,0].data)
                file_preffix=f"./OBC_sect_{v}"
                if nx > ny:
                        X=at[f'nx_segment_{n}'].data ; Z=at[v][:,:,0,:]
                else:        
                        X=at[f'ny_segment_{n}'].data ; Z=at[v][:,:,:,0]
                
                
                plot_crosssecEvol(v.split('_')[0], len(a.time.data), 
                                        Z, X, Y ,v.split('_')[0],
                                        exp_name=f'OBC_segment_{n}', fig_preffix=file_preffix)
        except:
                pass
        print(v)
        try:
                plot_evolutionOBC(v.split('_')[0],a[v][:,0,:,:],a[v].time.data,v, f"OBC_{v}")
                
        except:
                plot_evolutionOBC(v.split('_')[0],a[v][:,:,:],a[v].time.data,v, f"OBC_{v}")

        try:
            at[v][0,:,0,:].plot(size=10,
                cmap=colors_default(v.split('_')[0])[0],
                levels=colors_default(v.split('_')[0])[1])
            plt.savefig(f"OBC_{v}.png")
            plt.clf()
        except:
            try:
                at[v][0,:,-1,:].plot(size=10,
                        cmap=colors_default(v.split('_')[0])[0],
                        levels=colors_default(v.split('_')[0])[1])
                plt.savefig(f"OBC_{v}.png")
                plt.clf()
            except:
                try:
                    at[v][0,:,:,-1].plot(size=10,
                        cmap=colors_default(v.split('_')[0])[0],
                        levels=colors_default(v.split('_')[0])[1])
                    plt.savefig(f"OBC_{v}.png")
                    plt.clf()
                except:
                    pass
        
        for z in [0,nz-1]:

            try:
                at[v][0,z,:,:].plot(size=10,
                        cmap=colors_default(v.split('_')[0])[0],
                        levels=colors_default(v.split('_')[0])[1])
                plt.savefig(f"OBC_{v}_{z}.png")
                plt.clf()
            except:
                pass
    a.close()
print('done')
quit()
