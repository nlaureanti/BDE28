#!/bin/bash
#
#
#    Scrip para remapear saídas do MOM6 global para o regional
#    Inputs: arquivo netcdf saídas do global + grade regional
#    Desenvolvido por Nicole C. Laureanti
#    nlaureanti@gmail.com
#
#

# Para uso de geração de g
# Global model definitions
dir_saida='/home/nicole/workdir/SWA14/mine_boundary_final/'

# Regional model definitions
fgrid='/home/nicole/workdir/SWA14/grid/ocean_hgrid.nc'
lati='-60'
latf='10'
loni='265' #loni='-90'
lonf='355' #lonf='-10'

ocean_topog='/home/nicole/workdir/SWA14/grid/ocean_topog.nc'

# PAra uso de remapeamento
#dirdata='/Volumes/P1/Data/SODA/SODA_3.3.1/2001/'
dirdata='/home/nicole/workdir/SODA/'
fnames=('soda3.3.1_5dy_ocean_reg_2001_NovDec.nc'
        'soda3.3.1_5dy_ocean_reg_2001_NovDec.nc'
        'soda3.3.1_5dy_ocean_reg_2001_NovDec.nc'
        'soda3.3.1_5dy_ocean_reg_2001_NovDec.nc'
        'soda3.3.1_5dy_ocean_reg_2001_NovDec.nc')

vvars=('temp' 'salt' 'ssh' 'u' 'v' )


################################################################################
################################################################################

if [[ ${#1} == 0 ]] ;then 
read -p "remap_obc_python? 1-yes 0-no    " remap_obc_python
else
remap_obc_python=$1
fi

source /home/nicole/lib.sh
src="$(pwd)/src/"
mkdir -p $dir_saida
cd $dir_saida
cdo='/home/nicole/workdir/envs/cdo_env/bin/cdo'

rm -f output_dz_h.nc
for n in $(seq 0 $(( ${#vvars[@]} -1 )) ); do
#for n in 3 4; do 
    v=${vvars[n]}
    fname=${fnames[n]}

    #Definições
    fronteiraname=("north" "south" "east")

    #Cria arquivos de grade regional vazios em netcdf
    echo -ne "> ${mr}Regional: ${fim} ${fronteiranc[@]} \n "

    #echo -ne "${bg_mr} Remapeando ${fim} ic_${v}.nc \n"
    #python $src/remap_ic_from_soda.sh ${fgrid} ${dirdata}${fname} ${v} initial  || exit
    
    if [[ $remap_obc_python = 1 ]]; then
        $cdo -L -s showname ${dirdata}$fname    
        echo -ne "${bg_mr} Remapeando ${fim} obcs $v \n"                    
               
        for n in 0 1 2 ; do
	if [[ $v == 'u' ]] || [[ $v == 'v' ]] ; then
		rm -f output_dz_h.nc
	fi	
		${src}/remap_obc_from_soda_v3.sh ${fgrid} ${dirdata}${fname} $ocean_topog ${v} ${fronteiraname[$n]} $lati $latf $loni $lonf || exit #2> python.log || exit	
	
        echo "dset ^obc_${v}_${fronteiraname[$n]}.nc
    options  365_day_calendar
    tdef time 145 linear 01jan2001 5dy" > obc_${v}_${fronteiraname[$n]}.ddf
        done          
        
    fi
     
   #exit

done

set -x 
    for n in 0 1 2 ; do
        rm -f ${fronteiraname[$n]}_obc.nc
        $cdo -s -merge obc_*_${fronteiraname[$n]}.nc ${fronteiraname[$n]}_obc_soda.nc
        #ncatted -a modulo,time,c,c,' ' ${fronteiraname[$n]}_obc.nc
    done

    rm -f ic_file.nc obc_file_exp_AScoast002.nc obc_*_${fronteiraname[$n]}.nc
#    cdo -s -merge ic_salt.nc ic_ssh.nc ic_temp.nc ic_u.nc ic_v.nc ic_file.nc
#    cdo -s invertlev ic_file.nc ic_file_invert.nc
    #cdo -s -merge obc_*.nc obc_file_exp_AScoast002.nc      

#grads -lbc "run ../src/script.grads.gs"  &>>/dev/null


cd - &>>/dev/null
echo "FIM!"

