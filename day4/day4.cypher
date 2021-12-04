// part 1

MATCH (n) DETACH DELETE n;
CREATE BTREE INDEX item_comp IF NOT EXISTS FOR (n:Item) ON (n.board, n.line, n.item, n.value, n.available);

//ingestion line for python

MATCH (left:Item), (right:Item)
WHERE left.board = right.board
AND left.line = right.line
AND left.col < right.col
AND left.col + 1 = right.col
MERGE (left)-[:NEXT_TO]->(right);

MATCH (up:Item), (down:Item)
WHERE up.board = down.board
AND up.col = down.col
AND up.line < down.line
AND up.line + 1 = down.line
MERGE (up)-[:ABOVE]->(down);

CALL {MATCH p=(first)-[:NEXT_TO*4]->(last) RETURN p
UNION
MATCH p=(first)-[:ABOVE*4]->(last) RETURN p}
WITH p, [n in nodes(p)|n.available] AS avs_from
UNWIND avs_from AS av_from
WITH p, max(av_from) AS av_from
WITH p, av_from ORDER BY av_from ASC LIMIT 1
WITH p, av_from, nodes(p)[0].board AS board
MATCH (i:Item)
WHERE i.board = board AND i.available > av_from
WITH p, av_from, board, collect(i.value) AS unmarkeds
MATCH (i:Item)
WHERE i.board = board AND i.available = av_from
WITH p, av_from, board, unmarkeds , i.value AS lastMarked
RETURN toInteger(apoc.coll.sum(unmarkeds) * lastMarked);

// part 2
CALL {MATCH p=(first)-[:NEXT_TO*4]->(last) RETURN p
UNION
MATCH p=(first)-[:ABOVE*4]->(last) RETURN p}
WITH collect(p) AS paths, nodes(p)[0].board AS board
WITH apoc.coll.min([p in paths | apoc.coll.max([x in nodes(p) | x.available])]) AS firstBoardWin, board
WITH firstBoardWin, board ORDER BY firstBoardWin DESC LIMIT 1
MATCH (i:Item)
WHERE i.board = board AND i.available > firstBoardWin
WITH firstBoardWin, board, collect(i.value) AS unmarkeds
MATCH (i:Item)
WHERE i.board = board AND i.available = firstBoardWin
WITH firstBoardWin, board, unmarkeds , i.value AS lastMarked
RETURN toInteger(apoc.coll.sum(unmarkeds) * lastMarked)
