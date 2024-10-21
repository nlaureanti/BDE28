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
dir_saida='/home/nicole/workdir/SWA14/mine_boundary_final002/'

# Regional model definitions
fgrid='/home/nicole/workdir/SWA14/grid/ocean_hgrid.nc'
lati='-55'
latf='5'
loni='-69'
lonf='-9'

#lati='-40'
#latf='-20'
#loni='300'
#lonf='340'

ocean_topog='/home/nicole/workdir/SWA14/grid/ocean_topog.nc'

# PAra uso de remapeamento
dirdata='/home/nicole/workdir/glorys/2001/'
fnames=('glorys_2001-merge.nc'
       'glorys_2001-merge.nc'
	'glorys_2001-merge.nc'
 	'glorys_2001-merge.nc'
	'glorys_2001-merge.nc')

#vvars=('temp' 'salt' 'ssh' 'u' 'v' )
vvars=( 'thetao' 'so'  'uo' 'vo' 'zos')


################################################################################
################################################################################

if [[ ${#1} == 0 ]] ;then 
read -p "remap_obc_python? 1-yes 0-no    " remap_obc_python
else
remap_obc_python=$1
fi

source /home/nicole/lib.sh
src="$(pwd)/src/"
cdo='/home/nicole/workdir/envs/cdo_env/bin/cdo'
mkdir -p $dir_saida
cd $dir_saida
rm -f dz_*
#for n in $(seq 0 $(( ${#vvars[@]} -1 )) ); do
for n in 1 ; do
    v=${vvars[n]}
    fname=${fnames[n]}

    #Definições
    fronteiraname=("north" "south" "east")

    #Cria arquivos de grade regional vazios em netcdf
    echo -ne "> ${mr}Regional: ${fim}\n "
    
    if [[ $remap_obc_python = 1 ]]; then
        $cdo -L -s showname ${dirdata}$fname
        for n in 0 1 2 ; do
        echo -ne "${bg_mr} Remapeando ${fim} obcs $v ${fronteiraname[$n]}\n"
	${src}/remap_obc_from_glorys.sh ${fgrid} ${dirdata}${fname} $ocean_topog ${v} ${fronteiraname[$n]} $lati $latf $loni $lonf || exit #2> python.log || exit

        done          
        
    fi
done

set -x 
    for n in 0 1 2 ; do
        rm -f ${fronteiraname[$n]}_obc_glorys.nc
        $cdo -s -merge obc_*_${fronteiraname[$n]}.nc ${fronteiraname[$n]}_obc_glorys.nc
    done

#rm -f dz_* regrid_* #temporarios
cd - &>>/dev/null
echo "FIM!"

