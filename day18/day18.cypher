CREATE INDEX number_id IF NOT EXISTS FOR (n:Number) ON (n.id);
CREATE INDEX number_id IF NOT EXISTS FOR (n:Number) ON (n.depth);
CREATE INDEX number_id IF NOT EXISTS FOR (n:Number) ON (n.DFSLabel);

MATCH (n) DETACH DELETE n;

LOAD CSV FROM 'file:///input_18.txt' AS line FIELDTERMINATOR '#'
WITH line[0] AS line, linenumber() AS order
CREATE (:Line:Unprocessed {line: line, order:order});

// build number trees
CALL apoc.periodic.commit('
CALL apoc.cypher.runFile("load_number.cypher") YIELD result
MATCH (line:Line:Unprocessed)
WITH count(line) AS limit RETURN limit
',{});

// add trees
CALL apoc.periodic.commit('
CALL apoc.cypher.runFile("merge_2_first_trees.cypher") YIELD result
MATCH (n:Number)
WHERE n.id <> 1
WITH count(n) AS limit RETURN limit
',{});

// COMPUTE MAGNITUDE
MATCH (n:Number)
WITH n.val * 3^(apoc.text.occurences(n.DFSLabel, "0") * 2^(apoc.text.occurences(n.DFSLabel, "1") AS magnitude
RETURN sum(magnitude) AS totalMagnitude
