// part 1
LOAD CSV FROM "file:///input_1.txt" AS val
WITH apoc.coll.pairs(collect(toInteger(val[0]))) as pairs
RETURN apoc.coll.occurrences([pair IN pairs | pair[0] < pair[1]], true);

// part 2

CREATE INDEX meas_id IF NOT EXISTS FOR (m:Measurement) on (m.id);

LOAD CSV FROM "file:///input_1.txt" AS val
WITH linenumber() AS number, toInteger(val[0]) AS val
WITH {id: "meas_"+number, depth: val} AS record
WITH apoc.coll.pairs(collect(record)) AS pairs
UNWIND pairs AS pair
WITH pair WHERE EXISTS(pair[1].depth)
MERGE (first:Measurement {id: pair[0].id})
    ON CREATE SET first.depth = pair[0].depth
MERGE (second:Measurement {id: pair[1].id})
    ON CREATE SET second.depth = pair[1].depth
MERGE (first)-[:NEXT]->(second);
