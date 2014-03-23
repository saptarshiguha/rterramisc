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
   stdlib.qsort(src,length,size, compfunc:getdefinitions()[1]:getpointer())
end

function smisc.ascendingComparator(T)
   return terra(l0:&opaque, r0:&opaque)
      var l,r = @([&T](l0)), @([&T](r0))
      if  l>r  then
	 return 1
      elseif (l<r) then
	 return -1;
      else
	 return 0;
      end
	  end
end

function smisc.descendingComparator(T)
   return terra(l0:&opaque, r0:&opaque)
      var l,r = @([&T](l0)), @([&T](r0))
      if  l>r  then
	 return -1
      elseif (l<r) then
	 return 1;
      else
	 return 0;
      end
	  end
end
--! @brief Computes the dot product of two vetors
--! @param x vector one
--! @param w vector two
--! @param n is the common length of both
terra smisc.dotproduct 
for _,T  in pairs({ double, int}) do
   local I = terralib.cast(T, 0)
   terra smisc.dotproduct(x:&T,w:&T, n:int)
      var s = [I]
      for i=0,n do
	 s = s+ x[i]*w[i]
      end
      return s
   end
end
smisc.dotproduct:compile()


terra smisc.stddev(x:&double, n:int)
   var m,s= x[0],0.0
   var mnew = 0.0
   for i = 1, n-1 do
      mnew = m+(x[i]-m)/i
      s = s + (x[i] - m)*(x[i]-mnew)
      m = mnew
   end
   return  s/(n - 1.0)
end
smisc.stddev:compile()

local function Array(typ)
    return terra(N : int)
        var r : &typ = [&typ](stdlib.malloc(sizeof(typ) * N))
        return r
    end
end

smisc.intArray = Array(int)
smisc.doubleArray = Array(double)
smisc.doubleArray:compile()
smisc.intArray:compile()


--! This is the default rng. Dont share this across threads.
--! Maybe you can, i'm not sure
smisc.default_rng = smisc.init_default_rng()
smisc.gsl=gsl

return smisc
