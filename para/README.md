This is very rudimentary and can't promise things will work. You'll need Intel's
Thread Building Blocks (TBB). Once you have that

    g++ -shared -otbb.so -ltbb tbbexample.cpp

ought to produce a file `tbb.so` in the current directory. 
