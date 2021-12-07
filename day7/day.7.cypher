LOAD CSV FROM 'file:///input_7.txt' AS line  FIELDTERMINATOR ','
WITH [x IN line | toInteger(x)] AS crabs
WITH crabs, apoc.coll.toSet(crabs) as positions
WITH range(apoc.coll.min(positions), apoc.coll.max(positions)) as positions, crabs
UNWIND positions as position
UNWIND crabs as crab
WITH position, abs(crab - position) as fuel
RETURN position, sum(fuel) as totalFuel
ORDER BY totalFuel ASC LIMIT 1;

LOAD CSV FROM 'file:///input_7.txt' AS line  FIELDTERMINATOR ','
WITH [x IN line | toInteger(x)] AS crabs
WITH crabs, apoc.coll.toSet(crabs) as positions
WITH range(apoc.coll.min(positions), apoc.coll.max(positions)) as positions, crabs
UNWIND positions as position
UNWIND crabs as crab
WITH position, abs(crab - position) as dist
WITH position, dist ,toInteger((dist*(dist+1))/2) as fuel
RETURN position, sum(fuel) as totalFuel
ORDER BY totalFuel ASC LIMIT 1;
