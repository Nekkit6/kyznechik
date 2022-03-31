`timescale 1ns / 1ps


module APB(
    input           PCLK,
                    PRESETn,
            [31:0]  PADDR,
                    PPROT,
                    PSEL,
                    PENABLE,
                    PWRITE,
            [31:0]  PWDATA,
            [3:0]   PSTRB,
                    busy,
                    valid,
            [127:0] data_o,
                    
    output    reg        PREADY,
              reg[31:0]  PRDATA,
              reg        PSLVERR
    );
    
    kuznechik_cipher DUT(
        .clk_i      (PCLK),
        .resetn_i   (RESETn),
        .data_i     (data_i),
        .request_i  (request),
        .ack_i      (ack),
        .data_o     (data_o),
        .valid_o    (valid),
        .busy_o     (busy)
    );
    
    integer i;
    
    //wire         busy; 
    //reg [7:0]   REQ_ASK;
    //reg         valid;
    //reg [7:0]   BUSY;
    //reg [7:0]   data_in [0:15];
    //reg [7:0]   data_out;
    
    reg [7:0] memory [0:23];
    
    
    always @(posedge PCLK)
    begin
        if (!(RESETn & memory[0])) begin
            for (i = 0; i < 32; i = i + 1) begin
                memory[i]  <= 8'b0;
            end
        end
        else begin
            memory[2]  <= valid;
            memory[3]  <= busy;
            if(valid)
                memory[36'h14] <= data_o;
            if (PSEL) begin
                if(PWRITE) begin
                    if (32'h14 <= PADDR <= 32'h23) begin
                        PSLVERR <= 1'b1;
                    end else if (PADDR <= 32'b0) begin
//                        if(PSTRB[0])
//                            memory[PADDR] <= PWDATA[7:0];
//                        else if(PSTRB[1])
//                            memory[PADDR] <= PWDATA[15:8];
//                        else if(PSTRB[2])
//                            memory[PADDR] <= PWDATA[23:16];
//                        else if(PSTRB[3])
//                            memory[PADDR] <= PWDATA[31:24];
                        if (PENABLE) begin
                            memory[PADDR]       <= (PSTRB[0])?   PWDATA[7:0]:  8'b0;
                            memory[PADDR + 1]   <= (PSTRB[1])?   PWDATA[15:8]: 8'b0;
                            PSLVERR   <= (PSTRB[3:2])? 1:0;
                            PREADY = 'b1;
                        end else begin
                            PREADY <= 'b0;
                        end
                    end else if ((32'h4 <= PADDR <= 32'h13)) begin
                        memory[PADDR] <= PWDATA;
                    end
    
                end else begin
                    if(32'h14 <= PADDR <= 32'h23) begin
                        if (PENABLE) begin
                            PREADY <= 'b1;
                            PRDATA[7:0]     <= memory[PADDR];
                            PRDATA[15:8]    <= memory[PADDR + 1];
                            PRDATA[23:16]   <= memory[PADDR + 2];
                            PRDATA[31:24]   <= memory[PADDR + 3];
                        end
                    end else if(32'h2 <= PADDR <= 32'h3) begin
                        if (PENABLE) begin
                            PRDATA <= memory[PADDR];
                            PREADY <= 'b1;
                        end
                    end
                end
                               
            end else begin
                PREADY = 8'b0;  //sel == 0
            end
                        
        end
        
    end    
endmodule
