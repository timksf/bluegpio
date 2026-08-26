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
    Reg#(Bool) rg_done <- mkReg(False);

    rule r_write_markdown if(!rg_done);
        rg_done <= True;

        File fh <- $fopen("docs/register-map.md", "w");
        if(fh == InvalidFile) begin
            $display("Could not open docs/register-map.md");
            $finish(1);
        end
        else begin
            $fwrite(fh, "%s\n", doc.reg_defs);
            $fflush(fh);
            $fclose(fh);
            $display("Generated docs/register-map.md");
            $finish(0);
        end
    endrule
endmodule

endpackage
