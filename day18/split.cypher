MATCH (n:Number)
WHERE n.id= 1
AND n.val >= 10
WITH n ORDER BY n.DFSLabel
LIMIT 1
SET n:ToSplit
WITH n, n.val/2 AS val0, CASE n.val%2=0 WHEN true THEN n.val/2 ELSE 1+n.val/2 END AS val1
CREATE (c0:Number:Integer:Split:Split0 {id: n.id,  DFSLabel: n.DFSLabel + "0", val: val0})
CREATE (c1:Number:Integer:Split:Split1 {id: n.id,  DFSLabel: n.DFSLabel + "1", val: val1})
MERGE (c0)-[:DFS_NEXT]-(c1);

MATCH (prev)-[r:DFS_NEXT]->(n:ToSplit), (s0:Split0)
WHERE NOT prev:ToSplit
MERGE (prev)-[:DFS_NEXT]->(s0)
DELETE r;

MATCH (next)<-[r:DFS_NEXT]-(n:ToSplit), (s1:Split1)
WHERE NOT next:ToSplit
MERGE (s1)-[:DFS_NEXT]->(next)
DELETE r;

MATCH (n:Split)
REMOVE n:Split:Split0:Split1;

MATCH (n:ToSplit)
DETACH DELETE n;
