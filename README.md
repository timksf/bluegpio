# BlueGPIO

BlueGPIO is a small, parameterized GPIO controller with a native BlueCSR
register interface. Its register layout follows the SiFive FE310 GPIO map.

The GPIO input is masked by `INPUT_EN` and passes through a three-register
synchronizer. Interrupt pending bits are sticky and are cleared by writing one.
Each GPIO has one interrupt output. Its enabled rising-edge, falling-edge,
high-level, and low-level pending conditions are merged onto that pin's
interrupt line, matching how the FE310 presents individual GPIO sources to its
PLIC.
Peripheral-function routing is intentionally left to an external pinmux or I/O
matrix, so offsets `0x38` and `0x3c` are unmapped.

| Offset | Register | Access | Description |
| ---: | --- | :---: | --- |
| `0x00` | `INPUT_VAL` | RO | Synchronized, enabled GPIO inputs |
| `0x04` | `INPUT_EN` | RW | Input enable mask |
| `0x08` | `OUTPUT_EN` | RW | Output enable mask |
| `0x0c` | `OUTPUT_VAL` | RW | Software output value |
| `0x18` | `RISE_IE` | RW | Rising-edge interrupt enable |
| `0x1c` | `RISE_IP` | W1C | Rising-edge interrupt pending |
| `0x20` | `FALL_IE` | RW | Falling-edge interrupt enable |
| `0x24` | `FALL_IP` | W1C | Falling-edge interrupt pending |
| `0x28` | `HIGH_IE` | RW | High-level interrupt enable |
| `0x2c` | `HIGH_IP` | W1C | High-level interrupt pending |
| `0x30` | `LOW_IE` | RW | Low-level interrupt enable |
| `0x34` | `LOW_IP` | W1C | Low-level interrupt pending |
| `0x40` | `OUT_XOR` | RW | Invert final output value |

`mkBlueGPIO` is parameterized by GPIO count and CSR address width. It has a
`pins` subinterface for `I`, `O`, and `OE`, an `irq` subinterface containing
the `n`-bit interrupt vector, and a native `BlueCSR_ifc#(aw, 32, n)` slave
subinterface.
`mkBlueCSRAPBAdapter` or `mkBlueCSRAXI4LiteAdapter` can wrap it when a standard
bus interface is needed.

## Verilog generation

The synthesizable wrappers are configured at build time. `GPIO_WIDTH` selects
the number of GPIO and interrupt lines from 1 through 32. `ADDR_WIDTH` selects
the local CSR bus address width and defaults to 8.

The two wrappers are:

| Target | Generated module | Register interface |
| --- | --- | --- |
| `apb` | `mkBlueGPIOAPB` | APB4 slave |
| `axi4lite` | `mkBlueGPIOAXI4Lite` | AXI4-Lite slave |

The `verilog` target generates both wrappers.

For example, generate twelve-pin APB and AXI4-Lite variants with:

```sh
make apb axi4lite GPIO_WIDTH=12
```

The results are written below
`verilog/gpio12-addr8/{apb,axi4lite}`. Configuration-specific build
directories prevent stale Bluespec objects from being reused with another
width.

All wrappers have these GPIO and clock/reset ports:

| Port | Direction | Width | Description |
| --- | :---: | ---: | --- |
| `CLK` | input | 1 | Clock |
| `RSTN` | input | 1 | Active-low reset |
| `I` | input | `GPIO_WIDTH` | GPIO inputs, synchronized internally |
| `O` | output | `GPIO_WIDTH` | GPIO output values |
| `OE` | output | `GPIO_WIDTH` | Active-high output enables |
| `IRQ` | output | `GPIO_WIDTH` | Per-pin interrupt requests |

The APB and AXI4-Lite wrappers expose flat, conventionally named bus signals.
The APB wrapper omits zero-width APB user signals.

## Development

Clone with recursive submodules, or initialize an existing clone with:

```sh
make deps
```

This initializes BlueCSR and its nested BlueFabric and BlueAXI dependencies.
The build targets also run this command automatically.

Generate the detailed field-level Markdown table directly from the Bluespec CSR
definition with:

```sh
make docs
```

The generated file is `docs/register-map.md`.

Run the simulation test with:

```sh
make sim
```
