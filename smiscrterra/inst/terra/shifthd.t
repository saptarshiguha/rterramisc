local smisc = terralib.require 'smisc0'
local tbb = terralib.require('tbbwrap')
local basic = terralib.require("basic")

local A = {}
local pbeta = terra(x: double, pin: double, qin:double,lower_tail :bool)
   if lower_tail then
      return smisc.gsl.gsl_cdf_beta_P(x,pin, qin)
   else
      return smisc.gsl.gsl_cdf_beta_Q(x,pin, qin)
   end
end

doubleAscending = smisc.ascendingComparator(double)
doubleAscending:compile()
terra A.hd
terra  A.hd(x : &double,n : int,q : double)
   -- -- x is a pointer, n is length and q is the 'q' value to HD
   var w = smisc.doubleArray(n)
   var m1,m2 = (n+1.0)*q,(n+1.0)*(1.0-q)
   for i =0, n do
      w[i] = pbeta(([double](i+1))/n, m1,m2,true) - pbeta(([double](i))/n,m1,m2,true)
   end
   stdlib.qsort(x, n, sizeof(double),doubleAscending)
   var s = smisc.dotproduct(w,x,n)
   stdlib.free(w)
   return(s)
end
terra  A.hd(x : &double,n : int,q : double, w:&double)
   stdlib.qsort(x, n, sizeof(double),doubleAscending)
   var s = smisc.dotproduct(w,x,n)
   return(s)
end
A.hd:compile()

terra preComputeBetaDiff( n:int, q:double)
   var w = smisc.doubleArray(n)
   var m1,m2 = (n+1.0)*q,(n+1.0)*(1.0-q)
   for i =0, n do
      w[i] = pbeta(([double](i+1))/n, m1,m2,true) - pbeta(([double](i))/n,m1,m2,true)
   end
   return(w)
end



