# Download and build Arm software stack
## Preparation
#### Toolchains
###### The GNU Toolchain for the Cortex-A Family
AArch64 GNU/Linux target (aarch64-linux-gnu)

https://developer.arm.com/tools-and-software/open-source-software/developer-tools/gnu-toolchain/gnu-a/downloads
###### The GNU Embedded Toolchain for Arm
https://developer.arm.com/tools-and-software/open-source-software/developer-tools/gnu-toolchain/gnu-rm/downloads

#### Fast Models
https://developer.arm.com/tools-and-software/simulation-models/fixed-virtual-platforms

## Armv8-A Foundation Platform

```
   repo init -u https://github.com/geesun/arm-fvp-software-stack.git -m foundation.xml
   repo sync 
   export CROSS_COMPILE=$(TOOL_CHAIN_PATH)/aarch64-linux-gnu-
   make 
   export MODEL=/usr/local/DS-5_v5.29.1/sw/models/bin/Foundation_Platform
   make run
   
```
## Armv8-A Base Platform 
```
   repo init -u https://github.com/geesun/arm-fvp-software-stack.git -m base.xml
   repo sync 
   export CROSS_COMPILE=$(TOOL_CHAIN_PATH)/aarch64-linux-gnu-
   make 
   export MODEL=Base_RevC_AEMv8A_pkg/models/Linux64_GCC-4.9/FVP_Base_RevC-2xAEMv8A
   make run
```   

## CoreLink SGM-775 (Cortex-A75+Cortex-A55) System Guidance for Mobile

```
   repo init -u https://github.com/geesun/arm-fvp-software-stack.git -m sgm775.xml
   repo sync
   export CROSS_COMPILE=$(TOOL_CHAIN_PATH)/aarch64-linux-gnu-
   export CROSS_COMPILE_M=$(TOOL_CHAIN_PATH)/arm-none-eabi-
   make 
   export MODEL=FVP_CSS_SGM-775/models/Linux64_GCC-4.8/FVP_CSS_SGM-775 
   make run
```

## CoreLink SGI-575 System Guidance for Infrastructure

```
   repo init -u https://github.com/geesun/arm-fvp-software-stack.git -m sgi575.xml
   repo sync
   export CROSS_COMPILE=$(TOOL_CHAIN_PATH)/aarch64-linux-gnu-
   export CROSS_COMPILE_M=$(TOOL_CHAIN_PATH)/arm-none-eabi-
   make 
   export MODEL=FVP_CSS_SGI-575/models/Linux64_GCC-4.8/FVP_CSS_SGI-575
   export MODEL_CONFIG=FVP_CSS_SGI-575/models/Linux64_GCC-4.8/SGI-575_cmn600.yml
   make run
```
## CoreLink RD N1 EDGE 

```
   repo init -u https://github.com/geesun/arm-fvp-software-stack.git -m rdn1edge.xml
   repo sync --fetch-submodules
   export CROSS_COMPILE=$(TOOL_CHAIN_PATH)/aarch64-linux-gnu-
   export CROSS_COMPILE_M=$(TOOL_CHAIN_PATH)/arm-none-eabi-
   make 
   export MODEL=model/FVP_RD_N1_edge/models/Linux64_GCC-4.9/FVP_RD_N1_edge
   export MODEL_CONFIG=model/FVP_RD_N1_edge/models/Linux64_GCC-4.9/RD_N1_E1_cmn600.yml
   make run
```
