#!/bin/bash
echo "###############################"
echo "#                             #"
echo "#    DEM simulations using    #"
echo "#           LIGGGHTS          #"
echo "#                             #"
echo "###############################"

#Help
if [ $# != 4 ]
then
	echo "Input order:"
	echo "1:   Number of particles"
	echo "2:   Particle diameter"
	echo "3:   Box diameter"
	echo "4:   Convergence velocity (>0)"
	exit 1
fi

#Reading parameters for LIGGGHTS simulation from shell
Nspheres=$1
Dp=$2  
Lbox=$3
v=$4 
halfLbox=$(echo "$Lbox*0.5" | bc -l)

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
rm -rf DEMsimulation
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

sed "s/e/*10^/g" -i ../DEMsimulation/post/dumpSpheres
sed "s/E/*10^/g" -i ../DEMsimulation/post/dumpSpheres

touch DEM.info
echo "Number of spheres: $Nspheres" >> DEM.info
echo "Particle diameter: $Dp" >> DEM.info  
echo "Box diameter:      $Lbox" >> DEM.info
echo "###############################"
echo "#          DEM: done          #"
echo "###############################"
