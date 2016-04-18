#Help
if [ $# != 2 ]
then
	echo "Input order:"
	echo "1:   .stl file name (without extection)"
	echo "2:   Tube diameter [m]"
	exit 1
fi

name=$1
Dt=$2
r=$(echo "$Dt*0.5" | bc -l)

surfaceCheck -blockMesh STLfolder/$name.stl > log.surfaceCheck
xMin=$(sed -n 26p log.surfaceCheck | sed "s/)//g" | sed "s/(//g" | awk '{print $4}' )
yMin=$(sed -n 26p log.surfaceCheck | sed "s/)//g" | sed "s/(//g" | awk '{print $5}' )
zMin=$(sed -n 26p log.surfaceCheck | sed "s/)//g" | sed "s/(//g" | awk '{print $6}' )
xMax=$(sed -n 26p log.surfaceCheck | sed "s/)//g" | sed "s/(//g" | awk '{print $7}' )
yMax=$(sed -n 26p log.surfaceCheck | sed "s/)//g" | sed "s/(//g" | awk '{print $8}' )
zMax=$(sed -n 26p log.surfaceCheck | sed "s/)//g" | sed "s/(//g" | awk '{print $9}' )
xMinExtended=$(echo "$xMin-0.01*$xMax+0.01*$xMin" | bc -l)
xMaxExtended=$(echo "$xMax+0.01*$xMax-0.01*$xMin" | bc -l)
yMinExtended=$(echo "$yMin-0.05*$yMax+0.05*$yMin" | bc -l)
yMaxExtended=$(echo "$yMax+0.2*$yMax-0.2*$yMin" | bc -l)
zMinExtended=$(echo "$zMin-0.1*$zMax+0.1*$zMin" | bc -l)
zMaxExtended=$(echo "$zMax+0.5*$zMax-0.5*$zMin" | bc -l)

zLoc=$(echo "$zMinExtended+0.0001*$zMaxExtended-0.0001*$zMinExtended" | bc -l)
rm -f log.surfaceCheck
mkdir caseDicts
rm -f caseDicts/snappyHexMeshDict
touch caseDicts/snappyHexMeshDict
echo '/*--------------------------------*- C++ -*----------------------------------*\' >> caseDicts/snappyHexMeshDict
echo '| =========                 |                                                 |' >> caseDicts/snappyHexMeshDict
echo '| \\      /  F ield         | OpenFOAM: The Open Source CFD Toolbox           |' >> caseDicts/snappyHexMeshDict
echo '|  \\    /   O peration     | Version:  2.3.0                                 |' >> caseDicts/snappyHexMeshDict
echo '|   \\  /    A nd           | Web:      www.OpenFOAM.org                      |' >> caseDicts/snappyHexMeshDict
echo '|    \\/     M anipulation  |                                                 |' >> caseDicts/snappyHexMeshDict
echo '\*---------------------------------------------------------------------------*/' >> caseDicts/snappyHexMeshDict
echo 'FoamFile' >> caseDicts/snappyHexMeshDict
echo '{' >> caseDicts/snappyHexMeshDict
echo '    version     2.0;' >> caseDicts/snappyHexMeshDict
echo '    format      ascii;' >> caseDicts/snappyHexMeshDict
echo '    class       dictionary;' >> caseDicts/snappyHexMeshDict
echo '    object      snappyHexMeshDict;' >> caseDicts/snappyHexMeshDict
echo '}' >> caseDicts/snappyHexMeshDict
echo '// * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * //' >> caseDicts/snappyHexMeshDict
echo "castellatedMesh true;" >> caseDicts/snappyHexMeshDict
echo "snap            true;" >> caseDicts/snappyHexMeshDict
echo "addLayers       false;" >> caseDicts/snappyHexMeshDict
echo "geometry" >> caseDicts/snappyHexMeshDict
echo "{" >> caseDicts/snappyHexMeshDict
echo "    $name.stl" >> caseDicts/snappyHexMeshDict
echo "    {" >> caseDicts/snappyHexMeshDict
echo "        type triSurfaceMesh;" >> caseDicts/snappyHexMeshDict
echo "        tolerance 1e-14;" >> caseDicts/snappyHexMeshDict
echo "        name reactingWall;" >> caseDicts/snappyHexMeshDict
echo "    }" >> caseDicts/snappyHexMeshDict
echo "    inertWall " >> caseDicts/snappyHexMeshDict
echo "    {" >> caseDicts/snappyHexMeshDict
echo "        type searchableCylinder;" >> caseDicts/snappyHexMeshDict
echo "        point1 (0 0 -50);    // Height" >> caseDicts/snappyHexMeshDict
echo "        point2 (0 0 200);    // Vector" >> caseDicts/snappyHexMeshDict
echo "        radius $r;" >> caseDicts/snappyHexMeshDict       
echo "    }" >> caseDicts/snappyHexMeshDict
echo "}" >> caseDicts/snappyHexMeshDict
echo "castellatedMeshControls" >> caseDicts/snappyHexMeshDict
echo "{" >> caseDicts/snappyHexMeshDict
echo "    maxLocalCells 20000000;" >> caseDicts/snappyHexMeshDict
echo "    maxGlobalCells 40000000;" >> caseDicts/snappyHexMeshDict
echo "    minRefinementCells 25;" >> caseDicts/snappyHexMeshDict
echo "    nCellsBetweenLevels 2;" >> caseDicts/snappyHexMeshDict
echo "    features" >> caseDicts/snappyHexMeshDict
echo "    (" >> caseDicts/snappyHexMeshDict
echo "        //{ file \"$name.eMesh\"; level 0;}" >> caseDicts/snappyHexMeshDict
echo "    );" >> caseDicts/snappyHexMeshDict
echo "    refinementSurfaces" >> caseDicts/snappyHexMeshDict
echo "    {" >> caseDicts/snappyHexMeshDict
echo "        reactingWall" >> caseDicts/snappyHexMeshDict
echo "        {" >> caseDicts/snappyHexMeshDict
echo "            level (2 2);" >> caseDicts/snappyHexMeshDict
echo "            gapLevelIncrement 1;" >> caseDicts/snappyHexMeshDict
echo "            faceZone solid0;" >> caseDicts/snappyHexMeshDict
echo "            cellZone solid;" >> caseDicts/snappyHexMeshDict
echo "            cellZoneInside inside;" >> caseDicts/snappyHexMeshDict
echo "        }" >> caseDicts/snappyHexMeshDict
echo "        inertWall" >> caseDicts/snappyHexMeshDict
echo "        {" >> caseDicts/snappyHexMeshDict
echo "            level (0 1);" >> caseDicts/snappyHexMeshDict
echo "        }" >> caseDicts/snappyHexMeshDict
echo "    }" >> caseDicts/snappyHexMeshDict
echo "    resolveFeatureAngle 30;" >> caseDicts/snappyHexMeshDict
echo "    refinementRegions" >> caseDicts/snappyHexMeshDict
echo "    {" >> caseDicts/snappyHexMeshDict
echo "        reactingWall" >> caseDicts/snappyHexMeshDict
echo "        {" >> caseDicts/snappyHexMeshDict
echo "            mode inside;" >> caseDicts/snappyHexMeshDict
echo "            levels ((1 1));" >> caseDicts/snappyHexMeshDict
echo "        }" >> caseDicts/snappyHexMeshDict
echo "    }" >> caseDicts/snappyHexMeshDict
echo "    locationInMesh (0. 0. $zLoc);" >> caseDicts/snappyHexMeshDict
echo "    allowFreeStandingZoneFaces false;" >> caseDicts/snappyHexMeshDict
echo "}" >> caseDicts/snappyHexMeshDict
echo "snapControls" >> caseDicts/snappyHexMeshDict
echo "{" >> caseDicts/snappyHexMeshDict
echo "    nSmoothPatch 5;" >> caseDicts/snappyHexMeshDict
echo "    tolerance 1.0;" >> caseDicts/snappyHexMeshDict
echo "    nSolveIter 300;" >> caseDicts/snappyHexMeshDict
echo "    nRelaxIter 10;" >> caseDicts/snappyHexMeshDict
echo "    nFeatureSnapIter 10;" >> caseDicts/snappyHexMeshDict
echo "    implicitFeatureSnap false;" >> caseDicts/snappyHexMeshDict
echo "    multiRegionFeatureSnap false;" >> caseDicts/snappyHexMeshDict
echo "}" >> caseDicts/snappyHexMeshDict
echo "addLayersControls" >> caseDicts/snappyHexMeshDict
echo "{" >> caseDicts/snappyHexMeshDict
echo "    relativeSizes false;" >> caseDicts/snappyHexMeshDict
echo "    layers" >> caseDicts/snappyHexMeshDict
echo "    {" >> caseDicts/snappyHexMeshDict
echo "        reactingWall" >> caseDicts/snappyHexMeshDict
echo "        {" >> caseDicts/snappyHexMeshDict
echo "            nSurfaceLayers 2;" >> caseDicts/snappyHexMeshDict
echo "        }" >> caseDicts/snappyHexMeshDict
echo "    }" >> caseDicts/snappyHexMeshDict
echo "    expansionRatio 1.2;" >> caseDicts/snappyHexMeshDict
echo "    finalLayerThickness 0.04;" >> caseDicts/snappyHexMeshDict
echo "    minThickness 0.01;" >> caseDicts/snappyHexMeshDict
echo "    nGrow 0;" >> caseDicts/snappyHexMeshDict
echo "    featureAngle 85;" >> caseDicts/snappyHexMeshDict
echo "    slipFeatureAngle 25;" >> caseDicts/snappyHexMeshDict
echo "    nRelaxIter 5;" >> caseDicts/snappyHexMeshDict
echo "    nSmoothSurfaceNormals 4;" >> caseDicts/snappyHexMeshDict
echo "    nSmoothNormals 3;" >> caseDicts/snappyHexMeshDict
echo "    nSmoothThickness 10;" >> caseDicts/snappyHexMeshDict
echo "    maxFaceThicknessRatio 0.5;" >> caseDicts/snappyHexMeshDict
echo "    maxThicknessToMedialRatio 0.2;" >> caseDicts/snappyHexMeshDict
echo "    minMedianAxisAngle 90;" >> caseDicts/snappyHexMeshDict
echo "    nBufferCellsNoExtrude 0;" >> caseDicts/snappyHexMeshDict
echo "    nLayerIter 50;" >> caseDicts/snappyHexMeshDict
echo "}" >> caseDicts/snappyHexMeshDict
echo "meshQualityControls" >> caseDicts/snappyHexMeshDict
echo "{" >> caseDicts/snappyHexMeshDict
echo "    maxNonOrtho 65;" >> caseDicts/snappyHexMeshDict
echo "    maxBoundarySkewness 4;" >> caseDicts/snappyHexMeshDict
echo "    maxInternalSkewness 4;" >> caseDicts/snappyHexMeshDict
echo "    maxConcave 80;" >> caseDicts/snappyHexMeshDict
echo "    minVol 1e-13;" >> caseDicts/snappyHexMeshDict
echo "    minTetQuality 1e-30;" >> caseDicts/snappyHexMeshDict
echo "    minArea -1;" >> caseDicts/snappyHexMeshDict
echo "    minTwist 0.02;" >> caseDicts/snappyHexMeshDict
echo "    minDeterminant 0.001;" >> caseDicts/snappyHexMeshDict
echo "    minFaceWeight 0.02;" >> caseDicts/snappyHexMeshDict
echo "    minVolRatio 0.01;" >> caseDicts/snappyHexMeshDict
echo "    minTriangleTwist -1;" >> caseDicts/snappyHexMeshDict
echo "    nSmoothScale 4;" >> caseDicts/snappyHexMeshDict
echo "    errorReduction 0.75;" >> caseDicts/snappyHexMeshDict
echo "}" >> caseDicts/snappyHexMeshDict
echo "writeFlags" >> caseDicts/snappyHexMeshDict
echo "(" >> caseDicts/snappyHexMeshDict
echo "    scalarLevels" >> caseDicts/snappyHexMeshDict
echo "    layerSets" >> caseDicts/snappyHexMeshDict
echo "    layerFields" >> caseDicts/snappyHexMeshDict
echo ");" >> caseDicts/snappyHexMeshDict
echo "mergeTolerance 1E-10;" >> caseDicts/snappyHexMeshDict
echo '// ************************************************************************* //' >> caseDicts/snappyHexMeshDict


rm -f caseDicts/blockMeshDict
touch caseDicts/blockMeshDict
echo '/*--------------------------------*- C++ -*----------------------------------*\' >> caseDicts/blockMeshDict
echo '| =========                 |                                                 |' >> caseDicts/blockMeshDict
echo '| \\      /  F ield         | OpenFOAM: The Open Source CFD Toolbox           |' >> caseDicts/blockMeshDict
echo '|  \\    /   O peration     | Version:  2.3.0                                 |' >> caseDicts/blockMeshDict
echo '|   \\  /    A nd           | Web:      www.OpenFOAM.org                      |' >> caseDicts/blockMeshDict
echo '|    \\/     M anipulation  |                                                 |' >> caseDicts/blockMeshDict
echo '\*---------------------------------------------------------------------------*/' >> caseDicts/blockMeshDict
echo 'FoamFile' >> caseDicts/blockMeshDict
echo '{' >> caseDicts/blockMeshDict
echo '    version     2.0;' >> caseDicts/blockMeshDict
echo '    format      ascii;' >> caseDicts/blockMeshDict
echo '    class       dictionary;' >> caseDicts/blockMeshDict
echo '    object      blockMeshDict;' >> caseDicts/blockMeshDict
echo '}' >> caseDicts/blockMeshDict
echo '// * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * //' >> caseDicts/blockMeshDict
echo "vertices" >> caseDicts/blockMeshDict
echo "(" >> caseDicts/blockMeshDict
echo "    ($xMinExtended $yMinExtended 	$zMinExtended ) // 0" >> caseDicts/blockMeshDict
echo "    ($xMaxExtended $yMinExtended 	$zMinExtended )	// 1" >> caseDicts/blockMeshDict
echo "    ($xMaxExtended $yMaxExtended 	$zMinExtended ) // 2" >> caseDicts/blockMeshDict
echo "    ($xMinExtended $yMaxExtended	$zMinExtended )	// 3" >> caseDicts/blockMeshDict
echo "    ($xMinExtended $yMinExtended 	$zMaxExtended ) // 4" >> caseDicts/blockMeshDict
echo "    ($xMaxExtended $yMinExtended 	$zMaxExtended ) // 5" >> caseDicts/blockMeshDict
echo "    ($xMaxExtended $yMaxExtended 	$zMaxExtended ) // 6" >> caseDicts/blockMeshDict
echo "    ($xMinExtended $yMaxExtended	$zMaxExtended ) // 7" >> caseDicts/blockMeshDict
echo ");" >> caseDicts/blockMeshDict
echo "blocks" >> caseDicts/blockMeshDict
echo "(" >> caseDicts/blockMeshDict
echo "	hex (0 1 2 3 4 5 6 7) (10 10 10) simpleGrading (1 1 1)" >> caseDicts/blockMeshDict
echo ");" >> caseDicts/blockMeshDict
echo "edges();" >> caseDicts/blockMeshDict
echo "boundary" >> caseDicts/blockMeshDict
echo "(" >> caseDicts/blockMeshDict
echo "	outlet" >> caseDicts/blockMeshDict
echo "	{" >> caseDicts/blockMeshDict
echo "		type patch;" >> caseDicts/blockMeshDict
echo "		faces" >> caseDicts/blockMeshDict
echo "		(" >> caseDicts/blockMeshDict
echo "			(4 5 6 7)" >> caseDicts/blockMeshDict
echo "		);" >> caseDicts/blockMeshDict
echo "	}" >> caseDicts/blockMeshDict
echo "	inlet" >> caseDicts/blockMeshDict
echo "	{" >> caseDicts/blockMeshDict
echo "		type patch;" >> caseDicts/blockMeshDict
echo "		faces" >> caseDicts/blockMeshDict
echo "		(" >> caseDicts/blockMeshDict
echo "			(0 3 2 1)" >> caseDicts/blockMeshDict
echo "		);" >> caseDicts/blockMeshDict
echo "	}" >> caseDicts/blockMeshDict
echo "	tubeWall" >> caseDicts/blockMeshDict
echo "	{" >> caseDicts/blockMeshDict
echo "		type wall;" >> caseDicts/blockMeshDict
echo "		faces" >> caseDicts/blockMeshDict
echo "		(" >> caseDicts/blockMeshDict
echo "			(3 2 6 7)" >> caseDicts/blockMeshDict
echo "			(0 4 7 3)" >> caseDicts/blockMeshDict
echo "			(1 2 6 5)" >> caseDicts/blockMeshDict
echo "			(0 1 5 4)" >> caseDicts/blockMeshDict
echo "		);" >> caseDicts/blockMeshDict
echo "	}" >> caseDicts/blockMeshDict
echo ");" >> caseDicts/blockMeshDict
echo "mergePatchPairs();" >> caseDicts/blockMeshDict
echo "// ************************************************************************* //" >> caseDicts/blockMeshDict


rm -f caseDicts/topoSetDict
touch caseDicts/topoSetDict
echo '/*--------------------------------*- C++ -*----------------------------------*\' >> caseDicts/topoSetDict
echo '| =========                 |                                                 |' >> caseDicts/topoSetDict
echo '| \\      /  F ield         | OpenFOAM: The Open Source CFD Toolbox           |' >> caseDicts/topoSetDict
echo '|  \\    /   O peration     | Version:  2.3.0                                 |' >> caseDicts/topoSetDict
echo '|   \\  /    A nd           | Web:      www.OpenFOAM.org                      |' >> caseDicts/topoSetDict
echo '|    \\/     M anipulation  |                                                 |' >> caseDicts/topoSetDict
echo '\*---------------------------------------------------------------------------*/' >> caseDicts/topoSetDict
echo 'FoamFile' >> caseDicts/topoSetDict
echo '{' >> caseDicts/topoSetDict
echo '    version     2.0;' >> caseDicts/topoSetDict
echo '    format      ascii;' >> caseDicts/topoSetDict
echo '    class       dictionary;' >> caseDicts/topoSetDict
echo '    object      topoSetDict;' >> caseDicts/topoSetDict
echo '}' >> caseDicts/topoSetDict
echo '// * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * //' >> caseDicts/topoSetDict
echo "actions" >> caseDicts/topoSetDict
echo "(" >> caseDicts/topoSetDict
echo "	{" >> caseDicts/topoSetDict
echo "		name    f1;" >> caseDicts/topoSetDict
echo "		type    faceSet;" >> caseDicts/topoSetDict
echo "		action  new;" >> caseDicts/topoSetDict
echo "		source  patchToFace;" >> caseDicts/topoSetDict
echo "		sourceInfo" >> caseDicts/topoSetDict
echo "		{" >> caseDicts/topoSetDict
echo '			name  "inertWall";' >> caseDicts/topoSetDict
echo "		}" >> caseDicts/topoSetDict
echo "	}" >> caseDicts/topoSetDict
echo "	{" >> caseDicts/topoSetDict
echo "		name    f0;" >> caseDicts/topoSetDict
echo "		type    faceSet;" >> caseDicts/topoSetDict
echo "		action  new;" >> caseDicts/topoSetDict
echo "		source  boxToFace;" >> caseDicts/topoSetDict
echo "		sourceInfo" >> caseDicts/topoSetDict
echo "		{" >> caseDicts/topoSetDict
echo "			box  ($xMinExtended $yMinExtended $zMin) ($xMaxExtended $yMaxExtended $zMax);" >> caseDicts/topoSetDict
echo "		}" >> caseDicts/topoSetDict
echo "	}" >> caseDicts/topoSetDict
echo "	{" >> caseDicts/topoSetDict
echo "		name    f0;" >> caseDicts/topoSetDict
echo "		type    faceSet;" >> caseDicts/topoSetDict
echo "		action  subset;" >> caseDicts/topoSetDict
echo "		source  faceToFace;" >> caseDicts/topoSetDict
echo "		sourceInfo" >> caseDicts/topoSetDict
echo "		{" >> caseDicts/topoSetDict
echo "			set f1;" >> caseDicts/topoSetDict
echo "		}" >> caseDicts/topoSetDict
echo "	}" >> caseDicts/topoSetDict
echo ");" >> caseDicts/topoSetDict
echo "// ************************************************************************* //" >> caseDicts/topoSetDict

rm -f caseDicts/createPatchDict
touch caseDicts/createPatchDict
echo '/*--------------------------------*- C++ -*----------------------------------*\' >> caseDicts/createPatchDict
echo '| =========                 |                                                 |' >> caseDicts/createPatchDict
echo '| \\      /  F ield         | OpenFOAM: The Open Source CFD Toolbox           |' >> caseDicts/createPatchDict
echo '|  \\    /   O peration     | Version:  2.3.0                                 |' >> caseDicts/createPatchDict
echo '|   \\  /    A nd           | Web:      www.OpenFOAM.org                      |' >> caseDicts/createPatchDict
echo '|    \\/     M anipulation  |                                                 |' >> caseDicts/createPatchDict
echo '\*---------------------------------------------------------------------------*/' >> caseDicts/createPatchDict
echo 'FoamFile' >> caseDicts/createPatchDict
echo '{' >> caseDicts/createPatchDict
echo '    version     2.0;' >> caseDicts/createPatchDict
echo '    format      ascii;' >> caseDicts/createPatchDict
echo '    class       dictionary;' >> caseDicts/createPatchDict
echo '    object      createPatchDict;' >> caseDicts/createPatchDict
echo '}' >> caseDicts/createPatchDict
echo '// * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * //' >> caseDicts/createPatchDict
echo "pointSync false;" >> caseDicts/createPatchDict
echo "patches" >> caseDicts/createPatchDict
echo "(" >> caseDicts/createPatchDict
echo "	{" >> caseDicts/createPatchDict
echo "		name exchangeWall;" >> caseDicts/createPatchDict
echo "		patchInfo" >> caseDicts/createPatchDict
echo "		{" >> caseDicts/createPatchDict
echo "			type wall;" >> caseDicts/createPatchDict
echo "		}" >> caseDicts/createPatchDict
echo "		constructFrom set;" >> caseDicts/createPatchDict
echo "		patches (periodic1);" >> caseDicts/createPatchDict
echo "		set f0;" >> caseDicts/createPatchDict
echo "	}" >> caseDicts/createPatchDict
echo ");" >> caseDicts/createPatchDict
echo "// ************************************************************************* //" >> caseDicts/createPatchDict
