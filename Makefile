BSC ?= bsc

BLUECSR_DIR ?= dep/bluecsr
BLUEFABRIC_DIR ?= $(BLUECSR_DIR)/dep/bluefabric
BLUEAXI_DIR ?= $(BLUEFABRIC_DIR)/dep/blueaxi

GPIO_WIDTH ?= 8
ADDR_WIDTH ?= 8

CONFIG_TAG := gpio$(GPIO_WIDTH)-addr$(ADDR_WIDTH)
BUILD_DIR := build/$(CONFIG_TAG)
SIM_DIR := sim/$(CONFIG_TAG)
VERILOG_DIR := verilog/$(CONFIG_TAG)
DOC_BUILD_DIR := build/docs
DOC_SIM_DIR := sim/docs
DOC_DIR := docs
DOC_FILE := $(DOC_DIR)/register-map.md

TEST_TOP := mkTestGPIO
DOC_TOP := mkGPIOCSRMarkdown
APB_TOP := mkBlueGPIOAPB
AXI4LITE_TOP := mkBlueGPIOAXI4Lite
EXE := $(BUILD_DIR)/$(TEST_TOP)
DOC_EXE := $(DOC_BUILD_DIR)/$(DOC_TOP)

BLUEFABRIC_BSV_PATH := $(BLUEFABRIC_DIR)/src:$(BLUEFABRIC_DIR)/src/common
BLUEFABRIC_BSV_PATH := $(BLUEFABRIC_BSV_PATH):$(BLUEFABRIC_DIR)/src/apb
BLUEFABRIC_BSV_PATH := $(BLUEFABRIC_BSV_PATH):$(BLUEFABRIC_DIR)/src/axi
BLUEFABRIC_BSV_PATH := $(BLUEFABRIC_BSV_PATH):$(BLUEFABRIC_DIR)/src/axis
BLUEFABRIC_BSV_PATH := $(BLUEFABRIC_BSV_PATH):$(BLUEFABRIC_DIR)/src/ahb
BLUEFABRIC_BSV_PATH := $(BLUEFABRIC_BSV_PATH):$(BLUEFABRIC_DIR)/src/soc
BSV_PATH := src:test:$(BLUECSR_DIR)/src:$(BLUEFABRIC_BSV_PATH):$(BLUEAXI_DIR)/src:+

CONFIG_FLAGS := -D "BLUEGPIO_WIDTH=$(GPIO_WIDTH)"
CONFIG_FLAGS += -D "BLUEGPIO_ADDR_WIDTH=$(ADDR_WIDTH)"

SOURCES := $(wildcard src/*.bsv) $(wildcard src/*.bsvh) $(wildcard test/*.bsv)
BLUECSR_SOURCES := $(wildcard $(BLUECSR_DIR)/src/*.bsv)
BLUEFABRIC_SOURCES := $(wildcard $(BLUEFABRIC_DIR)/src/*.bsv)
BLUEFABRIC_SOURCES += $(wildcard $(BLUEFABRIC_DIR)/src/*/*.bsv)
BLUEAXI_SOURCES := $(wildcard $(BLUEAXI_DIR)/src/*.bsv)
DEPENDENCY_SOURCES := $(BLUECSR_SOURCES) $(BLUEFABRIC_SOURCES) $(BLUEAXI_SOURCES)

.PHONY: all check deps docs sim verilog apb axi4lite clean

all: check

deps:
	git submodule update --init --recursive

$(BUILD_DIR)/$(TEST_TOP).ba: $(SOURCES) $(DEPENDENCY_SOURCES) | deps
	@mkdir -p $(BUILD_DIR)
	$(BSC) -p $(BSV_PATH) -bdir $(BUILD_DIR) -sim -u -g $(TEST_TOP) test/TestGPIO.bsv

$(EXE): $(BUILD_DIR)/$(TEST_TOP).ba
	@mkdir -p $(SIM_DIR)
	$(BSC) -p $(BSV_PATH) -bdir $(BUILD_DIR) -simdir $(SIM_DIR) -sim -e $(TEST_TOP) -o $@

sim: $(EXE)
	./$(EXE)

$(VERILOG_DIR)/apb/$(APB_TOP).v: $(SOURCES) $(DEPENDENCY_SOURCES) | deps
	@mkdir -p $(BUILD_DIR)/apb $(VERILOG_DIR)/apb
	$(BSC) -p $(BSV_PATH) $(CONFIG_FLAGS) -bdir $(BUILD_DIR)/apb \
		-vdir $(VERILOG_DIR)/apb -verilog -u -g $(APB_TOP) src/BlueGPIOAPB.bsv

$(VERILOG_DIR)/axi4lite/$(AXI4LITE_TOP).v: $(SOURCES) $(DEPENDENCY_SOURCES) | deps
	@mkdir -p $(BUILD_DIR)/axi4lite $(VERILOG_DIR)/axi4lite
	$(BSC) -p $(BSV_PATH) $(CONFIG_FLAGS) -bdir $(BUILD_DIR)/axi4lite \
		-vdir $(VERILOG_DIR)/axi4lite -verilog -u -g $(AXI4LITE_TOP) src/BlueGPIOAXI4Lite.bsv

apb: $(VERILOG_DIR)/apb/$(APB_TOP).v

axi4lite: $(VERILOG_DIR)/axi4lite/$(AXI4LITE_TOP).v

verilog: apb axi4lite

$(DOC_EXE): $(SOURCES) $(DEPENDENCY_SOURCES) | deps
	@mkdir -p $(DOC_BUILD_DIR) $(DOC_SIM_DIR)
	$(BSC) -p $(BSV_PATH) -bdir $(DOC_BUILD_DIR) -sim -suppress-warnings G0024 \
		-u -g $(DOC_TOP) test/DocGPIO.bsv
	$(BSC) -p $(BSV_PATH) -bdir $(DOC_BUILD_DIR) -simdir $(DOC_SIM_DIR) \
		-sim -e $(DOC_TOP) -o $(DOC_EXE)

$(DOC_FILE): $(DOC_EXE)
	@mkdir -p $(DOC_DIR)
	./$(DOC_EXE)

docs: $(DOC_FILE)

check: sim verilog

clean:
	rm -rf build sim verilog
