// MERGE 2 TREES
MATCH (n:Number)
WITH DISTINCT (n.id) AS id, collect(n) AS _forget ORDER BY id LIMIT 2
WITH collect(id) AS ids
WITH ids
MATCH (n:Number)
WHERE n.id IN ids
SET n.DFSLabel = CASE n.id = ids[0] WHEN true THEN "0" ELSE "1" END + n.DFSLabel
WITH ids, collect(n) AS _forget
MATCH (tail0:Number), (head1:Number)
WHERE tail0.id = ids[0]
AND head1.id = ids[1]
AND NOT EXISTS ((tail0)-[:DFS_NEXT]->())
AND NOT EXISTS ((head1)<-[:DFS_NEXT]-())
MERGE (tail0)-[:DFS_NEXT]->(head1)
WITH ids
MATCH (n:Number)
WHERE n.id = ids[1]
SET n.id = ids[0];

// reduce
CALL apoc.periodic.commit('
CALL apoc.cypher.runFile("reduce.cypher") YIELD result

CALL { MATCH (n:Number)
WHERE n.id= 1
AND n.val >= 10
WITH n LIMIT 1
RETURN count(*) AS limit
UNION
MATCH (n0)-[r:DFS_NEXT]->(n1)
WHERE substring(n0.DFSLabel, 0, size(n0.DFSLabel)-1)= substring(n1.DFSLabel, 0, size(n1.DFSLabel)-1)
AND n0.id = 1
AND size(n0.DFSLabel) = 5
WITH n0 LIMIT 1
RETURN count(*) AS limit}
WITH sum(limit) AS limit
RETURN limit
',{});
