// part 2
CALL apoc.periodic.commit("
    MATCH (n)
    WITH n LIMIT 1000
    DETACH DELETE n
    RETURN count(n) AS limit",
    {});

CREATE CONSTRAINT pair IF NOT EXISTS
FOR (p:Pair)
REQUIRE (p.step, p.left, p.right) IS NODE KEY;
CREATE CONSTRAINT step IF NOT EXISTS
FOR (s:Step)
REQUIRE (s.step) IS NODE KEY;


CREATE INDEX rule_elements IF NOT EXISTS FOR (rule:Rule) ON (rule.left, rule.right);

// rules
LOAD CSV FROM "file:///input_14.txt" AS rule
WITH rule WHERE rule[0] CONTAINS "->"
WITH split(rule[0], " -> ") AS rule
WITH split(rule[0], '')[0] AS el_left, split(rule[0], '')[1] AS el_right, trim(rule[1]) as el_between
MERGE (:Rule {left: el_left, right: el_right, between: el_between});

// extremities
LOAD CSV FROM "file:///input_14.txt" AS polymerTemplate
WITH polymerTemplate
WHERE NOT polymerTemplate[0] CONTAINS "->"
WITH polymerTemplate[0] AS polymerTemplate
WITH left(polymerTemplate,1) AS left, ""+ right(polymerTemplate,1) AS right
CREATE (extremities:Extremities {first: left, last: right,  cardinality:1})
WITH extremities, left, right
CALL apoc.create.setProperties(extremities, [left, right], [1,1])
YIELD node
RETURN node;

// first line
LOAD CSV FROM "file:///input_14.txt" AS polymerTemplate
WITH polymerTemplate
WHERE NOT polymerTemplate[0] CONTAINS "->" AND size(polymerTemplate[0]) > 0
WITH split(polymerTemplate[0], '') AS polymerTemplate
UNWIND apoc.coll.pairsMin(polymerTemplate) AS pair
WITH pair, count(pair) AS cardinality
CREATE (p:Pair {left:pair[0], right: pair[1], label:pair[0]+pair[1],  cardinality: cardinality, step: 0})
RETURN p;

// apply the grammar 40 times
CALL apoc.periodic.commit("
MATCH (p:Pair)
WITH max(p.step) AS last_step
MATCH (p:Pair)
WHERE p.step = last_step AND last_step < 40
WITH p, last_step
MATCH (r:Rule)
WHERE r.left = p.left
AND r.right = p.right
WITH [[p.left, r.between],[r.between, p.right]] AS spawn_pairs, p, last_step
UNWIND spawn_pairs AS spawn_pair
WITH spawn_pair, sum(p.cardinality) AS cardinality, last_step
CREATE (spawn_p:Pair {left:spawn_pair[0], right: spawn_pair[1], label:spawn_pair[0]+spawn_pair[1],  cardinality: cardinality, step: last_step + 1})
WITH count(spawn_p) AS limit
RETURN limit"
,{});

//get the result
CALL {
    MATCH (p:Pair)
    RETURN  p.left AS el
UNION
    MATCH (p:Pair)
    RETURN  p.right AS el
}
WITH el
CALL {
    WITH el
    MATCH (n:Pair)
    WHERE n.step = 40 AND n.left CONTAINS el
    RETURN sum(n.cardinality) AS cardinality
UNION ALL
    WITH el
    MATCH (n:Pair)
    WHERE n.step = 40 AND n.right CONTAINS el
    RETURN sum(n.cardinality) AS cardinality
}
WITH el, sum(cardinality) AS cardinality
MATCH (ex:Extremities)
WITH el, cardinality + CASE el IN [ex.first, ex.last] WHEN true THEN 1 ELSE 0 END AS cardinality
WITH el, cardinality ORDER BY cardinality DESC
WITH collect(cardinality) AS cardinalities
WITH cardinalities
RETURN (cardinalities[0]-cardinalities[-1])/2;
