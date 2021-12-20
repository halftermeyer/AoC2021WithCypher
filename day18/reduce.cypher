// explode
CALL apoc.periodic.commit('
  CALL apoc.cypher.runFile("explode.cypher") YIELD result
  MATCH (n0)-[r:DFS_NEXT]->(n1)
  WHERE substring(n0.DFSLabel, 0, size(n0.DFSLabel)-1)= substring(n1.DFSLabel, 0, size(n1.DFSLabel)-1)
  AND n0.id = 1
  AND size(n0.DFSLabel) = 5
  WITH * LIMIT 1
  WITH count(*) AS limit RETURN limit
',{});

// split
CALL apoc.cypher.runFile("split.cypher") YIELD result
RETURN result;
