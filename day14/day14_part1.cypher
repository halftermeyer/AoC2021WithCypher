CREATE CONSTRAINT element IF NOT EXISTS
FOR (el:Element)
REQUIRE (el.element, el.id) IS NODE KEY;

CREATE INDEX rule_elements IF NOT EXISTS FOR (rule:Rule) ON (rule.left, rule.right);

CREATE INDEX next_step IF NOT EXISTS FOR ()-[r:NEXT]-() ON (r.step);

CALL apoc.periodic.commit("
    MATCH (n)
    WITH n LIMIT 1000
    DETACH DELETE n
    RETURN count(n) AS limit",
    {});

LOAD CSV FROM "file:///input_14.txt" AS polymerTemplate
WITH polymerTemplate
WHERE NOT polymerTemplate[0] CONTAINS "->"
WITH  [el IN split(polymerTemplate[0], '') | {element: el, id:apoc.create.uuid()}] AS polymerTemplate
UNWIND apoc.coll.pairsMin(polymerTemplate) AS pair
MERGE (e1:Element {element:pair[0].element, id:pair[0].id})
MERGE (e2:Element {element:pair[1].element, id:pair[1].id})
CREATE (e1)-[:NEXT {step: 0}]->(e2);

LOAD CSV FROM "file:///input_14.txt" AS rule
WITH rule WHERE rule[0] CONTAINS "->"
WITH split(rule[0], " -> ") AS rule
WITH split(rule[0], '')[0] AS el_left, split(rule[0], '')[1] AS el_right, trim(rule[1]) as el_between
MERGE (:Rule {left: el_left, right: el_right, between: el_between});

// part 1

// apply rules
CALL apoc.periodic.iterate("
  UNWIND range(1,10) AS step
  RETURN step
  ",
  "
  MATCH (left:Element)-[r:NEXT]->(right:Element), (rule:Rule)
  WHERE r.step = step - 1
  AND rule.left = left.element
  AND rule.right = right.element
  CREATE (between:Element {element:rule.between, id:apoc.create.uuid()})
  CREATE (left)-[:NEXT {step: step}]->(between)-[:NEXT {step: step}]->(right)",
  {batchSize: 1});

// get result
MATCH (el:Element)-[r:NEXT]-(t)
WHERE r.step = 10
WITH DISTINCT el
WITH el.element AS elemeny, count(el) AS number_el
ORDER BY number_el DESC
