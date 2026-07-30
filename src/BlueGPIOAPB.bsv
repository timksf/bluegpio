// SPDX-License-Identifier: MIT

package BlueGPIOAPB;

import BlueCSRAPBAdapter :: *;
import BlueCSRCore :: *;
import BlueFabric :: *;
import BlueGPIO :: *;

`include "BlueGPIOConfig.bsvh"

interface BlueGPIOAPB_ifc#(numeric type n, numeric type aw);
    (* prefix = "" *)
        interface GPIOPins_ifc#(n) pins;
    (* prefix = "" *)
        interface GPIOInterrupts_ifc#(n) irq;

    (* prefix = "" *)
        interface ApbSlaveFabric_ifc#(aw, 32, 0) s_apb;
endinterface

module [Module] mkBlueGPIOAPBCore(BlueGPIOAPB_ifc#(n, aw))
    provisos(Add#(n, unused, 32));

    BlueGPIO_ifc#(n, aw) i_gpio <- mkBlueGPIO;
    BlueCSR_APB_ifc#(aw, 32, 0, n) i_apb <- mkBlueCSRAPBAdapter(i_gpio.csr, False);

    interface pins = i_gpio.pins;
    interface irq = i_gpio.irq;
    interface s_apb = i_apb.s_apb;
endmodule

(* synthesize, default_clock_osc = "CLK", default_reset = "RSTN" *)
module mkBlueGPIOAPB(BlueGPIOAPB_ifc#(`BLUEGPIO_WIDTH, `BLUEGPIO_ADDR_WIDTH));
    let i_gpio <- mkBlueGPIOAPBCore;
    return i_gpio;
endmodule

endpackage
