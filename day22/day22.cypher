CALL apoc.periodic.commit(
"MATCH (n)
WITH n LIMIT 1000
DETACH DELETE n
WITH count(n) AS limit
RETURN limit"
,{});

LOAD CSV FROM "file:///input_22.txt" AS line FIELDTERMINATOR '#'
WITH line[0] AS line, linenumber() AS num
WITH apoc.text.regexGroups(
  line,
  '(\\w+) x=(-?\\d+)..(-?\\d+),y=(-?\\d+)..(-?\\d+),z=(-?\\d+)..(-?\\d+)'
)[0] AS line, num
WITH apoc.map.fromLists(["line", "mode", "x_from", "x_to", "y_from", "y_to", "z_from", "z_to"], line) AS line, num
WITH apoc.map.setEntry(line, "number", num) AS line
WITH apoc.map.setEntry(line, "x_from", toInteger(line["x_from"])) AS line
WITH apoc.map.setEntry(line, "x_to", toInteger(line["x_to"])) AS line
WITH apoc.map.setEntry(line, "y_from", toInteger(line["y_from"])) AS line
WITH apoc.map.setEntry(line, "y_to", toInteger(line["y_to"])) AS line
WITH apoc.map.setEntry(line, "z_from", toInteger(line["z_from"])) AS line
WITH apoc.map.setEntry(line, "z_to", toInteger(line["z_to"])) AS line
CREATE (step:Step)
SET step += line
RETURN step;

CREATE INDEX cube_coords_state IF NOT EXISTS FOR (c:Cube) ON (c.x, c.y, c.z, c.state);
FOREACH (x IN range(-50, 50) |
  FOREACH (y IN range(-50, 50) |
    FOREACH (z IN range(-50, 50) |
      CREATE (:Cube {x: x, y: y, z: z, state: "off"})
    )
  )
);

CALL apoc.periodic.iterate(
  "MATCH (s:Step)
  RETURN s ORDER BY s.number",
  "MATCH (c:Cube)
  WHERE s.x_from <= c.x <= s.x_to
  AND s.y_from <= c.y <= s.y_to
  AND s.z_from <= c.z <= s.z_to
  AND c.state = {off:'on', on:'off'}[s.mode]
  SET c.state = s.mode",
{batchSize: 1});

MATCH (c:Cube {state: "on"}) RETURN count (c) AS part_1;

CALL apoc.periodic.commit(
"MATCH (n:Cube)
WITH n LIMIT 1000
DETACH DELETE n
WITH count(n) AS limit
RETURN limit"
,{});
