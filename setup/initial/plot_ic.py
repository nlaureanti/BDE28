#!/Volumes/A1/workdir/nicole/bin/python
import xarray as xr
import matplotlib.pyplot as plt


ic=xr.open_dataset('/Volumes/A1/workdir/nicole/SWA14/INPUT/glorys_ic_75z_1997.nc')

#################################################################################
def colors_default(var):
        import numpy as np
        cmaps = {'temp': 'turbo','sst': 'turbo', 'thetao': 'turbo', 'Temp': 'turbo',
                'SSH':'seismic', 'ssh':'seismic', 'zos':'seismic', 'zeta':'seismic', 
                'ave_ssh':'seismic',
                'u':'bwr', 'v':'bwr', 'uo':'bwr', 'vo':'bwr',
                'dudy':'bwr', 'dvdx':'bwr',
                'ssu':'bwr', 'ssv':'bwr',
                'omldamax': 'gist_earth', 'dz': 'gist_earth',
                'salt': 'gist_earth',  'sss': 'gist_earth',  'so': 'gist_earth',
                'Salt': 'gist_earth',  
                'dz':'ocean', 
                'speed':'gist_rainbow_r',
                'vort':'Blues_r'}

        levels = {'temp': np.arange(0,32,2), 'sst': np.arange(0,32,2),'thetao': np.arange(0,32,2),
                'Temp': np.arange(0,32,2), 'ave_ssh':np.arange(-0.6,0.7,0.1),
                'Salt': np.arange(0,40,1),
                'SSH':np.arange(-0.6,0.7,0.1),'ssh':np.arange(-0.6,0.7,0.1),
                 'zos':np.arange(-0.6,0.7,0.1), 'zeta':np.arange(-0.6,0.7,0.1),
                'u':np.arange(-1.0,1.1,0.1),'v':np.arange(-1.0,1.1,0.1), 
                'uo':np.arange(-1.0,1.1,0.1),'vo':np.arange(-1.0,1.1,0.1),
                'ssu':np.arange(-1.0,1.1,0.1),'ssv':np.arange(-1.0,1.1,0.1),
                'dudy':np.arange(-1.0,1.1,0.1),'dvdx':np.arange(-1.0,1.1,0.1),
                'omldamax':np.linspace(0,300,16),'dz':np.linspace(0,300,16),
                'salt': np.arange(0,40,1),'sss': np.arange(0,40,1), 'so': np.arange(0,40,1),
                'speed':np.linspace(0,1.5,25),
                'vort':np.arange(-0.5,0.505,0.05)}

        labels = {'temp':"Temperature [°C]",'sst':"Temperature [°C]",'thetao':"Temperature [°C]",
                'SSH':'Sea Surface Height [m]', 'ssh':'Sea Surface Height [m]',
                'zos':'Sea Surface Height [m]', 'zeta':'Sea Surface Height [m]',
                'Temp': "Temperature [°C]", 'ave_ssh':'Sea Surface Height [m]',
                'Salt': 'Salinity [psu]',  
                'salt': 'Salinity [psu]','sss': 'Salinity [psu]','so': 'Salinity [psu]',
                'omldamax': 'Mixed Layer Depth [m]','dz': 'dz - thickness [m]',
                'v':'meridional velocity [ms-1]','u':'zonal velocity [ms-1]',
                'vo':'meridional velocity [ms-1]','uo':'zonal velocity [ms-1]',
                'ssv':'velocity [ms-1]','ssu':'velocity [ms-1]',
                'dudy':'dudy [s-1]','dvdx':'dvdx [s-1]',
                'speed':'Currents speed [ms-1]',
                'vort':'$\zeta / f$'}

        return cmaps[var], levels[var], labels[var]


nz=len(ic.zl.data)
nx=len(ic.xh.data)
ny=len(ic.yh.data)

for v in ic.keys():
    print(v)
    
    try:
        ic[v][0,:,0,:].plot(size=15,cmap=colors_default(v)[0],levels=colors_default(v)[1])
        plt.savefig(f"IC{v}_south.png", bbox_inches='tight')
        plt.clf()

        ic[v][0,:,-1,:].plot(size=15,cmap=colors_default(v)[0],levels=colors_default(v)[1])
        plt.savefig(f"IC{v}_north.png", bbox_inches='tight')
        plt.clf()

        ic[v][0,:,:,-1].plot(size=15,cmap=colors_default(v)[0],levels=colors_default(v)[1])
        plt.savefig(f"IC{v}_east.png", bbox_inches='tight')
        plt.clf()
    except:
        pass

    for z in [0,nz-1]:
        try:
            ic[v][0,z,:,:].plot(size=15,cmap=colors_default(v)[0],levels=colors_default(v)[1])
            plt.savefig(f"IC{v}_{z}.png", bbox_inches='tight')
            plt.clf()
        except:
            ic[v][0,:,:].plot(size=15,cmap=colors_default(v)[0],levels=colors_default(v)[1])
            plt.savefig(f"IC{v}_{z}.png", bbox_inches='tight')
            plt.clf()

print('done')
quit()


