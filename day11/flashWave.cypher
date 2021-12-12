CALL apoc.periodic.commit("
        CALL {
            MATCH (o:Octopus:NotFlashed)
            WHERE o.energy > 9
            SET o.energy = 0
            SET o.flashes = o.flashes + 1
            REMOVE o:NotFlashed
            SET o:JustFlashed
            WITH o
            MATCH (o)-[r:NEXT_TO]->()
            SET r.gives_energy = 1
        }
        CALL {
            MATCH (o:Octopus:NotFlashed)<-[r:NEXT_TO]-()
            WHERE r.gives_energy > 0
            WITH sum(r.gives_energy) AS energy, o
            SET o.energy = o.energy + energy
        }
        CALL {
            MATCH ()-[r:NEXT_TO]->()
            WHERE r.gives_energy > 0
            SET r.gives_energy = 0
        }
        CALL {
          MATCH (o:Octopus) WHERE o:JustFlashed
          REMOVE o:JustFlashed
          RETURN count(o) AS limit
        }
        RETURN limit
    ", {limit: 10000}) YIELD batches
    RETURN batches
