MATCH (n) DETACH DELETE n;
CREATE CONSTRAINT bit_pos IF NOT EXISTS FOR (b:Bit) REQUIRE (b.pos) IS NODE KEY;
WITH "0 = 0000
1 = 0001
2 = 0010
3 = 0011
4 = 0100
5 = 0101
6 = 0110
7 = 0111
8 = 1000
9 = 1001
A = 1010
B = 1011
C = 1100
D = 1101
E = 1110
F = 1111" AS hex2bin_map
WITH split(hex2bin_map, '\n') AS hex2bin_map
UNWIND hex2bin_map AS hex2bin
WITH split(hex2bin, ' = ') AS hex2bin
WITH hex2bin[0] AS hex, hex2bin[1] AS bin
MERGE (hexa:Hexa {string_repr: hex})
MERGE (binary:Binary {string_repr: bin})
MERGE (hexa)-[:HEX2BIN]->(binary);

LOAD CSV FROM 'file:///input_16.txt' AS line
WITH split(line[0],'') AS line
//WITH split("8A004A801A8002F478","") AS line
UNWIND [i IN range(0,size(line)-1) | [i, line[i]]] AS xdigit
WITH xdigit[0] AS pos, xdigit[1] AS xdigit
CREATE (xd:XDigit {pos: pos, xdigit: xdigit});


// CREATE chained list
MATCH (xd:XDigit)
MATCH (next:XDigit {pos: xd.pos +1})
CREATE (xd)-[:NEXT_XDIGIT]->(next);

// Convert to binary
MATCH (xd:XDigit), (hexa:Hexa)-[:HEX2BIN]->(binary:Binary)
WHERE xd.xdigit = hexa.string_repr
SET xd.binVal = binary.string_repr;

// CREATE bits
MATCH (xd:XDigit)
WITH [i IN range(0, 3) | [i, split(xd.binVal,'')[i]]] AS bits, xd
UNWIND bits AS bit
WITH 4 * xd.pos + bit[0] AS pos, bit[1] AS bit
CREATE (:Bit {pos: pos, bit: toInteger(bit)});

// CREATE chained list
MATCH (b:Bit)
MATCH (next:Bit {pos: b.pos +1})
CREATE (b)-[:NEXT_BIT]->(next);

CREATE (b:Bit:Processed {pos: -1})
MERGE (first:Bit {pos: 0})
CREATE (b)-[:NEXT_BIT]->(first);

// CREATE AUTOMATON (built with https://arrows.app/ import automaton.json)
CREATE (n5:State:EndPacket {type: "subpacketsLength", length: 15})-[:NEXT]->
(n0:State:Initial {type: "version", length: 3})-[:NEXT]->
(n1:State {type: "typeID", length: 3})-[:NEXT {val: [4]}]->
(n2:State {type: "number", length: 5})-[:NEXT {val: [16,17,18,19,20,21,22,23,24,25,26,27,28,29,30,31]}]->
(n2)-[:NEXT {val: [0,1,2,3,4,5,6,7,8,9,10,11,12,13,14,15]}]->(n0),
(n1)-[:NEXT {val: [0,1,2,3,5,6,7]}]->(n3:State {type: "lengthTypeID", length: 1})-[:NEXT {val: [0]}]->(n5),
(n3)-[:NEXT {val: [1]}]->(:State:EndPacket {type: "subpacketsNumber", length: 11})-[:NEXT]->(n0);

//CREATE QUEUE

MATCH (initial:State:Initial)
CREATE (q:Queue:Head:Tail)
MERGE (q)-[:TODO]->(initial)
RETURN q, initial;


CALL apoc.periodic.commit("
// PARSING STEP
MATCH (tail:Tail)-[:TODO]->(state:State)
REMOVE tail:Tail
WITH tail, state
MATCH p=(last:Processed)-[:NEXT_BIT]->(first:Bit)-[:NEXT_BIT*1..14]-(b:Bit)
WHERE NOT first:Processed
WITH tail, state, nodes(p) AS bits
UNWIND bits AS bit
WITH DISTINCT bit, tail, state ORDER BY bit.pos
WITH collect(bit) AS bits, tail, state
WITH bits [1..state.length + 1] AS bits, tail, state
FOREACH (bit IN bits | SET bit:Processed)
WITH reduce(acc=0, bit IN bits | acc * 2 + bit.bit) AS val,
    tail, state, bits, bits[0] AS first_bit, bits[-1] AS last_bit
CREATE (q:Queue:Tail {type: state.type, val:val})
MERGE (tail)-[:QUEUE_NEXT]->(q)
MERGE (q)-[:FIRST_BIT]->(first_bit)
MERGE (q)-[:LAST_BIT]->(last_bit)
SET q.length = state.length
WITH q, val, tail, state, bits
WITH q, val, tail, state, bits
MATCH (state)-[r:NEXT]->(next_step:State)
WHERE r.val IS NULL OR apoc.coll.contains(r.val, val)
WITH q, val, tail, state, bits, next_step
MERGE (q)-[:TODO]->(next_step)
WITH count(*) AS limit RETURN limit"
, {});

MATCH (q:Queue)
WHERE q.type = "version"
RETURN sum(q.val) AS result_part_1;
