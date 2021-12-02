// part 1
LOAD CSV FROM "file:///input_2.txt" AS line FIELDTERMINATOR ' '
WITH line[0] AS dir, toInteger(line[1]) AS units
WITH dir, sum(units) AS sum
WITH collect([dir, sum]) AS pairs
WITH apoc.map.fromPairs(pairs) AS map
RETURN (map.down - map.up) * map.forward;

// part 2

CREATE INDEX command_id IF NOT EXISTS FOR (c:Command) on (c.id);

// Let's clean
MATCH (n) DETACH DELETE n;

// Construct a path graph with commands
LOAD CSV FROM "file:///input_2.txt" AS line FIELDTERMINATOR ' '
WITH line[0] AS dir, toInteger(line[1]) AS units
WITH apoc.coll.pairs(collect([dir, units])) as pairs
WITH pairs, size(pairs) AS length
WITH range(1,length) as nums, pairs
WITH apoc.coll.zip(nums, pairs) AS records
UNWIND records AS record
WITH record WHERE record[1][1] IS NOT null
WITH record
MERGE (c1:Command {id: record[0]})
    ON CREATE
        SET c1.dir = record[1][0][0]
        SET c1.units = record[1][0][1]
MERGE (c2:Command {id: record[0] + 1})
    ON CREATE
        SET c2.dir = record[1][1][0]
        SET c2.units = record[1][1][1]
CREATE (c1)-[:NEXT]->(c2);

// add a "origin" node with values to zero
MATCH (first)
WHERE NOT EXISTS(()-->(first))
MERGE (origin:Command {id:0})
SET origin.aim = 0
SET origin.position = 0
SET origin.depth = 0
SET origin.processed = true
CREATE (origin)-[:NEXT]->(first);

// periodically process first unprocessed node in path
CALL apoc.periodic.commit('
MATCH (a)-->(b) WHERE EXISTS(a.processed) AND NOT EXISTS(b.processed)
WITH a.aim AS aim, a.position AS pos, a.depth AS depth, b.dir AS dir, b.units AS units, b
SET b.position = CASE dir
    WHEN "up" THEN pos
    WHEN "down" THEN pos
    WHEN "forward" THEN pos + units
END
SET b.aim = CASE dir
    WHEN "up" THEN aim - units
    WHEN "down" THEN aim + units
    WHEN "forward" THEN aim
END
SET b.depth = CASE dir
    WHEN "up" THEN depth
    WHEN "down" THEN depth
    WHEN "forward" THEN (aim * units) + depth
END
SET b.processed = true
RETURN count(*) AS limit
', {limit: 1001});

// get final answer

MATCH (n) WHERE NOT EXISTS((n)-->())
RETURN n.position * n.depth
