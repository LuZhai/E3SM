#!/bin/bash
#
#SBATCH --job-name dcmip2016-1
#SBATCH -N 128
#SBATCH -C knl
#SBATCH --time=0:30:00
#SBATCH -q debug
#
#


#
#  mpi run command
#
export OMP_STACKSIZE=16M     #  Cori has 96GB per node. had to lower to 8M on 3K nodes
export OMP_NUM_THREADS=2
PER_NODE=64          #  MPI per node

# number of virtual cores per MPI task
VC_PER_MPI=256  # Set this to 272 if using PER_NODE divides 272 instead of 256
let VC_PER_MPI/=$PER_NODE

export KMP_AFFINITY="granularity=core,scatter"
bind=--cpu_bind=core

# compute number of MPI tasks
if [ -n "$SLURM_NNODES" ]; then
  NNODES=$SLURM_NNODES
else
  NNODES=1
fi


NMPI=$NNODES
let NMPI*=$PER_NODE

echo NODES =            $NNODES
echo NMPI_PER_NODE =    $PER_NODE
echo NTHREADS_PER_MPI = $OMP_NUM_THREADS
mpirun="srun -n $NMPI -N $NNODES -c $VC_PER_MPI $bind"
echo mpi commnand:
echo $mpirun


# hydrostatic preqx
EXEC=../../../test_execs/theta-l-nlev30/theta-l-nlev30

function run { 
local NCPU=$1
echo "NCPU = $NCPU"
namelist=namelist-$prefix.nl
\cp -f $namelist input.nl
date
$mpirun  $EXEC < input.nl
date

ncl plot-baroclinicwave-init.ncl
ncl plot-lat-lon-TPLSPS.ncl 'var_choice=1'
ncl plot-lat-lon-TPLSPS.ncl 'var_choice=2'
ncl plot-lat-lon-TPLSPS.ncl 'var_choice=3'
\mv -f plot_baroclinicwave_init.pdf  ${prefix}_init.pdf
\mv -f preqx-test16-1latlonT850.pdf  ${prefix}_T850.pdf
\mv -f preqx-test16-1latlonPS.pdf  ${prefix}_PS.pdf
\mv -f preqx-test16-1latlonPRECL.pdf  ${prefix}_PRECL.pdf

\mv -f movies/dcmip2016_test11.nc    movies/${prefix}_dcmip2016_test11.nc
}

prefix=r400    ; run $(($NCPU>384?384:NCPU))

prefix=r100-dry; run $NCPU
prefix=r100-h  ; run $NCPU
prefix=r100    ; run $NCPU

prefix=r50    ; run $NCPU

# high res cases
#prefix=ne120  ; run $NCPU       
#prefix=ne256  ; run $NCPU       
#prefix=ne512  ; run $NCPU       
#prefix=ne1024  ; run $NCPU      

# cori-KNL timings
#  ne=120  25 nodes, 2h:  23s
#  ne=256  25 nodes, 2h:  142s
#  ne=512  64 nodes, 2h:  533s
#  ne=1024  512 nodes, 270 timsteps:   596s + init 
#      init time if run 16x8: 400s
#      init time if run 64x2: 1400s
#
#
#






