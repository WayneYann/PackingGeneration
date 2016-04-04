#!/bin/bash
echo "################################################"
echo "#                                              #"
echo "#          Create packed bed mesh with         #"
echo "#        LIGGGHTS and OPENFOAM and AdMesh      #"
echo "#                                              #"
echo "################################################"

#Help
if [ $# != 6 ]
then
	echo "Input order:"
	echo "1:   Number of particles"
	echo "2:   Particle diameter"
	echo "3:   Box diameter"
	echo "4:   Convergence velocity (>0)"
	echo "5:   Bridge diameter"
	echo "6:   Bridge per block"
	exit 1
fi

#Reading parameters for LIGGGHTS simulation from shell
Nspheres=$1                                #First  input:  number of particles
Dp=$2                                      #Second input:  particle diameter
Lbox=$3                                    #Third  input:  box side
v=$4                                       #Fourth input:  tresh velocity
Db=$5					   #Fifth  input:  bridge diameter
b_per_block=$6				   #Sixth  input:  bridge per block
halfLbox=$(echo "$Lbox*0.5" | bc -l)
rb=$(echo "$Db*0.5" | bc -l)
rp=$(echo "$Dp*0.5" | bc -l)
hb=$(echo "($rp - sqrt($rp*$rp - $rb*$rb))*1.01" | bc -l)
rBox=$(echo "$Lbox*0.5" | bc -l)

#Check input parameter for LIGGGHTS
dimensionComparisons=$(awk 'BEGIN{ print "'$Lbox'"<"'$Dp'" }')   
if [  "$dimensionComparisons" -eq 1 ]
then
	echo "ERROR: Particle diameter is bigger than box side"
	exit 1
fi

dimensionComparisons=$(awk 'BEGIN{ print "'$Dp'"<"'$Db'" }')   
if [  "$dimensionComparisons" -eq 1 ]
then
	echo "ERROR: Bridge diameter is bigger than particle diameter"
	exit 1
fi

velocityComparisons=$(awk 'BEGIN{ print "'$v'"<"'0.00001'" }')   
if [  "$velocityComparisons" -eq 1 ]
then
	echo "WARNING: Convergence velocity is too small, set to 1e-05"
	read -p "Press [Enter] key to continue..."
	v=0.00001
fi

#Creating directory for LIGGGHTS simulation
rm -rf DEM*
mkdir DEMsimulation
cd DEMsimulation
mkdir post

#Preparing LIGGGHTS input file
sed "s/##Particle_diameter##/$Dp/g" ../mandatoryFiles/in.packing > in.liggghts
sed "s/##Particle_number##/$Nspheres/g" -i in.liggghts
sed "s/##Box_half_side##/$halfLbox/g" -i in.liggghts
sed "s/##Tresh_velocity##/$v/g" -i in.liggghts

#Run LIGGGHTS simulation
liggghts < in.liggghts

cd ..

#Find latest file in post folder
spheresFileName=$(ls -t DEMsimulation/post | sed -n "1p")

#Remove the first 9 line of the file (NOT required)
sed '1,9d' DEMsimulation/post/$spheresFileName > DEMsimulation/post/dumpSpheres

#Make STL folder
rm -rf STL*
mkdir STLfolder
cd STLfolder

echo " "
echo "########################################"
echo "#        Creating bed STL: start       #"
echo "########################################"
echo " "
sed "s/e/*10^/g" -i ../DEMsimulation/post/dumpSpheres
sed "s/E/*10^/g" -i ../DEMsimulation/post/dumpSpheres
cont2=$(wc -l ../DEMsimulation/post/dumpSpheres | awk '{print $1}')
cont1=$(echo "$cont2-1" | bc -l)
echo " "
echo "Creating sphere 1"
cont=$(wc -l ../DEMsimulation/post/dumpSpheres | awk '{print $1}')
x=$(sed -n "1p" ../DEMsimulation/post/dumpSpheres | awk '{print $2}')
y=$(sed -n "1p" ../DEMsimulation/post/dumpSpheres | awk '{print $3}')
z=$(sed -n "1p" ../DEMsimulation/post/dumpSpheres | awk '{print $4}')
radius=$(sed -n "1p" ../DEMsimulation/post/dumpSpheres | awk '{print $1}')
surfaceTransformPoints -scale "($radius $radius $radius)" ../mandatoryFiles/startingSphere.stl sphere1.stl > log
surfaceTransformPoints -translate "($x $y $z)" sphere1.stl spheres.stl > log

for i in $(seq 2 $cont)
do
	echo "Creating sphere $i"
	x=$(sed -n "${i}p" ../DEMsimulation/post/dumpSpheres | awk '{print $2}')
	y=$(sed -n "${i}p" ../DEMsimulation/post/dumpSpheres | awk '{print $3}')
	z=$(sed -n "${i}p" ../DEMsimulation/post/dumpSpheres | awk '{print $4}')
	radius=$(sed -n "${i}p" ../DEMsimulation/post/dumpSpheres | awk '{print $1}')
	surfaceTransformPoints -scale "($radius $radius $radius)" ../mandatoryFiles/startingSphere.stl sphere1.stl > log
	surfaceTransformPoints -translate "($x $y $z)" sphere1.stl $i.stl > log

	rm -f run.scad
	touch run.scad
	echo "union()" >> run.scad
	echo "{"  >> run.scad
	echo "	import(\"$i.stl\");" >> run.scad
	echo "	import(\"spheres.stl\");"   >> run.scad
	echo "}"  >> run.scad

	openscad -o sphere2.stl run.scad
	rm -r spheres.stl
	mv sphere2.stl  spheres.stl
	rm -f log $i.stl
done

admesh spheres.stl -bbinary.stl > log
mv binary.stl spheres.stl
rm -f sphere1.stl sphere2.stl 
cp spheres.stl bed.stl
cp spheres.stl bed-cut.stl
cp spheres.stl bed-backup.stl
echo " "
echo "########################################"
echo "#        Creating bed STL: done        #"
echo "########################################"
	