--------------------------------------------------------------------------------
-- Version 1, linear, mostly luajit
--------------------------------------------------------------------------------
local function bsHDVariance1(rng, dest,  src,  nb,q)
   local ha=ffi.gc(smisc.doubleArray(nb),Rbase.free)
   local wprecomp = ffi.gc( preComputeBetaDiff(#src,q),Rbase.free)
   for bootindex = 1,nb do
      smisc.gsl.gsl_ran_sample (rng, dest, #src, src.ptr, #src, sizeof(double)) -- SRSWR n out on
      ha[bootindex-1] = A.hd( dest, #src, q,wprecomp)
   end
   local s =  smisc.stddev(ha,nb)
   return(s)
end
function A.shifthd1 (x_,y_, nboot_)
   local x,y, nboot = R.Robj(R.duplicateObject(x_)), R.Robj(R.duplicateObject(y_)), R.Robj(nboot_)
   local crit = 80.1/math.pow(math.min(#x, #y),2) + 2.73
   local rng = smisc.default_rng
   local xarray,yarray =ffi.gc(smisc.doubleArray(#x),Rbase.free), ffi.gc(smisc.doubleArray(#y),Rbase.free)
   local ret = R.Robj{type='vector', length = 9}
   for i = 1,9 do
      local q = i/10
      local sex = bsHDVariance1( rng, xarray, x,  nboot[0],q)
      local sey = bsHDVariance1( rng, yarray, y,  nboot[0],q)
      local dif = A.hd(y.ptr, #y,q) - A.hd(x.ptr,#x,q)
      ret[i-1] = R.Robj{type='numeric', with = {dif-crit*math.sqrt(sex+sey), dif + crit*math.sqrt(sex+sey),dif}}
   end
   return ret
end

--------------------------------------------------------------------------------
-- Version 2, parallel,  luajit + terra
--------------------------------------------------------------------------------
local function bsHDVariance2(src,  nb,q,grain)   
   local wprecomp = ffi.gc( preComputeBetaDiff(#src,q),Rbase.free)
   grain = grain or 50
   local l = #src
   local terra fillin(index:int, input:&opaque)
      var dest = [&double](stdlib.malloc(sizeof(double)*[l]))
      var rng2 = smisc.init_default_rng ()
      smisc.gsl.gsl_ran_sample (rng2, dest, [l], [src.ptr], [l], sizeof(double)) -- SRSWR n out on
      var r = A.hd(dest,l,q,wprecomp)
      Rbase.free(dest)
      return(r)
   end
   local ha = tbb.npar{length=nb, functor=fillin,grain=grain}
   local s =  smisc.stddev(ha,nb)
   Rbase.free(ha)
   return(s)
end
function A.shifthd2 (x_,y_, nboot_,grain_)
   local x,y, nboot,grain = R.Robj(R.duplicateObject(x_)), R.Robj(R.duplicateObject(y_)), R.Robj(nboot_),R.Robj(grain_)[0]
   local crit = 80.1/math.pow(math.min(#x, #y),2) + 2.73
   local ret = R.Robj{type='vector', length = 9}
   for i = 1,9 do
      local q = i/10
      local sex = bsHDVariance2( x,  nboot[0],q,grain)
      local sey = bsHDVariance2( y,  nboot[0],q,grain)
      local dif = A.hd(y.ptr, #y,q) - A.hd(x.ptr,#x,q)
      ret[i-1] = R.Robj{type='numeric', with = {dif-crit*math.sqrt(sex+sey), dif + crit*math.sqrt(sex+sey),dif}}
   end
   return ret
end

--------------------------------------------------------------------------------
-- Version 3, parallel,  mostly terra
--------------------------------------------------------------------------------
local struct hdVarStruct {
   w: &double;
   src: &double;
   l:int;
   q:double;
	       }
terra hdVarStruct.metamethods.__apply(self: &hdVarStruct)
   var dest = smisc.doubleArray(self.l)
   var rng2 = smisc.init_default_rng ()
   smisc.gsl.gsl_ran_sample (rng2, dest, self.l,self.src, self.l, sizeof(double)) -- SRSWR n out on
   var r = A.hd(dest,self.l,self.q,self.w)
   Rbase.free(dest)
   return(r)
end

local terra runme(index:int, input:&opaque, data:&hdVarStruct)
   return data()
end

local terra bsHDVariance3( src:&double, srclength:int, nb:int,q:double,grain:double)   
   var wprecomp = preComputeBetaDiff(srclength,q)
   var qdata = hdVarStruct { w = wprecomp, src=src, l=srclength, q =q}
   var ha = tbb.papply(src, nb, runme, &qdata,grain)
   var s =  smisc.stddev(ha,nb)
   Rbase.free(ha)
   return(s)
end

local struct F2 {
   x: &double;
   y: &double;
   nx:int;
   ny:int;
   nb:int;
   grain:int
		}
function A.shifthd3 (x_,y_, nboot_,grain_)
   local x,y, nboot,grain = R.Robj(R.duplicateObject(x_)), R.Robj(R.duplicateObject(y_)), R.Robj(nboot_),R.Robj(grain_)[0]
   local crit,ret = 80.1/math.pow(math.min(#x, #y),2) + 2.73, R.Robj{type='vector', length = 9}
   local b  = terralib.new(F2, {x.ptr, y.ptr,#x,#y,nboot[0], grain})
   local terra eval_for_q(index:int, input:&double, d:&F2)
      var sex = bsHDVariance3( d.x, d.nx, d.nb, (index+1.0)/10.0 ,d.grain)
      var sey = bsHDVariance3( d.y, d.ny, d.nb, (index+1.0)/10.0 ,d.grain)
      var dif = A.hd(d.y, d.ny,(index+1.0)/10.0 ) - A.hd(d.x,d.nx,(index+1.0)/10.0 )
      return  { sex=sex, sey=sey, dif=dif}
   end
   local res = tbb.npar{ length=9,functor= eval_for_q, data=terralib.cast(&F2,b),grain=grain}
   for i = 1, 9 do
      local resa = res[i-1]
      ret[i-1] = R.Robj{type='numeric', with = {resa.dif-crit*math.sqrt(resa.sex+resa.sey), resa.dif + crit*math.sqrt(resa.sex+resa.sey),resa.dif}}
   end
   return  ret
end



return A
