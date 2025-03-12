# Network switch
A network switch for the Stratix IV FPGA implemented in Verilog.

## Compile
To compile the source files you need to install Quartus.
This repository provides a reproducable Quartus installation with the Nix package manager.
If you have Nix installed you can run:
```shell
nix develop .#quartus
```
This will provide a development environment for this project including a Quartus installation.
The first time you run this command it will take a while since the installation files for Quartus are very large.
If you do not want the quartus installation create the default shell:
```shell
nix develop
```
This will provide an environment with simulation and test tools.
j
You can run a specific testbench by setting the ```TEST_MODULE``` from the command line:
```shell
make TEST_MODULE=async_fifo_tb test
```

With Quartus installed you can run:
```shell
make compile
```
This will compile the code with Quartus.
