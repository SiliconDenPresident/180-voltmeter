# ------------------------------
# Directory Structure, dont change
OUTPUT_PATH = outputs
SRC_PATH = src/
# ------------------------------
# Source file and Top-level module, change this
V_FILE := $(shell find $(SRC_PATH) -type f -name "*.v")
SV_FILE = $(SRC_PATH)testbench.sv

TESTBENCH_TOP_LEVEL = testbench

all: run

run:
	@mkdir -p $(OUTPUT_PATH)
	vcs -R -sverilog -timescale=1ns/1ps -hsopt\
		+vcs+dumpvars+outputs/run.vcd\
		-top $(TESTBENCH_TOP_LEVEL)\
		$(V_FILE)\
		$(SV_FILE)\

dcshell:
	@$(MAKE) -C dc synth

wave:
	simvision $(OUTPUT_PATH)/run.vcd
#	vcd2vpd $(OUTPUT_PATH)/run.vcd $(OUTPUT_PATH)/run.vpd
#	dve -full64 -vpd $(OUTPUT_PATH)/run.vpd

clean:
	rm -rf $(OUTPUT_PATH)
	rm -rf DVEfiles
	rm -rf csrc
	rm -rf simv
	rm -rf simv.daidir
	rm -rf ucli.key