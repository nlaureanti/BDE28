#!/Volumes/A1/workdir/nicole/bin/python
import xarray as xr
import matplotlib.pyplot as plt
import os

dir='/home/nicole/workdir/SWA14/boundary_final/'
print(f'{dir}')
files=os.listdir(f'{dir}')
print(files)

for f in files:
    print(f'{dir}{f}')
    a=xr.open_dataset(f'{dir}{f}')
    n=f.split('_')[1]
    print(n)
    try:
        nz=len(a[f'nz_segment_{n}'].data)
    except:
        pass
    nx=len(a[f'nx_segment_{n}'].data)
    ny=len(a[f'ny_segment_{n}'].data)

    cmaps = {'temp': 'jet', 'zeta':'PiYG', 'u':'nipy_spectral', 'v':'nipy_spectral',
            'salt': 'gist_earth', 'dz':'ocean'}

    for v in a.keys():
        print(v)
    
        try:
            a[v][0,:,0,:].plot(size=10,cmap=[v.split('_')[0]])
            plt.savefig(f"OBC_{v}.png")
            plt.clf()
        except:
            try:
                a[v][0,:,-1,:].plot(size=10,cmap=cmaps[v.split('_')[0]])
                plt.savefig(f"OBC_{v}.png")
                plt.clf()
            except:
                try:
                    a[v][0,:,:,-1].plot(size=10,cmap=cmaps[v.split('_')[0]])
                    plt.savefig(f"OBC_{v}.png")
                    plt.clf()
                except:
                    pass

        for z in [0,nz-1]:

            try:
                a[v][0,z,:,:].plot(size=10,cmap=cmaps[v.split('_')[0]])
                plt.savefig(f"OBC_{v}_{z}.png")
                plt.clf()
            except:
                a[v][0,:,:].plot(size=10)
                plt.savefig(f"OBC_{v}_{z}.png")
                plt.clf()
    a.close()
print('done')
quit()
