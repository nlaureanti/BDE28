#!/Volumes/A1/workdir/nicole/envs/getGlorys/bin/python
import warnings

import matplotlib.pyplot as plt
import numpy as np
import requests as rq
import xarray as xr
import getpass
import os.path
import os
import pandas as pd
#%matplotlib inline
warnings.simplefilter("ignore")

outpath = "/Volumes/A1/workdir/nicole/glorys/"
DATASET_ID = 'cmems_mod_glo_phy_my_0.083_P1D-m'
USERNAME = 'nlaureanti'
PASSWORD = getpass.getpass('Enter your password: ')

def copernicusmarine_datastore(dataset, username, password):
    from pydap.client import open_url
    from pydap.cas.get_cookies import setup_session
    cas_url = 'https://cmems-cas.cls.fr/cas/login'
    session = setup_session(cas_url, username, password)
    session.cookies.set("CASTGC", session.cookies.get_dict()['CASTGC'])
    database = ['my', 'nrt']
    url = f'https://{database[0]}.cmems-du.eu/thredds/dodsC/{dataset}'
    try:
        data_store = xr.backends.PydapDataStore(open_url(url, session=session))
    except:
        url = f'https://{database[1]}.cmems-du.eu/thredds/dodsC/{dataset}'
        data_store = xr.backends.PydapDataStore(open_url(url, session=session))
    return data_store

data_store = copernicusmarine_datastore(DATASET_ID, USERNAME, PASSWORD)
#--variable so --variable thetao --variable uo --variable vo --variable zos 
DS = xr.open_dataset(data_store)
DS = DS.sel(latitude=slice(-70,20), longitude=slice(-100,40))
DS = DS.drop("usi") #Northward velocity
DS = DS.drop("vsi")
DS = DS.drop("siconc") #Ice concentration
DS = DS.drop("sithick") 
DS = DS.drop("bottomT")
DS = DS.drop("mlotst")

drange = pd.date_range("2003-01-01", "2003-12-31")
#drange = pd.date_range("2011-11-01", "2012-11-01")
#drange = pd.date_range("2013-11-01", "2013-11-01")

for d in drange:
    print(d)
    temp = DS.sel(time=str(str(d.year) + "-" + str(d.month) + "-" + str(d.day)))
    if os.path.isfile(outpath + str(d.year) + "/glorys_" + str(d.year) + f'{d.month:02d}' + f'{d.day:02d}' + ".nc") == False:
        temp.to_netcdf(outpath + str(d.year) +"/glorys_" + str(d.year) + f'{d.month:02d}' + f'{d.day:02d}' + ".nc", format='NETCDF3_64BIT')
