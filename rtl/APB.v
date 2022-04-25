`timescale 1ns / 1ps


module APB(
    input           PCLK,
                    PRESETn,
            [31:0]  PADDR,
                    //PPROT,
    input           PSEL,
                    PENABLE,
                    PWRITE,
            [31:0]  PWDATA,
            [3:0]   PSTRB,                    
                
    output              
                    PSLVERR,
          reg       PREADY,
          reg[31:0] PRDATA
                      
    );
    localparam addr_data_out_l = 6'h14;
    localparam addr_data_out_h = 6'h23;
    localparam addr_data_in_l = 6'h4;
    localparam addr_data_in_h = 6'h13;
    localparam length_mem = 6'h23;
    
    wire [127:0]    data_out;
    wire            reset_n;
    wire [127:0]    data_in;
    wire            req_ack;
    wire            busy;
    wire            valid;
    
    reg [7:0] memory [0:35];
    
    integer r,i; 
  
    kuznechik_cipher DUT(
        .clk_i      (PCLK),
        .resetn_i   (reset_n),
        .data_i     (data_in),
        .request_i  (req_ack),
        .ack_i      (req_ack),
        .data_o     (data_out),
        .valid_o    (valid),
        .busy_o     (busy)
    );
       
    assign data_in = {memory[19],memory[18],memory[17],memory[16],memory[15],memory[14],memory[13],memory[12],
                     memory[11],memory[10],memory[9],memory[8],memory[7],memory[6],memory[5],memory[4]};    
    assign reset_n = PRESETn && memory[0][0]; 
    assign req_ack = memory[1][0];    
    assign PSLVERR = ( ((PADDR <=  addr_data_out_h) && (PADDR >= addr_data_out_l) && PWRITE) || (!PADDR && PSTRB[3:2]) )? 1:0; 
         
    always @(posedge PCLK) begin    
        if (!PRESETn) begin           
            memory[0][0] <= 'b1;
            PREADY <= 'b0;
            for(r = 1;  r <= length_mem; r = r + 1)begin
                memory[r] <= 8'b0;
            end
        end 
        else begin
            PREADY <= PENABLE;
            memory[2][0]  <= valid;
            memory[3][0]  <= busy;
            if(valid) begin                     
                for(i = 0;  i < 128; i = i + 1)begin
                    memory[addr_data_out_l + i/8][i % 8] <= data_out[i];  //localparam 
                end    
            end
            if (PSEL) begin
                if(PWRITE && PENABLE) begin
                    if (PADDR == 32'b0) begin
                        memory[0] <= (PSTRB[0])?   PWDATA[7:0] : 8'b0;
                        memory[1] <= (PSTRB[1])?   PWDATA[15:8]: 8'b0;
                    end 
                    else if (addr_data_in_l <= PADDR <= addr_data_in_h) begin
                        memory[PADDR]     <= PWDATA[7:0];
                        memory[PADDR + 1] <= PWDATA[15:8];
                        memory[PADDR + 2] <= PWDATA[23:16];
                        memory[PADDR + 3] <= PWDATA[31:24];
                    end               
                end else begin  //////////////////////////!PWRITE
                    PRDATA[7:0]     <= memory[PADDR];
                    PRDATA[15:8]    <= memory[PADDR + 1];
                    PRDATA[23:16]   <= memory[PADDR + 2];
                    PRDATA[31:24]   <= memory[PADDR + 3];
                end                              
            end                                   
        end       
    end    
endmodule
