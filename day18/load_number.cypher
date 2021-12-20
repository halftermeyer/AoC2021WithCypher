MATCH (lineNode:Line:Unprocessed)
WITH lineNode.line AS line, lineNode.order AS order, lineNode LIMIT 1
REMOVE lineNode:Unprocessed
CREATE (root:Number:Root:Building {depth:0, path: [], id: order, from_id: order})
WITH line, order
FOREACH (i1 IN [0,1] |
    CREATE (n:Number:Building {depth:1, path: [i1], id: order, from_id: order})
    FOREACH (i2 IN [0,1] |
        CREATE (n:Number:Building {depth:2, path: [i1, i2], id: order, from_id: order})
        FOREACH (i3 IN [0,1] |
            CREATE (n:Number:Building {depth:3, path: [i1, i2, i3], id: order, from_id: order})
            FOREACH (i4 IN [0,1] |
                CREATE (n:Number:Building {depth:4, path: [i1, i2, i3, i4], id: order, from_id: order})
            )
        )
    )
)
WITH line, order
CALL apoc.cypher.run("RETURN "+ line + " AS number", {}) YIELD value
WITH value.number AS number
MATCH (n:Number:Building)
WITH reduce(val = number, x in n.path | CASE apoc.meta.type(val) = "LIST"
                        AND val[x] IS NOT NULL WHEN TRUE THEN val[x] ELSE null END) AS chunk, n
WITH apoc.meta.type(chunk) AS t, chunk, n
CALL apoc.create.addLabels(n, [apoc.text.capitalize(toLower(t))]) YIELD node
WITH t, chunk, n
SET n.val = CASE t = "INTEGER" WHEN true THEN chunk ELSE null END;

MATCH (n:Building:Null) DETACH DELETE n;

MATCH (n:Building:Number)
WHERE NOT n:Root
MATCH (father:Building:Number {path: n.path[0..-1]})
MERGE (father)-[:HAS_CHILD {side: n.path[-1]}]->(n);

MATCH (n:Building:Integer)
SET n.DFSLabel = reduce(l = "", i IN n.path | l+i);

MATCH (n:Building:Integer)
WITH n ORDER BY n.DFSLabel
WITH collect(n) AS literals
WITH apoc.coll.pairsMin(literals) AS pairs
UNWIND pairs AS pair
WITH pair[0] AS prev, pair[1] AS next
MERGE (prev)-[:DFS_NEXT]->(next);

MATCH (n:Number:List) DETACH DELETE n;
MATCH (n:Building) REMOVE n:Building;
