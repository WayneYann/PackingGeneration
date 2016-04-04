rm -rf constant/polyMesh/sets
insideCells ../stl/bed.stl fluid
insideCells ../stl/bed-cut.stl bridges
insideCells ../stl/bed-cut.stl solid
rm -f batchFile
touch batchFile
#echo "cellSet fluid invert" >> batchFile
echo "cellSet bridges invert" >> batchFile
echo "cellSet bridges subset cellToCell fluid" >> batchFile
echo "cellSet fluid invert" >> batchFile
echo "cellZoneSet fluid new setToCellZone fluid" >> batchFile
echo "cellZoneSet solid new setToCellZone solid" >> batchFile
echo "cellZoneSet bridges new setToCellZone bridges" >> batchFile
setSet -batch batchFile
