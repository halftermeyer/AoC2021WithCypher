// part 1
LOAD CSV FROM 'file:///input_8.txt' AS line  FIELDTERMINATOR '|'
WITH linenumber() AS entry, split(trim(line[1]), ' ') AS displayedDigits
UNWIND displayedDigits AS digit
WITH entry, digit, size(digit) AS len
WHERE len IN [2, 4, 3, 7]
RETURN count(*)

// part 2
CREATE CONSTRAINT digit_val IF NOT EXISTS
FOR (n:Digit)
REQUIRE n.val IS NODE KEY;
CREATE CONSTRAINT entry_id IF NOT EXISTS
FOR (n:Entry)
REQUIRE n.id IS NODE KEY;
CREATE CONSTRAINT display_display IF NOT EXISTS
FOR (n:Display)
REQUIRE n.display IS NODE KEY;
CREATE CONSTRAINT matching_entry_digit IF NOT EXISTS
FOR (n:Matching)
REQUIRE (n.entry, n.digit) IS NODE KEY;


// Create straightforward matchings for unique-segment-number digit
LOAD CSV FROM 'file:///input_8.txt' AS line  FIELDTERMINATOR '|'
WITH linenumber() AS entry, split(trim(line[0]), ' ') AS displayedDigits
UNWIND displayedDigits AS display
WITH entry, display, size(display) AS len
WHERE len IN [2, 4, 3, 7]
WITH entry, display, len, CASE len
  WHEN 2 THEN 1
  WHEN 4 THEN 4
  WHEN 3 THEN 7
  WHEN 7 THEN 8 END AS digit
MERGE (e:Entry {id: entry})
MERGE (d:Display {display: display})
MERGE (dig:Digit {val: digit})
MERGE (m:Matching {entry: entry, digit: digit})
MERGE (e)-[:HAS_MATCHING]->(m)-[:FROM]->(d)
MERGE (m)-[:TO]->(dig);

// Create matchings for 6-segment-number digit
// Discriminate by comparing to 1 and 4
LOAD CSV FROM 'file:///input_8.txt' AS line  FIELDTERMINATOR '|'
WITH linenumber() AS entry, split(trim(line[0]), ' ') AS displayedDigits
UNWIND displayedDigits AS display
WITH entry, display, size(display) AS len
WHERE len IN [6]
MATCH (e:Entry {id:entry})-[:HAS_MATCHING]->(m1)-[:TO]->(d:Digit {val: 1}),
(m1)-[:FROM]->(d1:Display),
(e)-[:HAS_MATCHING]->(m7)-[:TO]->(:Digit {val: 4}),
(m7)-[:FROM]->(d4:Display)
WITH entry, display,
  CASE apoc.coll.containsAll(split(display,''), split(d1.display,''))
  WHEN false THEN 6 ELSE
    CASE apoc.coll.containsAll(split(display,''), split(d4.display,''))
    WHEN true THEN 9 ELSE 0 END
  END AS digit
MERGE (e:Entry {id: entry})
MERGE (d:Display {display: display})
MERGE (dig:Digit {val: digit})
MERGE (m:Matching {entry: entry, digit: digit})
MERGE (e)-[:HAS_MATCHING]->(m)-[:FROM]->(d)
MERGE (m)-[:TO]->(dig);

// Create matchings for 5-segment-number digit
// Discriminate by comparing to 1 and 6
LOAD CSV FROM 'file:///input_8.txt' AS line  FIELDTERMINATOR '|'
WITH linenumber() AS entry, split(trim(line[0]), ' ') AS displayedDigits
UNWIND displayedDigits AS display
WITH entry, display, size(display) AS len
WHERE len IN [5]
MATCH (e:Entry {id:entry})-[:HAS_MATCHING]->(m1)-[:TO]->(d:Digit {val: 1}),
(m1)-[:FROM]->(d1:Display),
(e)-[:HAS_MATCHING]->(m7)-[:TO]->(:Digit {val: 6}),
(m7)-[:FROM]->(d6:Display)
WITH entry, display,
  CASE apoc.coll.containsAll(split(display,''), split(d1.display,''))
  WHEN true THEN 3 ELSE
    CASE apoc.coll.containsAll(split(d6.display,''), split(display,''))
    WHEN true THEN 5 ELSE 2 END
  END AS digit
MERGE (e:Entry {id: entry})
MERGE (d:Display {display: display})
MERGE (dig:Digit {val: digit})
MERGE (m:Matching {entry: entry, digit: digit})
MERGE (e)-[:HAS_MATCHING]->(m)-[:FROM]->(d)
MERGE (m)-[:TO]->(dig);

// Decode
LOAD CSV FROM 'file:///input_8.txt' AS line  FIELDTERMINATOR '|'
WITH linenumber() AS entry, split(trim(line[1]), ' ') AS outDisplays
WITH entry, [x IN range(0,3)| [x, outDisplays[x]]] AS outDisplays
UNWIND outDisplays AS out
WITH entry, out[0] AS ord, out[1] AS out
MATCH (e:Entry {id:entry})-[:HAS_MATCHING]->(m)-[:FROM]->(disp:Display),
(m)-[:TO]->(d:Digit)
WHERE apoc.coll.sort(apoc.coll.toSet(split(disp.display,''))) = apoc.coll.sort(apoc.coll.toSet(split(out,'')))
WITH entry, ord, out, d.val AS val, d.val * 10^(3-ord) AS dec_value
RETURN toInteger(sum(dec_value));
