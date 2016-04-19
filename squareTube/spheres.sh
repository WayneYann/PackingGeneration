#!/bin/bash

#Reading parameters for LIGGGHTS simulation from shell
Nspheres=$(cat STLfolder/DEM.info | grep 'Num' | awk '{print$4}')
Dp=$(cat STLfolder/DEM.info | grep 'P' | awk '{print$3}') 
Lbox=$(cat STLfolder/DEM.info | grep 'Bo' | awk '{print$3}') 
halfLbox=$(echo "$Lbox*0.5" | bc -l)
cd STLfolder
echo " "
echo "########################################"
echo "#        Creating bed STL: start       #"
echo "########################################"
cont=$(wc -l ../DEMsimulation/post/dumpSpheres | awk '{print $1}')
rm -f run.scad
touch run.scad
echo "union()" >> run.scad
echo "{"  >> run.scad
for i in $(seq 1 $cont)
do
	echo "Creating sphere $i"
	x=$(sed -n "${i}p" ../DEMsimulation/post/dumpSpheres | awk '{print $2}')
	y=$(sed -n "${i}p" ../DEMsimulation/post/dumpSpheres | awk '{print $3}')
	z=$(sed -n "${i}p" ../DEMsimulation/post/dumpSpheres | awk '{print $4}')
	radius=$(sed -n "${i}p" ../DEMsimulation/post/dumpSpheres | awk '{print $1}')
	echo "translate([$x,$y,$z])"  >> run.scad
	echo "sphere(\$fn = 38, \$fa = 12, \$fs = 2, r = $radius);" >> run.scad
done
echo "}"  >> run.scad
openscad -o spheres.stl run.scad
admesh spheres.stl -bbinary.stl > log
rm -f spheres.stl log
mv binary.stl spheres.stl
rm -f *scad
echo "########################################"
echo "#        Creating bed STL: done        #"
echo "########################################"
