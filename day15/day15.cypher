CALL apoc.periodic.commit("
    MATCH (n)
    WITH n LIMIT 1000
    DETACH DELETE n
    RETURN count(n) AS limit",
    {});

////FORK//// FORK ///// alternative part 1 //////FORK////FORK//////FORK/
LOAD CSV FROM 'file:///input_15.txt' AS line
WITH [x IN split(line[0],'') | toInteger(x)] AS line
WITH linenumber() AS line_no, line
WITH line_no, line
FOREACH (col_no IN range(0, size(line)-1) |
    CREATE (:Cell {x: col_no, y: line_no, risk: line[col_no]})
)
RETURN count(line);
////OR//////OR////OR//// alternative part 2 //////OR///OR////OR///OR////
LOAD CSV FROM 'file:///input_15.txt' AS line
WITH [x IN split(line[0],'') | toInteger(x)] AS line
WITH apoc.coll.flatten([added_risk IN range(0,4) |
  [x IN line | 1 + (x - 1 + added_risk) % 9]]) AS line
WITH collect(line) AS lines
WITH [added_risk IN range(0,4) | [line IN lines |
  [x IN line |1+( x - 1 + added_risk) % 9]]] AS lines
WITH apoc.coll.flatten(lines) AS lines
WITH [line_no IN range(0, size(lines)-1) | [line_no, lines[line_no]]] AS lines
UNWIND lines AS line
WITH line[0] AS line_no, line[1] AS line
FOREACH (col_no IN range(0, size(line)-1) |
    CREATE (:Cell {x: col_no, y: line_no, risk: line[col_no]})
)
RETURN count(line);
/////////////////MERGE PARTS////////////MERGE PARTS///////////

// create horizontal rels
MATCH (l:Cell), (r:Cell)
WHERE l.y = r.y AND l.x + 1 = r.x
CREATE (l)-[:NEXT_TO {dir: "horizontal", risk: r.risk}]->(r)
CREATE (r)-[:NEXT_TO {dir: "horizontal", risk: l.risk}]->(l);
// create vertical rels
MATCH (u:Cell), (d:Cell)
WHERE u.y + 1 = d.y AND u.x = d.x
CREATE (u)-[:NEXT_TO {dir: "vertical", risk: d.risk}]->(d)
CREATE (d)-[:NEXT_TO {dir: "vertical", risk: u.risk}]->(u);

CALL gds.graph.drop('cavern');

CALL gds.graph.create(
    'cavern',
    'Cell',
    'NEXT_TO',
    {
        relationshipProperties: 'risk'
    }
);

MATCH (n:Cell)
WITH [min(n.x), min(n.y)] AS top_left_cell,
  [max(n.x), max(n.y)] AS bottom_right_cell
MATCH (source:Cell), (target:Cell)
WHERE source.x = top_left_cell[0]
  AND source.y = top_left_cell[1]
  AND target.x = bottom_right_cell[0]
  AND target.y = bottom_right_cell[1]
CALL gds.shortestPath.dijkstra.stream('cavern', {
    sourceNode: source,
    targetNode: target,
    relationshipWeightProperty: 'risk'
})
YIELD totalCost
RETURN toInteger(totalCost);
