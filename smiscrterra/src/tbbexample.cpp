#include "tbbexample.h"
#include "tbb/parallel_for.h"
#include "tbb/blocked_range.h"
#include "tbb/atomic.h"

using namespace tbb;


struct Executor {
  void* input;
  oTYPE output;
  void *notes;
  void  (*runner)(unsigned int, void *,oTYPE,void*);
  void operator()( const blocked_range<unsigned int>& range ) const {
    for( int i=range.begin(); i!=range.end(); ++i ){
      runner(i,input,output,notes);
    }
  }
};



extern "C" {
  void apply(void * input, oTYPE output,unsigned int n,unsigned int grain, void  (*runner)(unsigned int,void *,oTYPE,void*),void* notes){
    Executor e;
    e.input = input;
    e.output = output;
    e.runner = runner;
    e.notes = notes;
    blocked_range<unsigned int> rr = blocked_range<unsigned int>(0,n);
    parallel_for( rr, e);
  }

  void*  create_atomic_ull_counter(unsigned long long l ){
    atomic<unsigned long long>* x  = new atomic<unsigned long long>();
    x->fetch_and_add(l);
    return static_cast<void*>(x);
  }
  unsigned long long fetch_and_add_atomic_ull_counter(void *p, unsigned long long  a){
    atomic<unsigned long long> * pp = static_cast< atomic<unsigned long long>* >(p);
    return pp->fetch_and_add(a);
  }
  unsigned long long fetch_and_store_atomic_ull_counter(void *p, unsigned long long  a){
    atomic<unsigned long long> * pp = static_cast< atomic<unsigned long long>* >(p);
    return pp->fetch_and_store(a);
  }
  unsigned long long get_atomic_ull_counter(void *p){
    atomic<unsigned long long> * pp = static_cast< atomic<unsigned long long>* >(p);
    return *pp;
  }
  void free_ull_counter(void *p){
    if(p){
      atomic<unsigned long long> * pp = static_cast< atomic<unsigned long long>* >(p);
      delete(pp);
	}
  }

  void*  create_atomic_ll_counter(long long l ){
    atomic<long long>* x  = new atomic<long long>();
    x->fetch_and_add(l);
    return static_cast<void*>(x);
  }
  long long fetch_and_add_atomic_ll_counter(void *p, long long  a){
    atomic<long long> * pp = static_cast< atomic<long long>* >(p);
    return pp->fetch_and_add(a);
  }
  long long fetch_and_store_atomic_ll_counter(void *p, long long  a){
    atomic<long long> * pp = static_cast< atomic<long long>* >(p);
    return pp->fetch_and_store(a);
  }
  long long get_atomic_ll_counter(void *p){
    atomic<long long> * pp = static_cast< atomic<long long>* >(p);
    return *pp;
  }
  void free_ll_counter(void *p){
    if(p){
      atomic<unsigned long long> * pp = static_cast< atomic<unsigned long long>* >(p);
      delete(pp);
	}
  }

}

