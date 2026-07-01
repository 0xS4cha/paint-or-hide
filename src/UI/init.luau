return function()
	for _, moduleScript in script:GetDescendants() do
		if not moduleScript:IsA("ModuleScript") then continue end
		local feature = require(moduleScript)
		if type(feature) == "table" and feature.init and not feature.render then
			feature:init()
		end
	end
end
