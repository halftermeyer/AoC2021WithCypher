// part 1

LOAD CSV FROM "file:///input_3.txt" AS line
WITH line[0] AS line LIMIT 1
WITH size(line) AS length
WITH [x in range(0, length - 1) | 0] AS zero_list
CREATE (acc:Tmp {id: "acc"})
SET acc.ones = zero_list
SET acc.zeros = zero_list;

MATCH (acc:Tmp)
LOAD CSV FROM "file:///input_3.txt" AS line
WITH split(line[0], '') AS line, acc
WITH collect(line) as lines, acc
FOREACH (line IN lines |
    FOREACH (i IN range(0, size(line) - 1) |
        SET acc.ones = apoc.coll.set(acc.ones, i, acc.ones[i] + toInteger(line[i]))
        SET acc.zeros = apoc.coll.set(acc.zeros, i, acc.zeros[i] + 1 - toInteger(line[i]))
    )
);

MATCH (acc:Tmp)
SET acc.moreOnes = [i in range(0, size(acc.ones) - 1) | CASE acc.ones[i] > acc.zeros[i] WHEN true THEN 1 ELSE 0 END]
SET acc.moreZeros = [i in range(0, size(acc.ones) - 1) | CASE acc.zeros[i] > acc.ones[i] WHEN true THEN 1 ELSE 0 END];


MATCH (acc:Tmp)
WITH acc, size(acc.ones) as len
SET acc.gamma = apoc.coll.sum([i in range(0, len - 1) | acc.moreOnes[i] * 2^(len-1-i)])
SET acc.epsilon = apoc.coll.sum([i in range(0, len - 1) | acc.moreZeros[i] * 2^(len-1-i)]);

match (acc:Tmp) return toInteger(acc.epsilon * acc.gamma);

// part 2

MATCH (n) DELETE n;

LOAD CSV FROM "file:///input_3.txt" AS line
WITH split(line[0], '') AS line
WITH collect(line) as lines
FOREACH(l_num IN range(0, size(lines)-1) |
    CREATE (c:Command {id: "c_"+l_num, command: lines[l_num], majorityTimes: 0, minorityTimes: 0})
);

CREATE (:Counter {iteration: 0});

CALL apoc.periodic.commit('
    MATCH (cnt:Counter) WITH cnt LIMIT 1 WITH cnt.iteration AS i, cnt
    SET cnt.iteration = cnt.iteration + 1
    WITH i
    MATCH (c:Command) WHERE c.majorityTimes = i
    WITH count(c.command[i]) AS effective, toInteger(c.command[i]) AS tieBreaker, c.command[i] AS bit, i
    ORDER BY effective DESC, tieBreaker DESC LIMIT 1
    MATCH (maj:Command) WHERE maj.majorityTimes = i AND maj.command[i] = bit
    SET maj.majorityTimes = maj.majorityTimes + 1
    RETURN 1 AS LIMIT
', {limit: 12});

MATCH (cnt:Counter) SET cnt.iteration = 0;

CALL apoc.periodic.commit('
    MATCH (cnt:Counter) WITH cnt LIMIT 1 WITH cnt.iteration AS i, cnt
    SET cnt.iteration = cnt.iteration + 1
    WITH i
    MATCH (c:Command) WHERE c.minorityTimes = i
    WITH count(c.command[i]) AS effective, toInteger(c.command[i]) AS tieBreaker, c.command[i] AS bit, i
    ORDER BY effective ASC, tieBreaker ASC LIMIT 1
    MATCH (min:Command) WHERE min.minorityTimes = i AND min.command[i] = bit
    SET min.minorityTimes = min.minorityTimes + 1
    RETURN 1 AS LIMIT
', {limit: 12});


MATCH (alwaysMaj:Command) WITH alwaysMaj ORDER BY alwaysMaj.majorityTimes DESC LIMIT 1
MATCH (alwaysMin:Command) WITH alwaysMaj, alwaysMin ORDER BY alwaysMin.minorityTimes DESC LIMIT 1
WITH alwaysMin, alwaysMaj
WITH apoc.coll.sum([i in range(0, 11) | toInteger(alwaysMin.command[i]) * 2^(12-1-i)]) AS co2, apoc.coll.sum([i in range(0, 11) | toInteger(alwaysMaj.command[i]) * 2^(12-1-i)]) AS oxy
RETURN toInteger(co2 * oxy);
