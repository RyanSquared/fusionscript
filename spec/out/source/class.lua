local class = require("fusion.stdlib.class")
Example = class({
	__init = (function(a)
		if not a then
			a = 5
		end
		self.a = a
	end);
	print = (function()
		print(self.a)
	end);
}, nil, "Example")
a = Example()
b = Example(15)
ExampleToo = class({
	__init = (function(a, b)
		if not b then
			b = 10
		end
		self.a,self.b = a,b
	end);
	print = (function()
		print(self.b)
	end);
}, Example, "ExampleToo")
c = ExampleToo()
c:print()
Example.print(c)
ExampleThree = class({
	__init = (function(a, b)
		ExampleToo.__init(self,a,b)
	end);
}, ExampleToo, "ExampleThree")
