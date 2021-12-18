CREATE INDEX prob_coord IF NOT EXISTS
FOR (n:Probe)
ON (n.x,n.y);


MATCH (n) DETACH DELETE n;

LOAD CSV FROM 'file:///input_17.txt' AS line
WITH [x IN split(split(line[0],'=')[1],'..') | toInteger(x)] AS xs,
[x IN split(split(line[1],'=')[1],'..') | toInteger(x)] AS ys
FOREACH (vx IN range(0, xs[1]) |
    FOREACH (vy IN range(ys[0], -ys[0]+1) |
        CREATE (:Probe:Init {x: 0, y: 0, vx: vx, vy: vy})
    )
);

CALL apoc.periodic.commit("
MATCH (p:Probe)
WHERE NOT EXISTS ((p)-[:NEXT_STEP]->())
AND p.x < 240 AND p.y > -126
CREATE (next:Probe {x: p.x+p.vx, y: p.y + p.vy,
                vx: CASE p.vx = 0 WHEN true THEN 0
                        ELSE CASE p.vx > 0
                            WHEN true THEN p.vx - 1
                            ELSE p.vx + 1
                        END
                    END,
                vy: p.vy - 1})
MERGE (p)-[:NEXT_STEP]->(next)
WITH count(*) AS limit
RETURN limit",{});

MATCH path=(p:Probe:Init)-[:NEXT_STEP*]->(t:Probe)
WHERE 217<=t.x<=240
AND -126 <= t.y <= -69
WITH apoc.coll.max([x IN nodes(path) | x.y]) as max_height, p
RETURN max(max_height) AS part_1, count(DISTINCT p) AS part_2;