MATCH (n) DETACH DELETE n;

UNWIND split(
"1 5483143223
2 2745854711
3 5264556173
4 6141336146
5 6357385478
6 4167524645
7 2176841721
8 6882881134
9 4846848554
10 5283751526", '\n') AS line
WITH split(line, ' ') as line
WITH [x IN split(line[1],'') | toInteger(x)] AS line, toInteger(line[0]) AS line_no
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
