// SPDX-License-Identifier: MIT

package BlueGPIOAXI4Lite;

import BlueAXI :: *;
import BlueCSRAXI4LiteAdapter :: *;
import BlueCSRCore :: *;
import BlueGPIO :: *;

`include "BlueGPIOConfig.bsvh"

interface BlueGPIOAXI4Lite_ifc#(numeric type n, numeric type aw);
    (* prefix = "" *)
        interface GPIOPins_ifc#(n) pins;
    (* prefix = "" *)
        interface GPIOInterrupts_ifc#(n) irq;

    (* prefix = "" *)
        interface AXI4_Lite_Slave_Rd_Fab#(aw, 32) s_axi_rd;
    (* prefix = "" *)
        interface AXI4_Lite_Slave_Wr_Fab#(aw, 32) s_axi_wr;
endinterface

module [Module] mkBlueGPIOAXI4LiteCore(BlueGPIOAXI4Lite_ifc#(n, aw))
    provisos(Add#(n, unused, 32));

    BlueGPIO_ifc#(n, aw) i_gpio <- mkBlueGPIO;
    BlueCSR_AXI4Lite_ifc#(aw, 32, n) i_axi <- mkBlueCSRAXI4LiteAdapter(i_gpio.csr, 1, 1);

    interface pins = i_gpio.pins;
    interface irq = i_gpio.irq;
    interface s_axi_rd = i_axi.s_rd;
    interface s_axi_wr = i_axi.s_wr;
endmodule

(* synthesize, default_clock_osc = "CLK", default_reset = "RSTN" *)
module mkBlueGPIOAXI4Lite(BlueGPIOAXI4Lite_ifc#(`BLUEGPIO_WIDTH, `BLUEGPIO_ADDR_WIDTH));
    let i_gpio <- mkBlueGPIOAXI4LiteCore;
    return i_gpio;
endmodule

endpackage
