## Compiling VHDL For The Missing Fixed Point Libraries

The latest approved [IEEE 1076 standard (termed VHDL-2008)](https://ieeexplore.ieee.org/document/4772740|) adds signed (`sfixed`) and unsigned (`ufixed`) fixed-point data types and a set of primitives for their manipulation. The VHDL fixed-point package provides synthesizable implementations of fixed-point primitives for arithmetic, scaling and operand resizing. Sadly it takes a while for tools to catch up, and the free versions of tools such as "Web Packs" are well behind the latest. This means that these new types are not always available to try out. Thankfully David Bishop created a good VHDL-93 compliant version of the library which can be compiled up and I have got ModelSim, Vivado and Quartus Prime to simulate and synthesise fixed point arithmetic using the libraries. However the compilation was not quite as straight forward as you might hope. Here's how I did it in case you need the same.

Please read the blog post [Compiling VHDL For The Missing Fixed Point Libraries](http://blog.abbey1.org.uk/index.php/technology/compiling-vhdl-for-the-missing-fixed-point-libraries) to explain how the code works in detail.

## Compilation

1. Compile VHDL library [local](../Local) if you have not already done so.
2. Compile the missing fixed point libraries with [modelsim_compile_sfixed.cmd](modelsim_compile_sfixed.cmd).
3. Run the [modelsim_compile.cmd](modelsim_compile.cmd) Windows batch file.

Assumes the following directory already exists and hence will fail to compile if it does not. Amend to suit your needs.

```batch
set SIM=%USERPROFILE%\ModelSim
```