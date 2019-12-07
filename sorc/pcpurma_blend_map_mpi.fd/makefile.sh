set -x
mpif90 -O3 -fp-model strict -convert big_endian -traceback -free -o pcpurma_blend_map_mpi blending_map_mpi.f90
mv pcpurma_blend_map_mpi ../../exec
