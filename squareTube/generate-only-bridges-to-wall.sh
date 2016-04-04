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
hb=$(echo "2*($rp - sqrt($rp*$rp - $rb*$rb))" | bc -l)
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

#Make STL folder
cd STLfolder

echo " "
echo "########################################"
echo "#        Creating bed STL: start       #"
echo "########################################"
echo " "
cont2=$(wc -l ../DEMsimulation/post/dumpSpheres | awk '{print $1}')
cont1=$(echo "$cont2-1" | bc -l)
b=0
a=0
echo "solid" > bridges.stl
for i in $(seq 1 $cont1)
do
	xi=$(sed -n "${i}p" ../DEMsimulation/post/dumpSpheres | awk '{print $2}')
	yi=$(sed -n "${i}p" ../DEMsimulation/post/dumpSpheres | awk '{print $3}')
	zi=$(sed -n "${i}p" ../DEMsimulation/post/dumpSpheres | awk '{print $4}')
	radius=$(sed -n "${i}p" ../DEMsimulation/post/dumpSpheres | awk '{print $1}')
	xk=$halfLbox
	yk=$yi
	zk=$zi
	distanceCenter=$(echo "($xi*$xi+$xk*$xk-2*$xi*$xk)+($yi*$yi+$yk*$yk-2*$yi*$yk)+($zi*$zi+$zk*$zk-2*$zi*$zk)" | bc -l)
	DpSquare=$(echo "$rp*$rp + 0.05*$rp" | bc -l)
	hwb=$(echo "2*$hb" | bc -l)
	distanceBridge=$(awk 'BEGIN{ print "'$distanceCenter'"<"'$DpSquare'" }')   
	if [  "$distanceBridge" -eq 1 ]
	then
		echo "Creating bridge between spheres $i and x-max-wall"
		surfaceTransformPoints -scale "($rb $hwb $rb)" ../mandatoryFiles/startingBridge.stl sphere1.stl > log
		surfaceTransformPoints -rotate "( (0 1 0) (1 0 0) )" sphere1.stl sphere2.stl > log
		surfaceTransformPoints -translate "($xk $yk $zk)" sphere2.stl sphere3.stl > log
		sed "/^solid/d" sphere3.stl | sed "/^endsolid/d" >> bridges.stl 
		rm -f log
		a=$(echo "$a+1" | bc -l)
		if [ $a -gt $b_per_block ]
		then
			b=$(echo "$b+1" | bc -l)
			echo "endsolid" >> bridges.stl
			admesh bridges.stl -bbridges_$b.stl > log
			rm -f bridges.stl
			echo "solid" > bridges.stl
			a=0
		fi
	fi

	xk=-$halfLbox
	yk=$yi
	zk=$zi
	distanceCenter=$(echo "($xi*$xi+$xk*$xk-2*$xi*$xk)+($yi*$yi+$yk*$yk-2*$yi*$yk)+($zi*$zi+$zk*$zk-2*$zi*$zk)" | bc -l)
	DpSquare=$(echo "$rp*$rp + 0.05*$rp" | bc -l)
	hwb=$(echo "2*$hb" | bc -l)
	distanceBridge=$(awk 'BEGIN{ print "'$distanceCenter'"<"'$DpSquare'" }')   
	if [  "$distanceBridge" -eq 1 ]
	then
		echo "Creating bridge between spheres $i and x-min-wall"
		surfaceTransformPoints -scale "($rb $hwb $rb)" ../mandatoryFiles/startingBridge.stl sphere1.stl > log
		surfaceTransformPoints -rotate "( (0 1 0) (1 0 0) )" sphere1.stl sphere2.stl > log
		surfaceTransformPoints -translate "($xk $yk $zk)" sphere2.stl sphere3.stl > log
		sed "/^solid/d" sphere3.stl | sed "/^endsolid/d" >> bridges.stl 
		rm -f log
		a=$(echo "$a+1" | bc -l)
		if [ $a -gt $b_per_block ]
		then
			b=$(echo "$b+1" | bc -l)
			echo "endsolid" >> bridges.stl
			admesh bridges.stl -bbridges_$b.stl > log
			rm -f bridges.stl
			echo "solid" > bridges.stl
			a=0
		fi
	fi

	xk=$xi
	yk=$halfLbox
	zk=$zi
	distanceCenter=$(echo "($xi*$xi+$xk*$xk-2*$xi*$xk)+($yi*$yi+$yk*$yk-2*$yi*$yk)+($zi*$zi+$zk*$zk-2*$zi*$zk)" | bc -l)
	DpSquare=$(echo "$rp*$rp + 0.05*$rp" | bc -l)
	hwb=$(echo "2*$hb" | bc -l)
	distanceBridge=$(awk 'BEGIN{ print "'$distanceCenter'"<"'$DpSquare'" }')   
	if [  "$distanceBridge" -eq 1 ]
	then
		echo "Creating bridge between spheres $i and y-max-wall"
		surfaceTransformPoints -scale "($rb $hwb $rb)" ../mandatoryFiles/startingBridge.stl sphere2.stl > log
		surfaceTransformPoints -translate "($xk $yk $zk)" sphere2.stl sphere3.stl > log
		sed "/^solid/d" sphere3.stl | sed "/^endsolid/d" >> bridges.stl 
		rm -f log
		a=$(echo "$a+1" | bc -l)
		if [ $a -gt $b_per_block ]
		then
			b=$(echo "$b+1" | bc -l)
			echo "endsolid" >> bridges.stl
			admesh bridges.stl -bbridges_$b.stl > log
			rm -f bridges.stl
			echo "solid" > bridges.stl
			a=0
		fi
	fi

	xk=$xi
	yk=-$halfLbox
	zk=$zi
	distanceCenter=$(echo "($xi*$xi+$xk*$xk-2*$xi*$xk)+($yi*$yi+$yk*$yk-2*$yi*$yk)+($zi*$zi+$zk*$zk-2*$zi*$zk)" | bc -l)
	DpSquare=$(echo "$rp*$rp + 0.05*$rp" | bc -l)
	hwb=$(echo "2*$hb" | bc -l)
	distanceBridge=$(awk 'BEGIN{ print "'$distanceCenter'"<"'$DpSquare'" }')   
	if [  "$distanceBridge" -eq 1 ]
	then
		echo "Creating bridge between spheres $i and y-min-wall"
		surfaceTransformPoints -scale "($rb $hwb $rb)" ../mandatoryFiles/startingBridge.stl sphere2.stl > log
		surfaceTransformPoints -translate "($xk $yk $zk)" sphere2.stl sphere3.stl > log
		sed "/^solid/d" sphere3.stl | sed "/^endsolid/d" >> bridges.stl 
		rm -f log
		a=$(echo "$a+1" | bc -l)
		if [ $a -gt $b_per_block ]
		then
			b=$(echo "$b+1" | bc -l)
			echo "endsolid" >> bridges.stl
			admesh bridges.stl -bbridges_$b.stl > log
			rm -f bridges.stl
			echo "solid" > bridges.stl
			a=0
		fi
	fi
