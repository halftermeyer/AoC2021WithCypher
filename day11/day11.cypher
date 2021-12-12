MATCH (n) DETACH DELETE n;


LOAD CSV FROM 'file:///input_11.txt' AS line
WITH [x IN split(line[0],'') | toInteger(x)] AS line
WITH linenumber() AS line_no, line
WITH line_no, line
FOREACH (col_no IN range(0, size(line)-1) |
    CREATE (:Octopus:NotFlashed {x: col_no, y: line_no, flashes: 0, energy: line[col_no]})
)
RETURN count(line);

// create horizontal rels
MATCH (l:Octopus), (r:Octopus)
WHERE l.y = r.y AND l.x + 1 = r.x
CREATE (l)-[:NEXT_TO {dir: "horizontal", gives_energy: 0}]->(r)
CREATE (r)-[:NEXT_TO {dir: "horizontal", gives_energy: 0}]->(l);
// create vertical rels
MATCH (u:Octopus), (d:Octopus)
WHERE u.y + 1 = d.y AND u.x = d.x
CREATE (u)-[:NEXT_TO {dir: "vertical", gives_energy: 0}]->(d)
CREATE (d)-[:NEXT_TO {dir: "vertical", gives_energy: 0}]->(u);
// create diagonal rels
MATCH (nw:Octopus), (se:Octopus)
WHERE nw.y + 1 = se.y AND nw.x + 1 = se.x
CREATE (nw)-[:NEXT_TO {dir: "diagonal", gives_energy: 0}]->(se)
CREATE (se)-[:NEXT_TO {dir: "diagonal", gives_energy: 0}]->(nw);
// create antidiagonal rels
MATCH (sw:Octopus), (ne:Octopus)
WHERE sw.y - 1 = ne.y AND sw.x + 1 = ne.x
CREATE (sw)-[:NEXT_TO {dir: "antidiagonal", gives_energy: 0}]->(ne)
CREATE (ne)-[:NEXT_TO {dir: "antidiagonal", gives_energy: 0}]->(sw);

:auto UNWIND range (1, 100) AS round
CALL {
        CALL apoc.cypher.runMany("
        MATCH (o:Octopus)
        SET o:NotFlashed
        SET o.energy = o.energy + 1;
        CALL apoc.cypher.runFile('flashWave.cypher');", {}) YIELD result
} IN TRANSACTIONS OF 1 ROW;

MATCH (n:Octopus) WHERE n.flashes > 0 RETURN sum(n.flashes);
