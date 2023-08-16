/*
	Copyright 2020 Efabless Corp.

	Author: Mohamed Shalan (mshalan@efabless.com)
	
	Licensed under the Apache License, Version 2.0 (the "License"); 
	you may not use this file except in compliance with the License. 
	You may obtain a copy of the License at:
	http://www.apache.org/licenses/LICENSE-2.0
	Unless required by applicable law or agreed to in writing, software 
	distributed under the License is distributed on an "AS IS" BASIS, 
	WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied. 
	See the License for the specific language governing permissions and 
	limitations under the License.
*/

module EF_PSRAM_CTRL_wb_tb;
   
    reg         clk_i = 0;
    reg         rst_i = 1;
    reg  [31:0] adr_i;
    reg  [31:0] dat_i;
    wire [31:0] dat_o;
    reg  [3:0]  sel_i;
    reg         cyc_i;
    reg         stb_i;
    wire        ack_o;
    reg         we_i;
    
    wire        sck;
    wire        ce_n;
    wire [3:0]  din;
    wire [3:0]  dout;
    wire [3:0]  douten;    
    wire [3:0]  dio;

    `include "wb_tasks.vh"

    EF_PSRAM_CTRL_wb psram_ctrl(
        .clk_i(clk_i),
        .rst_i(rst_i),
        .adr_i(adr_i),
        .dat_i(dat_i),
        .dat_o(dat_o),
        .sel_i(sel_i),
        .cyc_i(cyc_i),
        .stb_i(stb_i),
        .ack_o(ack_o),
        .we_i(we_i),     
        .sck(sck),
        .ce_n(ce_n),
        .din(din),
        .dout(dout),
        .douten(douten)     
    );

    assign dio[0] = douten[0] ? dout[0] : 1'bz;
    assign dio[1] = douten[0] ? dout[1] : 1'bz;
    assign dio[2] = douten[0] ? dout[2] : 1'bz;
    assign dio[3] = douten[0] ? dout[3] : 1'bz;

    assign din = dio;
    
    EF_VIP_PSRAM psram (
        .sck(sck),
        .dio(dio),
        .ce_n(ce_n)
    );

    initial begin
        $dumpfile("EF_PSRAM_CTRL_wb_tb.vcd");
        $dumpvars;
        #999;
        @(posedge clk_i)
            rst_i <= 0;
        #1000_000 $finish;
    end

    always #10 clk_i = ~clk_i;
    
    reg [31:0] data;
    initial begin
        @(negedge rst_i);
        #999;
        @(posedge clk_i);
        WB_M_WR_W(0, 32'hABCD_1234);
        #1;
        $display("TB: Write a word to 0: 0x%x", 32'hABCD_1234);
        WB_M_RD_W(0, data);
        #1;
        $display("TB: Read a word from 0: 0x%x", data);
        
    end

endmodule