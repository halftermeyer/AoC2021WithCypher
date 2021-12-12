MATCH (n) DETACH DELETE n;

CREATE CONSTRAINT cave_name_key IF NOT EXISTS
FOR (n:Cave)
REQUIRE n.name IS NODE KEY;

MATCH (n) DETACH DELETE n;
WITH split('dc-end
HN-start
start-kj
dc-start
dc-HN
LN-dc
HN-end
kj-sa
kj-HN
kj-dc',
'\n') AS lines
UNWIND lines AS line
WITH split(line, '-') AS vertices
MERGE (from:Cave {name: vertices[0]})
MERGE (to:Cave {name: vertices[1]})
MERGE (from)-[:CONNECTED_TO]->(to);


MATCH (c:Cave)
WITH c, CASE c.name = toLower(c.name)
WHEN true THEN ["Small"] ELSE ["Big"] END AS cave_type
CALL apoc.create.addLabels(c, cave_type)
YIELD node
RETURN node;

// via Big cave
MATCH (s1:Small)-[:CONNECTED_TO]-(big:Big)-[:CONNECTED_TO]-(s2:Small)
WHERE id(s1) < id(s2)
MERGE (s1)-[:CONNECTED_TO {via: big.name}]->(s2);

// via Big cave add loops
MATCH (s:Small)-[:CONNECTED_TO]-(big:Big)
WHERE NOT s.name IN ["start", "end"]
MERGE (s)-[:LOOP {via: big.name}]->(s);


// via leaf add loops
MATCH (s:Small)-[:CONNECTED_TO]-(leaf:Small)
WHERE apoc.node.degree(leaf, "CONNECTED_TO") = 1
MERGE (s)-[:LOOP {via: leaf.name}]->(s)
DETACH DELETE leaf;

// back edges
MATCH (s1:Small)-[r:CONNECTED_TO]->(s2:Small)
WHERE NOT s1.name IN ["start", "end"]
AND NOT s2.name IN ["start", "end"]
CREATE (s1)<-[:CONNECTED_TO {via: r.via}]-(s2);

//remove Big
MATCH (b:Big) DETACH DELETE b;

// query
MATCH p = (s:Cave {name:"start"})-[:CONNECTED_TO|LOOP*0..7]-(e:Cave {name:"end"})
WITH p, [x in apoc.coll.duplicates(nodes(p)) | x.name] as dupl
WHERE all(c IN nodes(p) WHERE apoc.coll.occurrences(nodes(p), c) <= 2)
AND size(dupl) <= 1
AND NOT "start" IN dupl
AND NOT "end" IN dupl
WITH DISTINCT [n IN nodes(p) | n.name] AS smalls, [r IN relationships(p) | r.via] AS vias
RETURN count(*)
