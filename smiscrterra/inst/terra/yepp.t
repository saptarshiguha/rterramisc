local ffi = require("ffi")

yepplib = terralib.includecstring(
[[
#include <yepLibrary.h>
#include <yepCore.h>
#include <yepMath.h>
]]
,"-I","/usr/local/include/yepp")

if ffi.os == "OSX" then
   terralib.linklibrary("libyeppp.dylib")
else
   terralib.linklibrary("libyeppp.so")
end

yepp={}
yepp.init = function()
   yepplib.yepLibrary_Init()
end

yepp.unload = function()
   yepplib.yepLibrary_Release()
end

yepp.yerCore_SumSquares_V64f_S64f = nil
yepp.yerCore_SumSquares_V64f_S64f = function(x)
   local x1 = R.Robj(x)
   local r1 = R.Robj{type="real", length=1}
   yepplib.yepCore_SumSquares_V64f_S64f( x1.ptr, r1.ptr,#x1)
   return r1
end

yepp.yepCore_DotProduct_V64fV64f_S64f = nil
yepp.yepCore_DotProduct_V64fV64f_S64f = function(x,y)
   local x1,y1 = R.Robj(x),R.Robj(y)
   local r1 = R.Robj{type="real", length=1}
   if(#x1 ~= #y1) then Rbase.Rf_error("both arguments must have same length") end
   yepplib.yepCore_DotProduct_V64fV64f_S64f( x1.ptr, y1.ptr,r1.ptr,#x1)
   return r1
end

yepp.yepCore_Add_V64fV64f_V64f = nil
yepp.yepCore_Add_V64fV64f_V64f = function(x,y)
   local x1,y1 = R.Robj(x),R.Robj(y)
   local r1 = R.Robj{type="real", length=#x1}
   if(#x1 ~= #y1) then Rbase.Rf_error("both arguments must have same length") end
   yepplib.yepCore_Add_V64fV64f_V64f( x1.ptr, y1.ptr,r1.ptr,#x1)
   return r1
end


yepp.yepCore_Multiply_V64fV64f_V64f = nil
yepp.yepCore_Multiply_V64fV64f_V64f = function(x,y)
   local x1,y1 = R.Robj(x),R.Robj(y)
   local r1 = R.Robj{type="real", length=#x1}
   if(#x1 ~= #y1) then Rbase.Rf_error("both arguments must have same length") end
   yepplib.yepCore_Multiply_V64fV64f_V64f( x1.ptr, y1.ptr,r1.ptr,#x1)
   return r1
end

yepp.yepMath_Log_V64f_V64f = nil
yepp.yepMath_Log_V64f_V64f = function(x)
   local x1 = R.Robj(x)
   local r1 = R.Robj{type="real", length=#x1}
   yepplib.yepMath_Log_V64f_V64f ( x1.ptr, r1.ptr,#x1)
   return r1
end

yepp.__lib = yepplib
return yepp
