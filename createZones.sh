rm -rf constant/polyMesh/sets
insideCells bed-merged.stl fluid
insideCells bed-cut.stl bridges
insideCells bed-cut.stl solid
rm -f batchFile
touch batchFile
echo "cellSet bridges invert" >> batchFile
echo "cellSet bridges subset cellToCell fluid" >> batchFile
echo "cellSet fluid invert" >> batchFile
echo "cellZoneSet fluid new setToCellZone fluid" >> batchFile
echo "cellZoneSet solid new setToCellZone solid" >> batchFile
echo "cellZoneSet bridges new setToCellZone bridges" >> batchFile
setSet -batch batchFile
