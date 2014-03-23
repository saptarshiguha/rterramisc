
local smisc0 = terralib.require 'smisc0'
local shifthd = terralib.require 'shifthd'

local smisc = {}
for _,T in pairs({ smisc0, shifthd}) do
   for a,b in pairs(T) do
      smisc[a] = b
   end
end

return smisc
