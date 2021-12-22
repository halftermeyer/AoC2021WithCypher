CREATE CONSTRAINT pix_coords IF NOT EXISTS FOR (n:Pixel) REQUIRE (n.x, n.y) IS NODE KEY;

CALL apoc.periodic.commit("
MATCH (n)
WITH n LIMIT 1000
DETACH DELETE n
WITH count(n) AS limit
RETURN limit",{});

LOAD CSV FROM "file:///input_20.txt" AS line
WITH line, linenumber() AS lno
WHERE lno = 1
CREATE (algo:Algorithm {code: split(line[0],'')});

LOAD CSV FROM "file:///input_20.txt" AS line
WITH *, linenumber() AS lno
WHERE lno > 1
WITH [i IN range(0,55)|"."]+split(line[0], '')+[i IN range(0, 55)|"."] AS line
WITH collect(line) AS lines
WITH [l IN range(0,55) | [i IN range(0,size(lines[0])-1)|"."]]+lines+[l IN range(0,55) | [i IN range(0,size(lines[0])-1)|"."]] AS lines
WITH [i IN range(0, size(lines)-1) | {line: lines[i], lno: i}] AS lines
UNWIND lines AS line
WITH line.line AS line, line.lno AS y
FOREACH (x IN range(0, size(line)-1) | CREATE (p:Pixel {x:x, y:y, val: CASE line[x] WHEN "#" THEN 1 ELSE 0 END}));

// create rels
MATCH (n:Pixel)
WITH max (n.x) AS max_x, max (n.y) AS max_y, count(n) AS _
MATCH (p:Pixel)
FOREACH (y IN range(-1, 1) |
  FOREACH (x IN range(-1, 1) |
    MERGE (n:Pixel {x: (max_x + 1 +p.x + x) % (max_x + 1),
      y: (max_y + 1 + p.y + y) % (max_y + 1)})
    CREATE (p)-[:NEXT_TO {x: x, y: y, ordinal: x+1 + (y+1)*3,
      factor: 2^(8-(x+1 + (y+1)*3))}]->(n)
    )
  );

// convolution
CALL apoc.periodic.iterate('UNWIND range(1,50) AS i RETURN i',"
MATCH (algo:Algorithm)
MATCH (n:Pixel)-[r:NEXT_TO]->(m:Pixel)
WITH algo, n, r, m
WITH algo, n, count(r) AS convol_size, toInteger(sum(r.factor * m.val)) AS val
WITH n, convol_size, val, CASE algo.code[val]
  WHEN '#' THEN 1 ELSE 0 END AS new_pix
WHERE convol_size = 9
SET n.val = new_pix
",{batchSize:1});

MATCH (n:Pixel)
RETURN sum (n.val)
