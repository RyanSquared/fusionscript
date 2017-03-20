local itr = require("fusion.stdlib.iterable")
for i in itr.range(1, 10) do
end
for i in itr.range(1, 10) do
	print(i)
end
for i=1, 10 do
	print(i)
end
for i=1, 10 do
end
for i in itr.range(10, 1, -1) do
end
for i=10, 1, -1 do
end
for i=1, (#x) do
end
for x in y do
end
for x in y() do
end
for x in (y())() do
end
for x, y in z() do
end
while true do
	break
end
while true do
	print("test")
end
while (true) do
end
while x do
end
while (x) do
end
while x() do
end
while (x()) do
end
