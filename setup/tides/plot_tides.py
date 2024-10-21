

import xarray as xr
import matplotlib.pyplot as plt
import sys

try:
    dir=sys.argv[1]
except:
    dir='~/workdir/SWA14/INPUT/'

tu=[] ; tz=[]
for i in range(1,4):
    tu.append(xr.open_dataset(f'{dir}/tu_00{i}.nc'))
    tz.append(xr.open_dataset(f'{dir}/tz_00{i}.nc'))

tide=[
    "m2",  
    "s2",  
    "n2",  
    "k2",  
    "k1",  
    "o1",  
    "p1",  
    "q1",  
    "mm",  
    "mf",  
    ]
border=['north','south','east']
for m in range(1):
    for i in range(1,4):
        tz[i-1][f'zamp_segment_00{i}'][0,m,:,:].plot(size=12,label=f'{tide[m]} {border[i-1]}')
        plt.legend()
        plt.savefig(f'zamp_segment_00{i}_{tide[m]}.png')

        tu[i-1][f'uamp_segment_00{i}'][0,m,:,:].plot(label=f'{tide[m]} {border[i-1]}',size=12)
        plt.legend()
        plt.savefig(f'uamp_segment_00{i}_{tide[m]}.png')

        tu[i-1][f'vamp_segment_00{i}'][0,m,:,:].plot(label=f'{tide[m]} {border[i-1]}',size=12)
        plt.legend()
        plt.savefig(f'vamp_segment_00{i}_{tide[m]}.png')

        tz[i-1][f'zphase_segment_00{i}'][0,m,:,:].plot(label=f'{tide[m]} {border[i-1]}',size=12)
        plt.legend()
        plt.savefig(f'zphase_segment_00{i}_{tide[m]}.png')

        tu[i-1][f'uphase_segment_00{i}'][0,m,:,:].plot(label=f'{tide[m]} {border[i-1]}',size=12)
        plt.legend()
        plt.savefig(f'uphase_segment_00{i}_{tide[m]}.png')

        tu[i-1][f'vphase_segment_00{i}'][0,m,:,:].plot(label=f'{tide[m]} {border[i-1]}',size=12)
        plt.legend()
        plt.savefig(f'vphase_segment_00{i}_{tide[m]}.png')




