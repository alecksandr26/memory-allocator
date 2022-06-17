# Memory-Allocator-In-Nasm
This is my version of my memory allocator in nasm.
## Compiling
To compiled and generate the `alloc.o` just run.
```
$ make
```
## For testing
I write a `main.asm` program which test a little bit the behaivor of the alloc function, also I write c program which loads and use the `free` and `alloc` function.
## How works
Basically I move the brk address or break address 8 kilo bytes upper, to create an array where I use it to create heap, with that implementation I accomplish a runtime of `o(logn)` when `free` function gets executed. 

![image](https://user-images.githubusercontent.com/66882463/173128530-09573e90-8fdf-4c30-b51a-b51fa179ea8a.png)

And when ges execute `alloc` checks if there is a chuck with enough memory to use it, so if there is well it is going to take that chuck divided into two new chucks and return the chuck with the memory that you need and the another one will be pushed into the heap, doing a runtime again of `O(logn)`.

