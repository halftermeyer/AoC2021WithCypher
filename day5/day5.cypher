// part 1
CREATE BTREE INDEX cell_x IF NOT EXISTS FOR (c:Cell) ON (c.x);
CREATE BTREE INDEX cell_y IF NOT EXISTS FOR (c:Cell) ON (c.y);
CREATE CONSTRAINT cell_x_y_key IF NOT EXISTS ON (n:Cell) ASSERT (n.x, n.y) IS NODE KEY

// clean
CALL apoc.periodic.iterate("MATCH (n) RETURN n", "DETACH DELETE n", {batchSize: 10000}) YIELD batch RETURN 1;

// create vertices
// part 1

CALL apoc.periodic.iterate("
LOAD CSV FROM 'file:///input_5.txt' AS line  FIELDTERMINATOR '$'
WITH [x in split(line[0], ' -> ') | [x in split(x, ',') | toInteger(x)]] AS points
WITH apoc.coll.flatten(points) AS coords
WITH apoc.coll.max([coords[0], coords[3]]) AS xs, apoc.coll.max([coords[1], coords[4]]) AS ys
WITH max(xs) AS max_x, max(ys) AS max_y
UNWIND range(0, max_x) AS x
RETURN x, max_y
","
UNWIND range(0, max_y) AS y
CREATE (:Cell {x: x, y: y})
RETURN 1
",{batchSize: 10, parallel : true}) YIELD batch, operations
RETURN batch, operations;

// Grid rels
  // horizontal rels
CALL apoc.periodic.iterate("
MATCH (left:Cell) RETURN left
","
MATCH(right:Cell {x: left.x + 1, y: left.y})
CREATE (left)-[:NEXT_TO]->(right)
", {batchSize: 10000}) YIELD batch, operations
RETURN batch, operations;

// vertical rels
CALL apoc.periodic.iterate("
MATCH (up:Cell) RETURN up
","
MATCH (down:Cell {x: up.x, y: up.y + 1})
CREATE (up)-[:ABOVE]->(down)
", {batchSize: 10000}) YIELD batch, operations
RETURN batch, operations;

// iterate data
// parsing clouds

LOAD CSV FROM "file:///input_5.txt" AS line  FIELDTERMINATOR '$'
WITH [x in split(line[0], ' -> ') | [x in split(x, ',') | toInteger(x)]] AS points
MATCH (f:Cell {x: points[0][0], y: points[0][1]})
MATCH (s:Cell {x: points[1][0], y: points[1][1]})
CREATE (f)-[:HAS_CLOUD_UNTIL]->(s)

// Set Cell opacity
CALL apoc.periodic.iterate("MATCH (c:Cell) RETURN c","SET c.opacity = 0", {batchSize: 10000, parallel: true}) yield batch RETURN *;

CALL apoc.periodic.iterate("
CALL {
MATCH p=(a:Cell)-[:HAS_CLOUD_UNTIL]-(b:Cell)-[:NEXT_TO*]->(a) RETURN p
UNION
MATCH p=(a:Cell)-[:HAS_CLOUD_UNTIL]-(b:Cell)-[:ABOVE*]->(a) RETURN p}
WITH p RETURN p
","
WITH apoc.coll.toSet(nodes(p)) as distinctCells
FOREACH (c IN distinctCells | SET c.opacity = coalesce(c.opacity, 0) + 1)
RETURN 1
",{batchSize: 10}) YIELD batch RETURN *;

MATCH (c:Cell) WHERE (c.opacity) > 1 RETURN count(*);

// part 2

// Grid rels
  // diag rels
CALL apoc.periodic.iterate("
MATCH (upleft:Cell) RETURN upleft
","
MATCH(downRight:Cell {x: upleft.x + 1, y: upleft.y + 1})
CREATE (upleft)-[:DIAG_NEXT]->(downRight)
", {batchSize: 10000}) YIELD batch, operations
RETURN batch, operations;

// antidiag rels
CALL apoc.periodic.iterate("
MATCH (upRight:Cell) RETURN upRight
","
MATCH (downLeft:Cell {x: upRight.x - 1, y: upRight.y + 1})
CREATE (upRight)-[:ANTIDIAG_NEXT]->(downLeft)
", {batchSize: 10000}) YIELD batch, operations
RETURN batch, operations;

// Set Cell opacity
CALL apoc.periodic.iterate("MATCH (c:Cell) RETURN c","SET c.opacity = 0", {batchSize: 10000, parallel: true}) yield batch RETURN *;

CALL apoc.periodic.iterate("
CALL {
MATCH p=(a:Cell)-[:HAS_CLOUD_UNTIL]-(b:Cell)-[:NEXT_TO*]->(a) RETURN p
UNION
MATCH p=(a:Cell)-[:HAS_CLOUD_UNTIL]-(b:Cell)-[:ABOVE*]->(a) RETURN p
UNION
MATCH p=(a:Cell)-[:HAS_CLOUD_UNTIL]-(b:Cell)-[:DIAG_NEXT*]->(a) RETURN p
UNION
MATCH p=(a:Cell)-[:HAS_CLOUD_UNTIL]-(b:Cell)-[:ANTIDIAG_NEXT*]->(a) RETURN p
}
WITH p RETURN p
","
WITH apoc.coll.toSet(nodes(p)) as distinctCells
FOREACH (c IN distinctCells | SET c.opacity = coalesce(c.opacity, 0) + 1)
RETURN 1
",{batchSize: 10}) YIELD batch RETURN *;

MATCH (c:Cell) WHERE (c.opacity) > 1 RETURN count(*);
