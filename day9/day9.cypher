CREATE BTREE INDEX point_coords IF NOT EXISTS FOR (n:Point) ON (n.x, n.y, n.z);

MATCH (n) DETACH DELETE n;

// part 1

// create Points
LOAD CSV FROM 'file:///input_9.txt' AS line
WITH [x IN split(line[0],'') | toInteger(x)] AS line
WITH linenumber() AS line_no, line
WITH line_no, line
FOREACH (col_no IN range(0, size(line)-1) |
    CREATE (:Point {x: col_no, y: line_no, z: line[col_no]})
)
RETURN count(line);

// create horizontal rels
MATCH (l:Point), (r:Point)
WHERE l.y = r.y AND l.x + 1 = r.x
CREATE (l)-[:NEXT_TO {dir: "horizontal"}]->(r);

// create vertical rels
MATCH (u:Point), (d:Point)
WHERE u.y + 1 = d.y AND u.x = d.x
CREATE (u)-[:NEXT_TO {dir: "vertical"}]->(d);

// get sum of risk_levels
MATCH (p:Point)-[:NEXT_TO]-(n:Point)
WITH p, collect(n) AS neighbors
WHERE none(n in neighbors WHERE n.z <= p.z)
WITH p.z + 1 AS risk_level
RETURN sum (risk_level);

// part 2

// delete plateau points
MATCH (p:Point) WHERE p.z = 9
DETACH DELETE p;

// compute connected components as bassins with GDS weakly connected components
CALL gds.graph.create('bassins', 'Point', 'NEXT_TO');
CALL gds.wcc.write('bassins', {writeProperty: 'bassinId'});

// compute product of 3 largest bassin sizes
MATCH (p:Point)
WITH count(p) AS bassin_size, p.bassinId as bassin_id
ORDER BY bassin_size DESC LIMIT 3
WITH collect(bassin_size) AS sizes
RETURN reduce (prod=1, s IN sizes | prod * s);
