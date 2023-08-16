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

module EF_PSRAM_CTRL_ahb_tb;
    wire[3:0] dio;
    reg            HCLK = 0;
    reg            HRESETn = 0;
    reg            HSEL = 1;
    reg [31:0]     HADDR;
    reg [31:0]     HWDATA;
    reg [1:0]      HTRANS = 0;
    reg            HWRITE = 0;
    reg [2:0]      HSIZE;
    wire           HREADY;
    wire           HREADYOUT;
    wire [31:0]    HRDATA;
    
    wire            sck;
    wire            ce_n;
    wire [3:0]      din;
    wire [3:0]      dout;
    wire [3:0]      douten;    

    `include "AHB_tasks.vh"

    EF_PSRAM_CTRL_ahbl psram_ctrl(
        // AHB-Lite Slave Interface
        .HCLK(HCLK),
        .HRESETn(HRESETn),
        .HSEL(HSEL),
        .HADDR(HADDR),
        .HWDATA(HWDATA),
        .HTRANS(HTRANS),
        .HSIZE(HSIZE),
        .HWRITE(HWRITE),
        .HREADY(HREADY),
        .HREADYOUT(HREADYOUT),
        .HRDATA(HRDATA),
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
        $dumpfile("EF_PSRAM_CTRL_ahb_tb.vcd");
        $dumpvars;
        #999;
        @(posedge HCLK)
            HRESETn <= 1;
        #1000_000 $finish;
    end

    always #10 HCLK = ~HCLK;
    
    reg [31:0] data;
    initial begin
        @(posedge HRESETn);
        #999;
        @(posedge HCLK);
        AHB_WRITE_WORD(0, 32'hABCD_1234);
        #1;
        $display("TB: Write word to 0: 0x%x", 32'hABCD_1234);
        AHB_READ_WORD(0, data);
        #1;
        $display("TB: Read word from 0: 0x%x", data);
        AHB_READ_BYTE(2,data);
        #1;
        $display("TB: Read byte from 2: 0x%x", data);

        AHB_WRITE_WORD(100, 32'h88776655);
        #1;
        $display("TB: Write word to 100: 0x%x", 32'h88776655);
        
        AHB_READ_WORD(100, data);
        #1;
        $display("TB: Read word from 100: 0x%x", data);
        
        AHB_READ_HALF(100, data);
        #1;
        $display("TB: Read half-word from 100: 0x%x", data);
        
        AHB_READ_HALF(102, data);
        #1;
        $display("TB: Read half-word from 102: 0x%x", data);
        
        AHB_READ_BYTE(103, data);
        #1;
        $display("TB: Read byte from 103: 0x%x", data);

        AHB_WRITE_BYTE(200, 8'h21);
        AHB_WRITE_BYTE(201, 8'h32);
        AHB_WRITE_BYTE(202, 8'h43);
        AHB_WRITE_BYTE(203, 8'h54);
        #1;
        $display("TB: Write 4 bytes to 200: 0x%x", 32'h54433221);
        AHB_READ_WORD(200, data);
        #1;
        $display("TB: Read word from 200: 0x%x", data);
        AHB_READ_HALF(200, data);
        #1;
        $display("TB: Read half word from 200: 0x%x", data);
        AHB_READ_HALF(202, data);
        #1;
        $display("TB: Read half word from 202: 0x%x", data);
        
        AHB_WRITE_HALF(300, 16'hBBAA);
        AHB_WRITE_HALF(302, 16'hDDCC);
        #1;
        $display("TB: Write 2 haf words to 300: 0x%x", 32'hDDCCBBAA);
        AHB_READ_WORD(300, data);
        #1;
        $display("TB: Read word from 300: 0x%x", data);
    end

    assign HREADY = HREADYOUT;


endmodule