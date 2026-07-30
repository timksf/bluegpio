// SPDX-License-Identifier: MIT

package DocGPIO;

import BlueCSRCore :: *;
import BlueCSRExport :: *;
import BlueGPIO :: *;

module [BlueCSRCtx_t#(8, 32)] gpio_csrs_8(GPIOPins_ifc#(8));
    let pins <- gpio_csrs;
    return pins;
endmodule

module [Module] mkGPIOCSRMarkdown(Empty);
    RegMapDoc_t#(32) doc <- doc_blue_csr_markdown(gpio_csrs_8);
    messageM(doc.reg_defs);
endmodule

endpackage
