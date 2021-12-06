:param num_generation => 256;

CREATE CONSTRAINT aggFish IF NOT EXISTS
FOR (n:AggregatedLanternFish)
REQUIRE n.timerBin IS UNIQUE;

MATCH (n) DETACH DELETE n;

// create a flow-like graph
// A node is a timer bin
// It points at timer bins to which
// it spill each generation

// creating bins
UNWIND range(0, 8) AS bin
CREATE (:AggregatedLanternFish {timerBin: bin, number: 0});

// creating one-day less before reproduction links
MATCH (bin:AggregatedLanternFish)
MATCH (next:AggregatedLanternFish {timerBin: CASE bin WHEN -1 THEN 6 ELSE bin.timerBin - 1 END})
CREATE (bin)-[:ADDS_ONE_TO]->(next);

// creating reproduction links
UNWIND [6, 8] AS nextBin
MATCH (binZero:AggregatedLanternFish {timerBin:0})
MATCH (next:AggregatedLanternFish {timerBin: nextBin})
CREATE (binZero)-[:ADDS_ONE_TO]->(next);

// initial effective for each bin
LOAD CSV FROM 'file:///input_6.txt' AS line  FIELDTERMINATOR ',' // comment for testing
// WITH ["3","4","3","1","2"] AS line // test data
WITH [x IN line | toInteger(x)] as dayss
UNWIND dayss AS days
MATCH (bin:AggregatedLanternFish {timerBin:days})
SET bin.number = bin.number + 1;

// iterate over generations
CALL apoc.periodic.iterate("UNWIND range(1,$num_generation) AS generation RETURN generation",
"
// bufferize to out-link
CALL {MATCH (l:AggregatedLanternFish)-[buffer:ADDS_ONE_TO]->() SET buffer.number = l.number}
// read from in-links
CAll {MATCH ()-[buffer:ADDS_ONE_TO]->(next:AggregatedLanternFish)
WITH sum(buffer.number) as number, next
SET next.number = number}
", {batchSize:1, params: {num_generation: $num_generation}})
