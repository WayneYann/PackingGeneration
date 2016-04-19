#!/bin/bash

#Help
if [ $# != 1 ]
then
	echo "Input order:"
	echo "1:   Bridge diameter"
	exit 1
fi

#Reading parameters for LIGGGHTS simulation from shell
Db=$1

Dp=$(cat STLfolder/DEM.info | grep 'P' | awk '{print$3}') 
Lbox=$(cat STLfolder/DEM.info | grep 'Bo' | awk '{print$3}') 
halfLbox=$(echo "$Lbox*0.5" | bc -l)

rb=$(echo "$Db*0.5" | bc -l)
rp=$(echo "$Dp*0.5" | bc -l)
hb=$(echo "2*($rp - sqrt($rp*$rp - $rb*$rb))" | bc -l)
rBox=$(echo "$Lbox*0.5" | bc -l)

#Check input parameter for LIGGGHTS
dimensionComparisons=$(awk 'BEGIN{ print "'$Dp'"<"'$Db'" }')   
if [  "$dimensionComparisons" -eq 1 ]
then
	echo "ERROR: Bridge diameter is bigger than particle diameter"
	exit 1
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
rm -f run.scad
touch run.scad
rm -f temp.scad
touch temp.scad
echo "module cylALL()" >> temp.scad
echo "{"  >> temp.scad
for i in $(seq 1 $cont1)
do
	xi=$(sed -n "${i}p" ../DEMsimulation/post/dumpSpheres | awk '{print $2}')
	yi=$(sed -n "${i}p" ../DEMsimulation/post/dumpSpheres | awk '{print $3}')
	zi=$(sed -n "${i}p" ../DEMsimulation/post/dumpSpheres | awk '{print $4}')
	radius=$(sed -n "${i}p" ../DEMsimulation/post/dumpSpheres | awk '{print $1}')
	distanceCenter=$(echo "( $xi * $xi ) + ( $yi * $yi )" | bc -l)
	DtDp=$(echo "$halfLbox*$halfLbox - 2*$halfLbox*$rp + $rp*$rp" | bc -l)
	DpSquare=$(echo "$DtDp - 0.05*$DtDp" | bc -l)
	hwb=$(echo "2*$hb" | bc -l)
	distanceBridge=$(awk 'BEGIN{ print "'$DpSquare'"<"'$distanceCenter'" }')   
	if [  "$distanceBridge" -eq 1 ]
	then
		m=$(echo "$yi/$xi" | bc -l)
		z=0
		check=$(awk 'BEGIN{ print "'$xi'"<"'$z'" }')
		if [  "$check" -eq 1 ]
		then
			xk=$(echo "- sqrt($halfLbox*$halfLbox/(1+$m*$m))" | bc -l)
			yk=$(echo "$m*$xk" | bc -l)
		else
			xk=$(echo "sqrt($halfLbox*$halfLbox/(1+$m*$m))" | bc -l)
			yk=$(echo "$m*$xk" | bc -l)
		fi
		echo "Creating bridge between spheres $i and wall"
		echo "module wall$i()" >> run.scad
		echo "{"  >> run.scad
		echo "x1 = $xi;" >> run.scad
		echo "y1 = $yi;" >> run.scad
		echo "z1 = $zi;" >> run.scad
		echo "x2 = $xk;" >> run.scad
		echo "y2 = $yk;" >> run.scad
		echo "z2 = $zi;" >> run.scad
		echo "xr = x1-x2;" >> run.scad
		echo "yr = y1-y2;" >> run.scad
		echo "zr = z1-z2;" >> run.scad
		echo "xm = x2;" >> run.scad
		echo "ym = y2;" >> run.scad
		echo "zm = z2;" >> run.scad
		echo "l  = norm([xr,yr,zr]);" >> run.scad
		echo "b = acos(zr/l);" >> run.scad
		echo "c = atan2(yr,xr);" >> run.scad
		echo "translate([xm,ym,zm])" >> run.scad
		echo "rotate([0,b,c])" >> run.scad
		echo "cylinder(\$fn = 38, \$fa = 12, \$fs = 2, h = $hwb, d1 = $Db, d2 = $Db, center = true);" >> run.scad
		echo "}"  >> run.scad
		echo " "  >> run.scad
		echo "wall$i();" >> temp.scad
	fi

	cont3=$(echo "$i+1" | bc -l)
	for k in $(seq $cont3 $cont2)
	do
		xk=$(sed -n "${k}p" ../DEMsimulation/post/dumpSpheres | awk '{print $2}')
		yk=$(sed -n "${k}p" ../DEMsimulation/post/dumpSpheres | awk '{print $3}')
		zk=$(sed -n "${k}p" ../DEMsimulation/post/dumpSpheres | awk '{print $4}')
		distanceCenter=$(echo "($xi*$xi+$xk*$xk-2*$xi*$xk)+($yi*$yi+$yk*$yk-2*$yi*$yk)+($zi*$zi+$zk*$zk-2*$zi*$zk)" | bc -l)
		DpSquare=$(echo "$Dp*$Dp + 0.01*$Dp" | bc -l)
		distanceBridge=$(awk 'BEGIN{ print "'$distanceCenter'"<"'$DpSquare'" }')   
		if [  "$distanceBridge" -eq 1 ]
		then
			DpSquare=$(echo "$Dp*$Dp - 0.01*$Dp" | bc -l)
			distanceBridge1=$(awk 'BEGIN{ print "'$DpSquare'"<"'$distanceCenter'" }') 
			if [  "$distanceBridge1" -eq 1 ]
			then
				echo "Creating bridge between spheres $k and $i"
				echo "module cyl$i$k()" >> run.scad
				echo "{"  >> run.scad
				echo "x1 = $xi;" >> run.scad
				echo "y1 = $yi;" >> run.scad
				echo "z1 = $zi;" >> run.scad
				echo "x2 = $xk;" >> run.scad
				echo "y2 = $yk;" >> run.scad
				echo "z2 = $zk;" >> run.scad
				echo "xr = x1-x2;" >> run.scad
				echo "yr = y1-y2;" >> run.scad
				echo "zr = z1-z2;" >> run.scad
				echo "xm = (x1+x2)/2;" >> run.scad
				echo "ym = (y1+y2)/2;" >> run.scad
				echo "zm = (z1+z2)/2;" >> run.scad
				echo "l  = norm([xr,yr,zr]);" >> run.scad
				echo "b = acos(zr/l);" >> run.scad
				echo "c = atan2(yr,xr);" >> run.scad
				echo "translate([xm,ym,zm])" >> run.scad
				echo "rotate([0,b,c])" >> run.scad
				echo "cylinder(\$fn = 38, \$fa = 12, \$fs = 2, h = $hwb, d1 = $Db, d2 = $Db, center = true);" >> run.scad
				echo "}"  >> run.scad
				echo " "  >> run.scad
				echo "cyl$i$k();" >> temp.scad
			fi
		fi
	done



done
echo "}"  >> temp.scad
cat temp.scad >> run.scad
echo " "  >> run.scad
echo "cylALL();" >> run.scad
rm -f temp.scad
openscad -o bridges.stl run.scad
admesh bridges.stl -bbinary.stl > log
rm -f bridges.stl log
mv binary.stl bridges.stl
rm -f *scad
echo "########################################"
echo "#        Creating bed STL: done        #"
echo "########################################"
	
