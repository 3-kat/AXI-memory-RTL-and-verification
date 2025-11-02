`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 31.10.2025 19:32:25
// Design Name: 
// Module Name: axilite_s
// Project Name: 
// Target Devices: 
// Tool Versions: 
// Description: 
// 
// Dependencies: 
// 
// Revision:
// Revision 0.01 - File Created
// Additional Comments:
// 
//////////////////////////////////////////////////////////////////////////////////

module axilite_s(

    input  wire         s_axi_aclk,
    input  wire         s_axi_aresetn,
    input  wire         s_axi_awvalid,
    output reg          s_axi_awready,
    input  wire [31: 0] s_axi_awaddr,

    input  wire         s_axi_wvalid,
    output reg         s_axi_wready,
    input  wire [31: 0] s_axi_wdata,

    output reg         s_axi_bvalid,
    input  wire         s_axi_bready,
    output reg  [1: 0] s_axi_bresp,

    input wire         s_axi_arvalid,
    output reg         s_axi_arready,
    input wire [31: 0] s_axi_araddr,

    output reg         s_axi_rvalid,
    input wire         s_axi_rready,
    output reg [31: 0] s_axi_rdata,
    output reg  [1: 0] s_axi_rresp
    );

localparam idle            = 0, 
           send_waddr_ack  = 1,
           send_raddr_ack  = 2,
           send_wdata_ack  = 3,
           update_mem      = 4,
           send_wr_err     = 5,
           send_wr_resp    = 6,
           gen_data        = 7,
           send_rd_err     = 8,
           send_rdata      = 9;
           
           
reg [3:0] state      = idle;
reg [3:0] next_state = idle;
reg [1:0] count    = 0;
reg [31:0] waddr, raddr, wdata, rdata;

reg [31:0] mem [128];
                  
           
always@(posedge s_axi_aclk)
begin
if (s_axi_aresetn == 1'b0)
begin
            state <= idle;
            for(int i = 0; i < 128; i++)
            begin
            mem[i] <= 0;
            end
            s_axi_awready <= 0;
            s_axi_wready  <= 0;
            s_axi_bvalid  <= 0;
            s_axi_bresp   <= 0;
            s_axi_arready <= 0;
            s_axi_rvalid  <= 0;
            s_axi_rdata   <= 0;
            s_axi_rresp   <= 0;
            waddr         <= 0;
            raddr         <= 0;
            wdata         <= 0;
            rdata         <= 0;      
 end
 else 
 begin
        case(state)
        idle: 
        begin

            s_axi_awready <= 0;
            s_axi_wready  <= 0;
            s_axi_bvalid  <= 0;
            s_axi_bresp   <= 0;
            s_axi_arready <= 0;
            s_axi_rvalid  <= 0;
            s_axi_rdata   <= 0;
            s_axi_rresp   <= 0;
            waddr         <= 0;
            raddr         <= 0;
            wdata         <= 0;
            rdata         <= 0;
            count         <= 0;
            s_axi_rvalid  <= 1'b0;
            
            if (s_axi_awvalid == 1'b1)
                    begin
                    state         <= send_waddr_ack;
                    waddr         <= s_axi_awaddr;
                    s_axi_awready <= 1'b1;
                    end
            else if (s_axi_arvalid == 1'b1)
                    begin
                    state         <= send_raddr_ack;
                    raddr         <= s_axi_araddr;
                    s_axi_arready <= 1'b1;
                    end
            else
                    begin
                    state         <= idle;
                    end
            
        end
            
       send_waddr_ack : 
       begin
        s_axi_awready <= 1'b0;
        if(s_axi_wvalid)
                  begin
                  wdata        <= s_axi_wdata;
                  s_axi_wready <= 1'b1;
                  state        <= send_wdata_ack;
                  end
        else
                  begin
                  state        <= send_waddr_ack;
                  end
       end
       
       send_wdata_ack: 
       begin
          s_axi_wready <= 1'b0;
          if(waddr < 128)
                   begin
                   state      <= update_mem;
                   mem[waddr] <= wdata;
                   end 
          else
                 begin
                 state        <= send_wr_err;
                 s_axi_bresp <= 2'b11; //error response
                 s_axi_bvalid <= 1'b1; 
                 end
       end
       
       update_mem: 
       begin
       mem[waddr] <= wdata;
       state      <= send_wr_resp;
       end
       
       send_wr_resp: 
       begin
       s_axi_bresp  <= 2'b00;
       s_axi_bvalid <= 1'b1;
       if(s_axi_bready)
                 begin
                 state        <= idle;
                 end
       else 
                 begin
                 state        <= send_wr_resp;
                 end
       end
       
       send_wr_err: begin
       if(s_axi_bready)
                 begin
                 state   <= idle;
                 end
       else 
                 begin
                 state <= send_wr_err;
                 end
       end
       
       
       ////////////////read operation
        send_raddr_ack : 
        begin
        s_axi_arready = 1'b0;
        if(raddr < 128)
                state <= gen_data;
        else
                begin
                s_axi_rvalid <= 1'b1;
                state <= send_rd_err;
                s_axi_rdata  <= 0;
                s_axi_rresp  <= 2'b11;
                end
       end
    
    
        gen_data: begin
        if(count < 2)
                begin
                rdata <= mem[raddr];
                state <= gen_data;
                count <= count + 1;
                end       
        else
                begin
                s_axi_rvalid <= 1'b1;
                s_axi_rdata  <= rdata;
                s_axi_rresp  <= 2'b00;
                if(s_axi_rready)
                   state <= idle;
                else
                   state <=  gen_data;
                end
        end
        

        send_rd_err:
        begin
        if(s_axi_rready)
                begin
                state <= idle;
                end
        else
                begin
                state <= send_rd_err;
                end
        end
        

       default: state <= idle;
    endcase
end
end



endmodule

/////////////////////////////
interface axi_if;
  logic clk,resetn;
  logic awvalid, awready;
  logic arvalid, arready;
  logic wvalid, wready;
  logic bready, bvalid;
  logic rvalid, rready;
  logic [31:0] awaddr, araddr, wdata, rdata;
  logic [1:0] wresp,rresp;
  
endinterface
