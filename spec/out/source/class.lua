local class = require("fusion.stdlib.class")
Example = class({
	__init = (function(self, a)
		if not a then
			a = 5
		end
		self.a = a
	end);
	print = (function(self)
		print(self.a)
	end);
}, {}, "Example")
a = Example()
b = Example(15)
local ExampleLocal = class({}, {}, "ExampleLocal")
ExampleToo = class({
	__init = (function(self, a, b)
		if not b then
			b = 10
		end
		self.a,self.b = a,b
	end);
	print = (function()
		print(self.b)
	end);
}, {extends = Example}, "ExampleToo")
c = ExampleToo()
c:print()
Example.print(c)
ExampleThree = class({
	__init = (function(self, a, b)
		ExampleToo.__init(self,a,b)
	end);
}, {extends = ExampleToo}, "ExampleThree")
IScope = {
	close = true;
}
IO = class({
	close = (function(self)
		if (not self.closed) then
			self.closed = true
		else
			return 
		end
		self.file:close()
	end);
}, {implements = IScope}, "IO")
File = class({
	__new = (function(self, ...)
		self.file = io.open(...)
	end);
}, {extends = IO,implements = IScope}, "File")
