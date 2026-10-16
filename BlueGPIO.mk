# BSVTools library integration for BlueGPIO.
ifndef BLUEGPIO_MK_INCLUDED
BLUEGPIO_MK_INCLUDED := 1

BLUEGPIO_ROOT := $(abspath $(dir $(lastword $(MAKEFILE_LIST))))
BLUEGPIO_SRC := $(BLUEGPIO_ROOT)/src

# Prefer the project's library, falling back to the bundled dependency.
BLUEGPIO_BLUECSR_MK := $(firstword $(wildcard $(CURDIR)/libraries/*/BlueCSR.mk) $(BLUEGPIO_ROOT)/dep/bluecsr/BlueCSR.mk)
include $(BLUEGPIO_BLUECSR_MK)

EXTRA_BSV_LIBS += $(BLUEGPIO_SRC)

$(info Adding BlueGPIO from $(BLUEGPIO_SRC))

endif
