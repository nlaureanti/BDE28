

import xarray as xr
import matplotlib.pyplot as plt
import sys

try:
    dir=sys.argv[1]
except:
    dir= '/Volumes/A1/workdir/kate/ESMG/ESMG-configs/Bering/INPUT/'

tu=[] ; tz=[]
for i in range(1,4):
    tu.append(xr.open_dataset(f'{dir}/tu00{i}.nc'))
    tz.append(xr.open_dataset(f'{dir}/tz00{i}.nc'))

tide=[
    "m2  ",  
    "s2  ",  
    "n2  ",  
    "k2  ",  
    "k1  ",  
    "o1  ",  
    "p1  ",  
    "q1  ",  
    "mm  ",  
    "mf  ",  
    ]
for m in range(0,10):
    for i in range(1,4):
        tu[i-1][f'uamp_segment_00{i}'][0,m,:,:].plot(label=f'{tide[m]}')
        tz[i-1][f'zamp_segment_00{i}'][0,m,:,:].plot(label=f'{tide[m]}')
        plt.legend()

#plt.show()
plt.clf()

tide=["M2","S2","N2","K2","K1","O1","P1","Q1","MM","MF"]
for n in range(1,4):
    for t in range(len(tide)): 
        tu[n-1][f'uamp_segment_00{n}'][0,t,:,:].plot(label=f'tu_00{n} {tide[t]}')
        tz[n-1][f'zamp_segment_00{n}'][0,t,:,:].plot(label=f'tz_00{n} {tide[t]}')
        
        plt.legend(bbox_to_anchor=(1.05, 1),
                         loc='upper left', borderaxespad=0.,ncol=4)
    plt.savefig(f'OBC_Tamp_00{n}.png')
    plt.show()
    plt.clf()    

tide=["M2","S2","N2","K2","K1","O1","P1","Q1","MM","MF"]
for n in range(1,4):
    for t in range(len(tide)): 
        tu[n-1][f'uphase_segment_00{n}'][0,t,:,:].plot(label=f'tu_00{n} {tide[t]}')
        tz[n-1][f'zphase_segment_00{n}'][0,t,:,:].plot(label=f'tz_00{n} {tide[t]}')
        
        plt.legend(bbox_to_anchor=(1.05, 1),
                         loc='upper left', borderaxespad=0.,ncol=4)
    plt.savefig(f'OBC_Tphase_00{n}.png')
    plt.show()
    plt.clf()       
