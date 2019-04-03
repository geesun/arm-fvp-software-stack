# Download and build Arm software stack
## Preparation
### Toolchain
#### The GNU Toolchain for the Cortex-A Family
AArch64 GNU/Linux target (aarch64-linux-gnu)

https://developer.arm.com/tools-and-software/open-source-software/developer-tools/gnu-toolchain/gnu-a/downloads
#### The GNU Embedded Toolchain for Arm
https://developer.arm.com/tools-and-software/open-source-software/developer-tools/gnu-toolchain/gnu-rm/downloads

### Fast Models
https://developer.arm.com/tools-and-software/simulation-models/fixed-virtual-platforms

## Armv8-A Foundation Platform

```
   repo init -u https://github.com/geesun/manifests.git
   repo sync 
   export CROSS_COMPILE=$(TOOL_CHAIN_PATH)/aarch64-linux-gnu-
   make 
   export MODEL=/usr/local/DS-5_v5.29.1/sw/models/bin/Foundation_Platform
   make run
   
```
## CoreLink SGM-775 (Cortex-A75+Cortex-A55) System Guidance for Mobile

```
   repo init -u https://github.com/geesun/manifests.git -m sgm775.xml
   repo sync
   export CROSS_COMPILE=$(TOOL_CHAIN_PATH)/aarch64-linux-gnu-
   export CROSS_COMPILE_M=$(TOOL_CHAIN_PATH)/arm-none-eabi-
   make 
   export MODEL=FVP_CSS_SGM-775/models/Linux64_GCC-4.8/FVP_CSS_SGM-775 
   make run
```

## CoreLink SGI-575 System Guidance for Infrastructure

```
   repo init -u https://github.com/geesun/manifests.git -m sgi575.xml
   repo sync
   export CROSS_COMPILE=$(TOOL_CHAIN_PATH)/aarch64-linux-gnu-
   export CROSS_COMPILE_M=$(TOOL_CHAIN_PATH)/arm-none-eabi-
   make 
   export MODEL=FVP_CSS_SGI-575/models/Linux64_GCC-4.8/FVP_CSS_SGI-575
   export MODEL_CONFIG=FVP_CSS_SGI-575/models/Linux64_GCC-4.8/SGI-575_cmn600.yml
   make run
```
