import re
a_file = open("input.txt")

first = True
i = -1
boards = []

for line in a_file:
    line = line.strip()
    if first:
        draws = [int(x) for x in line.split(',')]
        first = False
        continue
    if line == "":
        i +=1
        boards.append([])
        continue
    line = [int(x) for x in re.split(r' +', line)]
    boards[i].append(line)
print("CREATE ")
for board_i, board in enumerate(boards):
    for line_j, line in enumerate(board):
        for item_k, item in enumerate(line):
            available = draws.index(item)
            print(f"(:Item {{board: {board_i}, line: {line_j}, col: {item_k}, value: {item}, available: {available}}}),")
        
