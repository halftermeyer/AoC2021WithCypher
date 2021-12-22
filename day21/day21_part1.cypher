CREATE CONSTRAINT dice_face_num IF NOT EXISTS FOR (n:DiceFace) REQUIRE (n.number) IS NODE KEY;

MATCH (n) DETACH DELETE n;

CALL apoc.periodic.commit(
"MATCH (n)
WITH n LIMIT 1000
DETACH DELETE n
WITH count(n) AS limit
RETURN limit"
,{});

CREATE (n0:State:Initial {name: "player1_1", code:
"MATCH (mem:Memory)-[hs:HAS_STATE]->(curr:State)-[:NEXT]->(next:State)
SET mem.pos_1 =  1+(mem.pos_1 + mem.dice -1 )%10
SET mem.count_throw = mem.count_throw + 1
SET mem.dice = 1 + (mem.dice + 1 -1)%100
DELETE hs
CREATE (mem)-[:HAS_STATE]->(next)
RETURN 1 AS limit"
})-[:NEXT]->(:State {name: "player1_2", code:
"MATCH (mem:Memory)-[hs:HAS_STATE]->(curr:State)-[:NEXT]->(next:State)
SET mem.pos_1 =  1+(mem.pos_1 + mem.dice -1 )%10
SET mem.count_throw = mem.count_throw + 1
SET mem.dice = 1 + (mem.dice + 1 -1)%100
DELETE hs
CREATE (mem)-[:HAS_STATE]->(next)
RETURN 1 AS limit"
})-[:NEXT]->(n2:State {name: "player1_3", code:
"MATCH (mem:Memory)-[hs:HAS_STATE]->(curr:State)
WITH mem, hs, curr, 1 + (mem.pos_1 + mem.dice -1 )%10 AS new_pos
WITH mem, hs, curr, new_pos, new_pos + mem.score_1 AS new_score
SET mem.pos_1 =  new_pos
SET mem.score_1 = new_score
SET mem.count_throw = mem.count_throw + 1
SET mem.dice = 1 + (mem.dice + 1 -1)%100
WITH curr, new_score, hs, mem
MATCH (curr)-[:NEXT {game_over: new_score >= 1000}]->(next:State)
DELETE hs
CREATE (mem)-[:HAS_STATE]->(next)
RETURN 1 AS limit"
})-[:NEXT {game_over: false}]->(:State {name: "player2_1", code:
"MATCH (mem:Memory)-[hs:HAS_STATE]->(curr:State)-[:NEXT]->(next:State)
SET mem.pos_2 =  1 + (mem.pos_2 + mem.dice - 1)%10
SET mem.count_throw = mem.count_throw + 1
SET mem.dice = 1 + (mem.dice + 1 -1)%100
DELETE hs
CREATE (mem)-[:HAS_STATE]->(next)
RETURN 1 AS limit"
})-[:NEXT]->(:State {name: "player2_2", code:
"MATCH (mem:Memory)-[hs:HAS_STATE]->(curr:State)-[:NEXT]->(next:State)
SET mem.pos_2 =  1 + (mem.pos_2 + mem.dice -1 )%10
SET mem.count_throw = mem.count_throw + 1
SET mem.dice = 1 + (mem.dice + 1 -1)%100
DELETE hs
CREATE (mem)-[:HAS_STATE]->(next)
RETURN 1 AS limit"
})-[:NEXT]->(n5:State {name: "player2_3", code:
"MATCH (mem:Memory)-[hs:HAS_STATE]->(curr:State)
WITH mem, hs, curr, 1 + (mem.pos_2 + mem.dice - 1)%10 AS new_pos
WITH mem, hs, curr, new_pos, new_pos + mem.score_2 AS new_score
SET mem.pos_2 =  new_pos
SET mem.score_2 = new_score
SET mem.count_throw = mem.count_throw + 1
SET mem.dice = 1 + (mem.dice + 1 -1)%100
WITH curr, new_score, hs, mem
MATCH (curr)-[:NEXT {game_over: new_score >= 1000}]->(next:State)
DELETE hs
CREATE (mem)-[:HAS_STATE]->(next)
RETURN 1 AS limit"
})-[:NEXT {game_over: false}]->(n0)<-[:HAS_STATE]-(:Memory {score_1: 0, score_2: 0, count_throw: 0, game_over: false}),
(n2)-[:NEXT {game_over: true}]->(:State:Terminal {name: "game_over", code:
"MATCH (mem:Memory) SET mem.game_over = true
RETURN 0 AS limit"
})<-[:NEXT {game_over: true}]-(n5);

LOAD CSV FROM "file:///input_21.txt" AS line
WITH toInteger(split(line[0], '')[-1]) AS init
WITH collect(init) AS inits
MATCH (mem:Memory)
SET mem.pos_1 = inits[0]
SET mem.pos_2 = inits[1]
SET mem.dice = 1;

CALL apoc.periodic.commit(
"MATCH (mem:Memory)-[:HAS_STATE]->(s:State)
CALL apoc.cypher.doIt(s.code, {}) YIELD value
WITH value.limit AS limit
RETURN limit"
,{});

MATCH (mem:Memory)
RETURN mem.count_throw * apoc.coll.min([mem.score_1, mem.score_2]);
