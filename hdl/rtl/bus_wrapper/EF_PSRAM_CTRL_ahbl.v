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

`timescale              1ns/1ps
`default_nettype        none

// Using EBH Command
module EF_PSRAM_CTRL_ahbl (
    // AHB-Lite Slave Interface
    input   wire            HCLK,
    input   wire            HRESETn,
    input   wire            HSEL,
    input   wire [31:0]     HADDR,
    input   wire [31:0]     HWDATA,
    input   wire [1:0]      HTRANS,
    input   wire [2:0]      HSIZE,
    input   wire            HWRITE,
    input   wire            HREADY,
    output  reg             HREADYOUT,
    output  wire [31:0]     HRDATA,

    // External Interface to Quad I/O
    output  wire            sck,
    output  wire            ce_n,
    input   wire [3:0]      din,
    output  wire [3:0]      dout,
    output  wire [3:0]      douten     
);

    localparam  ST_IDLE = 1'b0,
                ST_WAIT = 1'b1;

    wire        mr_sck; 
    wire        mr_ce_n; 
    wire [3:0]  mr_din; 
    wire [3:0]  mr_dout; 
    wire        mr_doe;
    
    wire        mw_sck; 
    wire        mw_ce_n; 
    wire [3:0]  mw_din; 
    wire [3:0]  mw_dout; 
    wire        mw_doe;
    
    // PSRAM Reader and Writer wires
    wire        mr_rd;
    wire        mr_done;
    wire        mw_wr;
    wire        mw_done;

    wire        doe;

    reg         state, nstate;

    //AHB-Lite Address Phase Regs
    reg         last_HSEL;
    reg [31:0]  last_HADDR;
    reg         last_HWRITE;
    reg [1:0]   last_HTRANS;
    reg [2:0]   last_HSIZE;

    wire [2:0]  size =  (last_HSIZE == 0) ? 1 :
                        (last_HSIZE == 1) ? 2 :
                        (last_HSIZE == 2) ? 4 : 4;

    wire        ahb_addr_phase  = HTRANS[1] & HSEL & HREADY;

    always@ (posedge HCLK) begin
        if(HREADY) begin
            last_HSEL       <= HSEL;
            last_HADDR      <= HADDR;
            last_HWRITE     <= HWRITE;
            last_HTRANS     <= HTRANS;
            last_HSIZE      <= HSIZE;
        end
    end

    always @ (posedge HCLK or negedge HRESETn)
        if(HRESETn == 0) 
            state <= ST_IDLE;
        else 
            state <= nstate;

    always @* begin
        case(state)
            ST_IDLE :   
                if(ahb_addr_phase) 
                    nstate = ST_WAIT;
                else
                    nstate = ST_IDLE;

            ST_WAIT :   
                if((mw_done & last_HWRITE) | (mr_done & ~last_HWRITE))   
                    nstate = ST_IDLE;
                else
                    nstate = ST_WAIT; 
        endcase
    end

    // HREADYOUT Generation
    always @(posedge HCLK or negedge HRESETn)
        if(!HRESETn) 
            HREADYOUT <= 1'b1;
        else
            case (state)
                ST_IDLE :   
                    if(ahb_addr_phase) 
                        HREADYOUT <= 1'b0;
                    else 
                        HREADYOUT <= 1'b1;

                ST_WAIT :   
                    if((mw_done & last_HWRITE) | (mr_done & ~last_HWRITE))  
                        HREADYOUT <= 1'b1;
                    else 
                        HREADYOUT <= 1'b0;
            endcase

    assign mr_rd    = ( ahb_addr_phase & (state==ST_IDLE ) & ~HWRITE );
    assign mw_wr    = ( ahb_addr_phase & (state==ST_IDLE ) & HWRITE );

    PSRAM_READER MR (   
        .clk(HCLK), 
        .rst_n(HRESETn), 
        .addr({HADDR[23:0]}), 
        .rd(mr_rd), 
        .size(size),
        .done(mr_done), 
        .line(HRDATA),
        .sck(mr_sck), 
        .ce_n(mr_ce_n), 
        .din(mr_din), 
        .dout(mr_dout), 
        .douten(mr_doe) 
    );

    PSRAM_WRITER MW (   
        .clk(HCLK), 
        .rst_n(HRESETn), 
        .addr({HADDR[23:0]}), 
        .wr(mw_wr), 
        .size(size),
        .done(mw_done), 
        .line(HWDATA),
        .sck(mw_sck), 
        .ce_n(mw_ce_n), 
        .din(mw_din), 
        .dout(mw_dout), 
        .douten(mw_doe) 
    );

    assign sck  = last_HWRITE ? mw_sck  : mr_sck;
    assign ce_n = last_HWRITE ? mw_ce_n : mr_ce_n;
    assign dout = last_HWRITE ? mw_dout : mr_dout;
    assign douten  = last_HWRITE ? {4{mw_doe}}  : {4{mr_doe}};
    
    assign mw_din = din;
    assign mr_din = din;

endmodule


