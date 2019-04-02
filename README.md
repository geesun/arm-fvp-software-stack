#Download and build Arm software stack

#Arm Foundation platform

```
   repo init -u https://github.com/geesun/manifests.git
   repo sync 
   export CROSS_COMPILE=$(TOOL_CHAIN_PATH)/aarch64-linux-gnu-
   make 
   export MODEL=/usr/local/DS-5_v5.29.1/sw/models/bin/Foundation_Platform
   make run
   
```

#Arm SGI-575 platform

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
