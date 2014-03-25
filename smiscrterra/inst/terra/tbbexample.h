#ifndef	__mytbb_h
#define	__mytbb_h

#define oTYPE void**

#ifdef __cplusplus 
extern "C" {
#endif

  void apply( void *, oTYPE ,unsigned int, unsigned int,void  (*runner)(unsigned int i,void *,oTYPE,void*),void*);
  void* create_atomic_ull_counter(unsigned long long  );
  unsigned long long fetch_and_add_atomic_ull_counter(void*,unsigned long long  );
  unsigned long long fetch_and_store_atomic_ull_counter(void*,unsigned long long  );
  unsigned long long get_atomic_ull_counter(void*);
  void free_ull_counter( void*);
  
  void* create_atomic_ll_counter(long long );
  long long fetch_and_add_atomic_ll_counter(void*,long long  );
  long long fetch_and_store_atomic_ll_counter(void*,long long  );
  long long get_atomic_ll_counter(void*);
  void free_ll_counter( void*);
  
#ifdef __cplusplus
}
#endif


#endif
