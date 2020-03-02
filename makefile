SRC_DIR = Sources
EMBEDDED_LIB_DIR = embedded
SYSTEM_DIR = system


ifeq ($(CONFIG), DEBUG)
OBJ_DIR = bin/obj/debug
OUTPUT_DIR = bin/debug
OFLAGS += -ggdb3
OFLAGS += -O0
OFLAGS += -fno-omit-frame-pointer
else
OBJ_DIR = bin/obj/release
OUTPUT_DIR = bin/release
#OFLAGS += -Os
OFLAGS += -O3
OFLAGS += -fomit-frame-pointer
endif

TARGET = $(OUTPUT_DIR)/main


#region TOOLCHAIN
TOOLCHAIN_DIR = ../../programs/arm-gcc/bin
TOOLCHAIN = $(TOOLCHAIN_DIR)/arm-none-eabi-
CC = $(TOOLCHAIN)gcc
CXX = $(TOOLCHAIN)g++
LD = $(TOOLCHAIN)gcc
CP = $(TOOLCHAIN)objcopy
SIZE = $(TOOLCHAIN)size
OBJDUMP = $(TOOLCHAIN)objdump
NM = $(TOOLCHAIN)nm
#endregion

#region PLATFORM
LDSCRIPT = -T$(SYSTEM_DIR)/STM32L475VGTX_FLASH.ld

MCU = STM32L475xx

MCUFLAGS += -mcpu=cortex-m4
MCUFLAGS += -mthumb
MCUFLAGS += -mfpu=fpv4-sp-d16 -mfloat-abi=hard
#endregion

#region SOURCES
INC += $(SYSTEM_DIR)/inc
INC += $(SRC_DIR)/inc
INC += $(SYSTEM_DIR)/CMSIS/inc
INC += $(SYSTEM_DIR)/HAL/inc
#INC += $(EMBEDDED_LIB_DIR)/*/inc
INC := $(addprefix -I, $(wildcard $(INC)))

#SRC_DIRS += $(SYSTEM_DIR)
#SRC_DIRS += $(SYSTEM_DIR)/src
#SRC_DIRS += $(SRC_DIR)
SRC_DIRS += $(SYSTEM_DIR)/CMSIS/src
SRC_DIRS += $(SYSTEM_DIR)/HAL/src
SRC_DIRS += $(SRC_DIR)/src
#SRC_DIRS += $(EMBEDDED_LIB_DIR)/*/src/*

#ASM_FILES := $(foreach dir,$(SRC_DIRS),$(wildcard $(dir)/*.s))
ASM_FILES := $(SYSTEM_DIR)/startup_stm32l475vgtx.s
C_FILES := $(foreach dir,$(SRC_DIRS),$(wildcard $(dir)/*.c))
CPP_FILES := $(foreach dir,$(SRC_DIRS),$(wildcard $(dir)/*.cpp))

OBJ_FILES := $(ASM_FILES:%.s=%.o)
OBJ_FILES += $(C_FILES:%.c=%.o)
OBJ_FILES += $(CPP_FILES:%.cpp=%.o)
OBJ_FILES := $(addprefix $(OBJ_DIR)/, $(OBJ_FILES))

#endregion

#region FLAGS
LDFLAGS += $(MCUFLAGS)
LDFLAGS += $(LDSCRIPT)
LDFLAGS += -Wl,--gc-sections
LDFLAGS += -Wl,-Map=$(TARGET).map -Wl,--cref		#Настройки создания map файла
LDFLAGS += --specs=nano.specs
LDFLAGS += --specs=nosys.specs
LDFLAGS += -static
LDFLAGS += -Wl,--start-group -lc -lm -lstdc++ -lsupc++ -Wl,--end-group
#LDFLAGS += -flto

DEFS += -D$(MCU)
DEFS += -DUSE_HAL_DRIVER
DEFS += -D__forceinline="__attribute__((always_inline))"

CFLAGS += $(MCUFLAGS)
CFLAGS += $(OFLAGS)
CFLAGS += $(DEFS)
CFLAGS += $(INC)
CFLAGS += -Wall -Wextra #-Werror
CFLAGS += -ffunction-sections -fdata-sections
CFLAGS += --specs=nano.specs
#CFLAGS += -flto


ASMFLAGS += -x assembler-with-cpp

#CCFLAGS += -std=c11
CCFLAGS += -std=gnu11
CCFLAGS += -fstack-usage

CXXFLAGS += -std=c++17
#CXXFLAGS += -std=gnu++14
CXXFLAGS += -fno-rtti
CXXFLAGS += -fno-exceptions
CXXFLAGS += -fno-threadsafe-statics -fno-use-cxa-atexit
CXXFLAGS += -fstack-usage
#endregion

all: directories clean clean_target hex bin lss sym size
	@echo "*** DONE ***"

size:
	@$(SIZE) -A -x $(TARGET).elf > $(TARGET).size
	@$(SIZE) -B  $(TARGET).elf

directories:
	@echo "*** CREATE DIRECTORIES ***"
	@mkdir -p $(OUTPUT_DIR)
	@mkdir -p $(sort $(dir $(OBJ_FILES)))

hex: elf
	@echo "*** MAKE HEX ***"
	@$(CP) -Oihex $(TARGET).elf $(TARGET).hex

bin: elf
	@echo "*** MAKE BIN ***"
	@$(CP) $(TARGET).elf $(TARGET).bin -O binary

lss: elf
	@$(OBJDUMP) -h -S -C -r $(TARGET).elf > $(TARGET).lss

sym: elf
	@$(NM) -n $(TARGET).elf > $(TARGET).sym

elf: $(OBJ_FILES)
	@echo "*** LINK ***"
	@$(LD) $(LDFLAGS) $(OBJ_FILES) -o $(TARGET).elf

$(OBJ_DIR)/%.o: %.cpp
	@echo "*** COMPILE" $< "***"
	@$(CXX) $(CFLAGS) $(CXXFLAGS) -c $< -o $@

$(OBJ_DIR)/%.o: %.c
	@echo "*** COMPILE" $< "***"
	@$(CC) $(CFLAGS) $(CCFLAGS) -c $< -o $@

$(OBJ_DIR)/%.o: %.s
	@echo "*** COMPILE" $< "***"
	@$(CC) $(CFLAGS) $(ASMFLAGS) -c $< -o $@

clean:
	@echo "*** CLEAN ***"
	@rm -f $(OBJ_FILES)

clean_target:
	@echo "*** CLEAN TARGET ***"
	@rm -f $(TARGET).elf $(TARGET).hex $(TARGET).bin $(TARGET).map $(TARGET).lss $(TARGET).sym $(TARGET).size

view:
	@echo $(INC)
	@echo $(SRC_DIRS)
	@echo $(ASM_FILES)
	@echo $(C_FILES)
	@echo $(CPP_FILES)
	@echo $(OBJ_FILES)
