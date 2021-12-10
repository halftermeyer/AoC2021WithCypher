// ingestion

MATCH (n) DETACH DELETE n;

LOAD CSV FROM 'file:///input_10.txt' AS line
WITH linenumber() AS line_no, split(line[0], '') AS line
CREATE (:Line {id: line_no, line: line});

// part 1

MATCH (l:Line)
WITH l, apoc.map.fromPairs([[')','('], ['}','{'], [']','['], ['>', '<']]) AS par_map
SET l.stack = reduce(stack = [], chunk IN l.line |
  CASE stack [0]
    WHEN 'ILLEGAL' THEN stack
    ELSE
      CASE chunk IN ['(', '{', '[', '<']
        WHEN true
          THEN apoc.coll.insert(stack, 0, chunk)
        ELSE
          CASE par_map[chunk] = stack[0]
            WHEN true THEN apoc.coll.remove(stack, 0)
            ELSE ['ILLEGAL', chunk]
        END
      END
    END)

WITH apoc.map.fromPairs([[')',3], ['}',1197], [']',57], ['>', 25137]]) AS points_map
MATCH (l) WHERE l.stack[0] = 'ILLEGAL'
RETURN sum(points_map[l.stack[1]])

// part 2

WITH apoc.map.fromPairs([['(',1], ['[',2], ['{',3], ['<', 4]]) AS points_map
MATCH (l) WHERE l.stack[0] <> 'ILLEGAL'
WITH reduce(total= 0, chunk in l.stack |
    total * 5 + points_map[chunk]
) AS score ORDER BY score
WITH collect(score) AS scores
RETURN scores[size(scores)/2]
