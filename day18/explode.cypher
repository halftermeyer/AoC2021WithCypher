MATCH (n0)-[r:DFS_NEXT]->(n1)
WHERE substring(n0.DFSLabel, 0, size(n0.DFSLabel)-1)= substring(n1.DFSLabel, 0, size(n1.DFSLabel)-1)
AND n0.id = 1
AND size(n0.DFSLabel) = 5
WITH n0, n1 ORDER BY n0.DFSLabel LIMIT 1
MERGE (n0)-[:DFS_NEXT]->(mid:Number:Middle {DFSLabel: substring(n0.DFSLabel, 0, size(n0.DFSLabel)-1), val: 0, id: n0.id})-[:DFS_NEXT]->(n1)
SET n0:ToExplode0:ToExplode
SET n1:ToExplode1:ToExplode;


MATCH (prev:Number)-[:DFS_NEXT]->(n0:Number:ToExplode0)-[:DFS_NEXT]->(mid:Number:Middle)
SET prev.val = prev.val + n0.val
MERGE (prev)-[:DFS_NEXT]->(mid);

MATCH (next:Number)<-[:DFS_NEXT]-(n1:Number:ToExplode1)<-[:DFS_NEXT]-(mid:Number:Middle)
SET next.val = next.val + n1.val
MERGE (mid)-[:DFS_NEXT]->(next);

MATCH (n:ToExplode)
DETACH DELETE n;

MATCH (n:Middle)
REMOVE n:Middle;