done
if [ $a != 0 ]
then
	echo "endsolid" >> bridges.stl
	b=$(echo "$b+1" | bc -l)
	admesh bridges.stl -bbridges_$b.stl > log
	rm -f bridges.stl
else
	rm -f bridges.stl
fi

rm -f sphere1.stl sphere2.stl sphere3.stl log

cp bed-backup.stl bed.stl
cp bed-backup.stl bed-cut.stl
cp bridges_1.stl b1.stl
echo " "
for i in $(seq 1 $b)
do
	if [ $i != 1 ]
	then
		echo "Merging bridges' block $i"
		surfaceAdd bridges_$i.stl b1.stl b2.stl -mergeRegions > log
		rm -f b1.stl
		mv b2.stl b1.stl
	fi

	rm -f run.scad	
	touch run.scad
	echo "union()" >> run.scad
	echo "{"  >> run.scad
	echo "	import(\"bridges_$i.stl\");" >> run.scad
	echo "	import(\"bed.stl\");"   >> run.scad
	echo "}"  >> run.scad
	echo "Adding bridges' block $i" 
	openscad -o sphere2.stl run.scad
	rm -r bed.stl
	mv sphere2.stl  bed.stl

	rm -f run.scad
	touch run.scad
	echo "difference()" >> run.scad
	echo "{"  >> run.scad
	echo "	import(\"bed-cut.stl\");"   >> run.scad
	echo "	import(\"bridges_$i.stl\");" >> run.scad
	echo "}"  >> run.scad
	echo "Removing bridges' block $i" 
	openscad -o sphere2.stl run.scad
	rm -r bed-cut.stl
	mv sphere2.stl  bed-cut.stl

done
admesh bed.stl -bbinary.stl > log
mv binary.stl bed.stl
admesh bed-cut.stl -bbinary.stl > log
mv binary.stl bed-cut.stl
rm -f log run.scad
admesh b1.stl -bbridges-all.stl > log 
rm -f b1.stl
echo " "
echo "########################################"
echo "#        Creating bed STL: done        #"
echo "########################################"
	
