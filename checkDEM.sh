if [ $# != 1 ]
then
	echo "Input order:"
	echo "1:   .stl file name (without extection)"
	exit 1
fi

cd STLfolder
name=$1

surfaceCheck -blockMesh $name.stl > log.surfaceCheck
rm *obj *vtk

xMin=$(sed -n 26p log.surfaceCheck | sed "s/)//g" | sed "s/(//g" | awk '{print $4}' )
yMin=$(sed -n 26p log.surfaceCheck | sed "s/)//g" | sed "s/(//g" | awk '{print $5}' )
zMin=$(sed -n 26p log.surfaceCheck | sed "s/)//g" | sed "s/(//g" | awk '{print $6}' )
xMax=$(sed -n 26p log.surfaceCheck | sed "s/)//g" | sed "s/(//g" | awk '{print $7}' )
yMax=$(sed -n 26p log.surfaceCheck | sed "s/)//g" | sed "s/(//g" | awk '{print $8}' )
zMax=$(sed -n 26p log.surfaceCheck | sed "s/)//g" | sed "s/(//g" | awk '{print $9}' )

Dt=$(echo "($yMax - $yMin)" | bc -l)
zC=$(echo "($zMin+$zMax)*0.5" | bc -l)
zLow=$(echo "$zC - $Dt" | bc -l)
zHigh=$(echo "$zC + $Dt" | bc -l)

echo '/*--------------------------------*- C++ -*----------------------------------*\' >> subSetDict
echo '| =========                 |                                                 |' >> subSetDict
echo '| \\      /  F ield         | OpenFOAM: The Open Source CFD Toolbox           |' >> subSetDict
echo '|  \\    /   O peration     | Version:  3.0.x                                 |' >> subSetDict
echo '|   \\  /    A nd           | Web:      www.OpenFOAM.org                      |' >> subSetDict
echo '|    \\/     M anipulation  |                                                 |' >> subSetDict
echo '\*---------------------------------------------------------------------------*/' >> subSetDict
echo 'FoamFile' >> subSetDict
echo '{' >> subSetDict
echo '    version     2.0;' >> subSetDict
echo '   format      ascii;' >> subSetDict
echo '    class       dictionary;' >> subSetDict
echo '    object      surfaceSubsetDict;' >> subSetDict
echo '}' >> subSetDict
echo '// * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * //' >> subSetDict
echo 'faces ();' >> subSetDict
echo 'localPoints ( );' >> subSetDict
echo 'edges ();' >> subSetDict
echo 'zone' >> subSetDict
echo '(' >> subSetDict
echo "    ($xMin $yMin $zLow)" >> subSetDict
echo "    ($xMax $yMax $zHigh)" >> subSetDict
echo ');' >> subSetDict
echo 'addFaceNeighbours no;' >> subSetDict
echo 'invertSelection false;' >> subSetDict
echo '// ************************************************************************* //' >> subSetDict

surfaceSubset subSetDict $name.stl $name-center.stl > log.subSet
rm subSetDict log.subSet
admesh $name-center.stl > ../stl.properties
