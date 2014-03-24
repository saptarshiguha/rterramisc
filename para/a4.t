tbb   = terralib.includecstring [[
  #include <tbbexample.h>
]]


stdlib = terralib.includec("stdlib.h")
stdio = terralib.includec("stdio.h")
unistd = terralib.includec("unistd.h")
terralib.linklibrary("tbb.so")

function ptable(w)
   for key,value in pairs(w) do
      print(key,value)
   end
end



function _createCounter(typ)
   local m={}
   m.uint64 = {create= tbb.create_atomic_ull_counter, fetchAndAdd  = tbb.fetch_and_add_atomic_ull_counter,
	fetchAndStore = tbb.fetch_and_store_atomic_ull_counter, get = tbb.get_atomic_ull_counter, free = tbb.free_ull_counter}
   m.int64 = {create= tbb.create_atomic_ll_counter, fetchAndAdd  = tbb.fetch_and_add_atomic_ll_counter,
	fetchAndStore = tbb.fetch_and_store_atomic_ll_counter, get = tbb.get_atomic_ll_counter, free = tbb.free_ll_counter}
   local typname = typ.name
   tbb.AtomicCounters= struct {
      _counter : &opaque;
      create: typ->{&opaque};
      fetchAndAdd: {&opaque,typ}->{typ};
      fetchAndStore: {&opaque,typ}->{typ};
      get: {&opaque}->{typ};
      free: {&opaque}->{};
			    }  
   terra tbb.AtomicCounters:add(r:typ)	return self.fetchAndAdd( self._counter, r)	end
   terra tbb.AtomicCounters:store(r:typ) return self.fetchAndStore( self._counter, r)	end
   terra tbb.AtomicCounters:get()	return self.get( self._counter)			end
   terra tbb.AtomicCounters:free()	return self.free( self._counter)		end
   function tbb.AtomicCounters.metamethods.__typename(self)
      return "AtomicCounters"
   end
   return terra( init: typ)
      var b: tbb.AtomicCounters
      b.create = [m[typname].create]
      b.fetchAndAdd = [ m[typname].fetchAndAdd]
      b.fetchAndStore = [m[typname].fetchAndStore]
      b.get = [ m[typname].get]
      b.free = [m[typname].free]
      b._counter = b.create(init)
      return b
	  end
end

ULongLongCounter = _createCounter(uint64)
LongLongCounter = _createCounter(int64)


paraply = macro(function(i,l,r,nr,gr)
		   gr = gr or 100
		   local grt = r.tree.expression.value
		   print("DKDKD")
		   print(grt)
		   print("HEYE")
		   grt:compile(false)
		   local _,fty =grt:peektype()
		   local rty = fty.returntype
		   local outsideRunner,driver=nil,nil
		   local notetype = fty.parameters[3]
		   local runnerHasReturn=function(i,q,p,op,nt)
		      if rty.name ~= 'anon' then
			 if notetype then
			    return(quote
				      var op2 = [&rty] (op)
				      op2[i] = grt(i,q,[notetype](nt))
				      end)
                         else
			    return(quote
				      var op2 = [&rty] (op)
				      op2[i] = grt(i,q)
				      end)
                        end
                      else
			 if notetype then
			    return(quote
				      grt(i,q,[notetype](nt))
				      end)
                        else 
			    return(quote
				      grt(i,q)
				      end)
                        end			 
                      end
                  end
		  local driverHasReturn=function(ii,ll,grr,nt,rty)
		     if rty.name == 'anon' then
			return quote
			   tbb.apply( [&opaque](&ii),nil,ll,grr,outsideRunner,nt)
			   end
		      else
			 return quote
			    var ret = [&&rty]( stdlib.malloc(sizeof(rty)*ll))
			    tbb.apply( [&opaque](&ii),[&&opaque](ret),ll,grr,outsideRunner,nt)
			    return ret
			    end
		      end
		  end
		   outsideRunner = terra (i:uint, p : &opaque,op:&&opaque, nt:&opaque)
		      var q = ([fty.parameters[2]])(p)
		      [runnerHasReturn(i,q,p,op,nt,rty)]
		   end
		   driver = terra(ii: i:gettype(),ll: l:gettype(), grr: int, nt: &opaque)
		      [driverHasReturn(ii,ll,grr,nt,rty) ] 
		   end
		   if nr then
		      if rty.name == 'anon' then return
			 `(driver(i, l,gr,nr))
		      else return `[&rty](driver(i, l,gr,nr)) end
		   else
		      if rty.name == 'anon' then return
			 `(driver(i, l,gr,nil))
		      else return `[&rty](driver(i, l,gr,nil)) end
		   end
		end)

terra mainRunner( i:uint, input : &&uint8, notes: &opaque)
   var b  =[&tbb.AtomicCounters](notes)
   stdio.printf("runner %d,%s\n", i,input[i])
   b:add(10)
   return 10+i
end


terra mainRunner2( i:uint, input : &&uint8,notes: &tbb.AtomicCounters)
   stdio.printf("runner %d,%s\n", i,input[i])
   notes:add(1)
   return input[i]
end

function lparaply(inputArray, N, runner,counter,gr)
   gr = gr or nil
   counter = counter or nil
   local a = terra ()
      var n:int  = [N]
      var b =  paraply(inputArray,n,runner,nil,10)
      return b
   end
   return a()
end

terra foo2()
   var N = 4
   var g = 1
   var atc = ULongLongCounter(0)
   atc:add(1)
   var input = array("one","two","threee","four")
   var output=paraply(input,N,mainRunner2,&atc)
   for i =0,4 do
      stdio.printf("%s .. %d %d, \n", output[i],i,atc:get())
   end
   atc:free()
end
-- foo2:printpretty()
foo2()
-- foo()
-- lparaply({"one","twooo","threeee"},3, mainRunner2)
