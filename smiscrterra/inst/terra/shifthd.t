local smisc = terralib.require 'smisc0'
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
local terra hd
local terra  hd0(x : &double,n : int,q : double)
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
local terra  hd1(x : &double,n : int,q : double, w:&double)
   stdlib.qsort(x, n, sizeof(double),doubleAscending)
   var s = smisc.dotproduct(w,x,n)
   return(s)
end
hd:adddefinition(hd0)
hd:adddefinition(hd1)
hd:compile()

terra preComputeBetaDiff( n:int, q:double)
   var w = smisc.doubleArray(n)
   var m1,m2 = (n+1.0)*q,(n+1.0)*(1.0-q)
   for i =0, n do
      w[i] = pbeta(([double](i+1))/n, m1,m2,true) - pbeta(([double](i))/n,m1,m2,true)
   end
   return(w)
end

local function bsHDVariance(rng, dest,  src,  nb,q)
   local ha=ffi.gc(smisc.doubleArray(nb),Rbase.free)
   local wprecomp = ffi.gc( preComputeBetaDiff(#src,q),Rbase.free)
   for bootindex = 1,nb do
      smisc.gsl.gsl_ran_sample (rng, dest, #src, src.ptr, #src, sizeof(double)) -- SRSWR n out on
      ha[bootindex-1] = hd( dest, #src, q,wprecomp)
   end
   local s =  smisc.stddev(ha,nb)
   return(s)
end

function A.shifthd (x_,y_, nboot_)
   local x,y, nboot = R.Robj(R.duplicateObject(x_)), R.Robj(R.duplicateObject(y_)), R.Robj(nboot_)
   local crit = 80.1/math.pow(math.min(#x, #y),2) + 2.73
   local rng = smisc.default_rng
   local xarray,yarray =ffi.gc(smisc.doubleArray(#x),Rbase.free), ffi.gc(smisc.doubleArray(#y),Rbase.free)
   local ret = R.Robj{type='vector', length = 9}
   for i = 1,9 do
      local q = i/10
      local sex = bsHDVariance( rng, xarray, x,  nboot[0],q)
      local sey = bsHDVariance( rng, yarray, y,  nboot[0],q)
      local dif = hd(y.ptr, #y,q) - hd(x.ptr,#x,q)
      ret[i-1] = R.Robj{type='numeric', with = {dif-crit*math.sqrt(sex+sey), dif + crit*math.sqrt(sex+sey),dif}}
   end
   return ret
end

A.hd = hd
return A
