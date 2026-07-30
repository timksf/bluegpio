// SPDX-License-Identifier: MIT

package TestGPIO;

import StmtFSM :: *;

import BlueCSRCore :: *;
import BlueCSRTb :: *;
import BlueGPIO :: *;

module mkTestGPIO(Empty);

    BlueGPIO_ifc#(8, 8) i_gpio <- mkBlueGPIO;

    Reg#(Bit#(8)) rg_input <- mkReg(0);

    rule r_drive_pins;
        i_gpio.pins.input_value(rg_input);
    endrule

    function Action expect_read(Bit#(32) expected, String label);
        action
            let response <- accept_read_response(i_gpio.csr);
            if(tpl_2(response) != CSR_OKAY || tpl_1(response) != expected) begin
                $display(
                    "%s: expected %08x/OKAY, got %08x/%0d",
                    label, expected, tpl_1(response), tpl_2(response)
                );
                $finish(1);
            end
        endaction
    endfunction

    function Action expect_unmapped(String label);
        action
            let response <- accept_read_response(i_gpio.csr);
            if(tpl_2(response) != CSR_DECERR) begin
                $display("%s: expected DECERR, got %0d", label, tpl_2(response));
                $finish(1);
            end
        endaction
    endfunction

    function Action check(Bool condition, String label);
        action
            if(!condition) begin
                $display("%s", label);
                $finish(1);
            end
        endaction
    endfunction

    Stmt test = seq
        issue_read(i_gpio.csr, 'h00, CSR_INSECURE);
        expect_read(0, "INPUT_VAL reset");

        issue_write(i_gpio.csr, 'h04, 32'h0F, 4'hF, CSR_INSECURE);
        expect_write_okay(i_gpio.csr);
        rg_input <= 8'h05;
        repeat(5) noAction;
        issue_read(i_gpio.csr, 'h00, CSR_INSECURE);
        expect_read(32'h05, "synchronized INPUT_VAL");

        issue_write(i_gpio.csr, 'h08, 32'h0F, 4'hF, CSR_INSECURE);
        expect_write_okay(i_gpio.csr);
        issue_write(i_gpio.csr, 'h0C, 32'h0A, 4'hF, CSR_INSECURE);
        expect_write_okay(i_gpio.csr);
        check(i_gpio.pins.output_enable == 8'h0F, "OUTPUT_EN pin value mismatch");
        check(i_gpio.pins.output_value == 8'h0A, "OUTPUT_VAL pin value mismatch");

        issue_write(i_gpio.csr, 'h40, 32'h03, 4'hF, CSR_INSECURE);
        expect_write_okay(i_gpio.csr);
        check(i_gpio.pins.output_value == 8'h09, "OUT_XOR pin value mismatch");

        issue_read(i_gpio.csr, 'h38, CSR_INSECURE);
        expect_unmapped("reserved offset 0x38");
        issue_read(i_gpio.csr, 'h3C, CSR_INSECURE);
        expect_unmapped("reserved offset 0x3c");

        rg_input <= 0;
        repeat(5) noAction;
        issue_write(i_gpio.csr, 'h1C, 32'hFF, 4'hF, CSR_INSECURE);
        expect_write_okay(i_gpio.csr);
        issue_write(i_gpio.csr, 'h18, 1, 4'hF, CSR_INSECURE);
        expect_write_okay(i_gpio.csr);
        rg_input <= 1;
        repeat(5) noAction;
        check(i_gpio.irq.interrupts == 8'h01, "GPIO 0 rising-edge interrupt did not assert");
        issue_read(i_gpio.csr, 'h1C, CSR_INSECURE);
        expect_read(1, "RISE_IP");
        issue_write(i_gpio.csr, 'h1C, 1, 4'hF, CSR_INSECURE);
        expect_write_okay(i_gpio.csr);
        noAction;
        check(i_gpio.irq.interrupts == 0, "GPIO 0 rising-edge interrupt did not clear");

        issue_write(i_gpio.csr, 'h18, 2, 4'hF, CSR_INSECURE);
        expect_write_okay(i_gpio.csr);
        rg_input <= 3;
        repeat(5) noAction;
        check(i_gpio.irq.interrupts == 8'h02, "GPIO interrupts were not vectored by pin");

        issue_write(i_gpio.csr, 'h20, 2, 4'hF, CSR_INSECURE);
        expect_write_okay(i_gpio.csr);
        rg_input <= 1;
        repeat(5) noAction;
        issue_write(i_gpio.csr, 'h1C, 2, 4'hF, CSR_INSECURE);
        expect_write_okay(i_gpio.csr);
        noAction;
        check(i_gpio.irq.interrupts == 8'h02, "GPIO 1 trigger sources were not merged");
        issue_write(i_gpio.csr, 'h24, 2, 4'hF, CSR_INSECURE);
        expect_write_okay(i_gpio.csr);
        noAction;
        check(i_gpio.irq.interrupts == 0, "GPIO 1 merged interrupt did not clear");

        $display("BlueGPIO test passed");
    endseq;

    mkAutoFSM(test);

endmodule

endpackage
