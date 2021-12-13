CREATE BTREE INDEX dot_coords IF NOT EXISTS FOR (n:Dot) ON (n.x, n.y, n.fold);

MATCH (n) DETACH DELETE n;

LOAD CSV FROM "file:///input_13.txt" AS dot
WITH dot
WHERE size(dot) = 2
WITH [coord IN dot | toInteger(coord)] AS dot
CREATE (:Dot {x: dot[0], y: dot[1], fold: 0});

CALL apoc.periodic.iterate("
  LOAD CSV FROM 'file:///input_13.txt' AS fold
  WITH fold, linenumber() - 959 AS folding_step
  WHERE size(fold) = 1
  WITH split(split(fold[0], ' ')[2], '=') AS fold, folding_step
  WITH [fold[0], toInteger(fold[1])] AS fold, folding_step
  WITH fold, folding_step
  WITH fold[0] AS coord, fold[1] AS val, folding_step
  RETURN coord, val, folding_step
",
"
  MATCH (d:Dot)
  WHERE d.fold = folding_step - 1
  WITH d, coord, val, folding_step,
  CASE d[coord] > val
      WHEN true THEN
          CASE coord
              WHEN 'x' THEN {x: 2 * val - d.x, y: d.y, fold: folding_step}
              ELSE {x: d.x, y:2 * val - d.y, fold: folding_step}
          END
      ELSE
          {x: d.x, y: d.y, fold: folding_step}
  END AS new_dot
  MERGE (new:Dot {x: new_dot.x, y: new_dot.y, fold: new_dot.fold})
  MERGE (d)-[:FOLDS_TO {step: folding_step}]->(new)
", {batchSize: 1});

// part 1

MATCH (d:Dot) WHERE d.fold = 1 RETURN count(*);

// part 2

CALL apoc.custom.asFunction(
  'pixelFromDotCoordsAndFold',
  'MATCH (d:Dot {x: $x, y: $y, fold: $fold})
  RETURN CASE count(*) > 0 WHEN true THEN "#" ELSE " " END',
  'string',
  [['x','number'], ['y','number'], ['fold','number']]
);

MATCH (d:Dot)
WITH max(d.fold) AS fold
MATCH (d:Dot) WHERE d.fold = fold
WITH max(d.x) AS max_x, max(d.y) AS max_y, fold
RETURN apoc.text.join([
  y IN range(0,max_y) |
    apoc.text.join([x IN range(0,max_x) |
      custom.pixelFromDotCoordsAndFold(x,y,fold)], '')], '\n') AS result;


//      ##  ####   ## #  # #    #  #  ##    ##
//     #  # #       # # #  #    #  # #  #    #
//     #    ###     # ##   #    #  # #       #
//     #    #       # # #  #    #  # # ##    #
//     #  # #    #  # # #  #    #  # #  # #  #
//      ##  ####  ##  #  # ####  ##   ###  ##
