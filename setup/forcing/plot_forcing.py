#!/Volumes/A1/workdir/nicole/bin/python
import xarray as xr
import matplotlib.pyplot as plt
import glob
import numpy as np

dir='/home/nicole/workdir/SWA14/forcing_subset_ERA5/*2001.nc'
#dir='/home/nicole/workdir/SWA14/forcing_subset_ERA5/ERA5_surface_thermal_radiation_downwards_2001.nc'
#dir='/home/nicole/workdir/SWA14/forcing2_subset_ERA5/ERA5_total*2001.nc'
#files=os.listdir(f'{dir}')
files=glob.glob(dir)
print(files)
for f in files:
    a=xr.open_dataset(f'{f}')
    print(f'{f}')
#    nz=len(a.zl.data)
    nx=len(a.longitude.data)
    ny=len(a.latitude.data)

    cmaps = {'t2m': 'bwr', 'msl':'PiYG', 'u10':'RdBu_r', 'v10':'RdBu_r',
            'huss': 'gist_earth', 'siconc': 'bwr', 'sst':'bwr', 'ssrd':'jet', 'strd':'jet',
            'trr':'jet_r', None:'viridis'}

    levels= {'t2m': np.arange(0,32,2), 'msl':np.linspace(960e2,1030e2,21), 'u10':np.linspace(-10,10,21), 'v10':np.linspace(-10,10,21),
            'huss': np.linspace(.001,.02,11), 'siconc': np.linspace(0,50,16), 'sst':np.arange(0,32,2), 'ssrd':np.linspace(100,450,16), 'strd':np.linspace(100,450,16),
            'trr':np.linspace(0,1e3,11), None:np.linspace(0,1,11)}

    for v in a.keys():
        print(v)
        if v in ['t2m','sst']:
                a[v]=a[v]-273.15
        elif v in ['ssrd','strd']:
                a[v]=a[v]/3600
    
    try:
        a[v][0,0,:,:].plot(size=10,cmap=cmaps[v], levels=levels[v])
        plt.savefig(f"FORC_{v}.png")
        plt.clf()
    except:
        a[v][0,:,:].plot(size=10,cmap=cmaps[v], levels=levels[v])
        plt.savefig(f"FORC_{v}.png")
        plt.clf()


    if v in ['trr']:
        b=(a[v]*3600).groupby(a.time.dt.month).sum()
        print(b.max())
    else:
        b=a[v].groupby(a.time.dt.month).mean()
    lat_t=-10 ; lon_t=330
    try:
        b[:,0].sel(latitude=-10,longitude=330).plot(size=10)
        plt.savefig(f"FORC_{v}_monthly.png")
        plt.clf()
    except:
        b[:].sel(latitude=-10,longitude=330).plot(size=10)
        plt.savefig(f"FORC_{v}_monthly.png")
        plt.clf()
    for t in range(len(b.month)):
        try:
            b[t,0,:,:].plot(size=10,cmap=cmaps[v], levels=levels[v])
            plt.savefig(f"FORC_{v}_mo{t}.png")
            plt.clf()
        except:
            b[t,:,:].plot(size=10,cmap=cmaps[v], levels=levels[v])
            plt.savefig(f"FORC_{v}_mo{t}.png")
            plt.clf()
    plt.close()        
    a.close()
print('done')
quit()
