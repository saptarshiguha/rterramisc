local smisc={}

local gsl = terralib.includecstring [[ 
 #include <gsl/gsl_cdf.h>
 #include <gsl/gsl_rng.h>
 #include <gsl/gsl_randist.h>
 const gsl_rng_type* get_mt19937(){
    return gsl_rng_mt19937;
  }
]]
local stdlib = terralib.includec("stdlib.h")

if jit.os == "OSX" then 
   terralib.linklibrary("libgsl.dylib")
   terralib.linklibrary("libgslcblas.dylib")
elseif  jit.os == "Linux" then 
   terralib.linklibrary("libgsl.so")
   terralib.linklibrary("libgslcblas.so")
end      


--! @brief Returns a rng using default rng type
--! @return an object of type gsl_rng 
smisc.init_default_rng = terra ()
   var rng = gsl.gsl_rng_alloc(gsl.get_mt19937())
   return rng
end
--! @brief frees an rng returned by smisc.init_rng
smisc.free_rng=terra (r : &gsl.gsl_rng )
   gsl.gsl_rng_free(r)
end

--! @brief qsort of array in place
--! @param src is a C array(zero based) of type T 
--! @param length of the array
--! @param size of a single element in T
--! @param compfunc is Terra/C function that takes two args of type T
--! The comparison function must return an integer less than, equal to,
--! or greater than zero if the first argument is considered to be
--! respectively less than, equal to, or greater than the second.  If two
--! members compare as equal, their order in the sorted array is undefined.
--! @return nil
smisc.qsort=function (src, length, size,compfunc)
   local T = compfunc:gettype()['parameters'][1] -- second must be the same
   local _cmp = terra (elem1 : &opaque, elem2: &opaque)
      var f= @([&T](elem1))
      var s= @([&T](elem2))
      return compfunc(f,s)
   end
   stdlib.qsort(src,length,size, _cmp:getdefinitions()[1]:getpointer())
end

--! @brief Computes the dot product of two vetors
--! @param x vector one
--! @param w vector two
--! @param n is the common length of both
smisc.dotproduct=terra (x:double,w:double, n:int)
   var s = 0.0
   for i=0,n-1 do
      s = s+ x[i]*w[i]
   end
   return s
end
smisc.dotproduct=terra (x:int,w:int, n:int)
   var s = 0
   for i=0,n-1 do
      s = s+ x[i]*w[i]
   end
   return s
end


smisc.stddev=terra (x:double, n:int)
   var m,s= x[0],0.0
   var mnew = 0.0
   for i = 1, n-1 do
      mnew = m+(x[i]-m)/i
      s = s + (x[i] - m)*(x[i]-mnew)
      m = mnew
   end
   return  s/(n - 1.0)
end

local function Array(typ)
    return terra(N : int)
        var r : &typ = [&typ](stdlib.malloc(sizeof(typ) * N))
        return r
    end
end

smisc.intArray = Array(int)
smisc.doubleArray = Array(double)


--! This is the default rng. Dont share this across threads.
--! Maybe you can, i'm not sure
smisc.rng = smisc.init_default_rng()
smisc.gsl=gsl

return smisc
