`timescale 1ns / 1ps


module APB(
    input           PCLK,
                    PRESETn,
            [31:0]  PADDR,
                    //PPROT,
    input           PSEL,
                    PENABLE,
                    PWRITE,
                    busy,
                    valid,
            [31:0]  PWDATA,
            [3:0]   PSTRB,
                    
            [127:0] data_o,
                    
    output    reg           PREADY ,
              reg[31:0]  PRDATA = 0,
              reg        PSLVERR = 0
    );
    
    //wire busy_o;
    //wire valido;
  //  wire datao;
    //wire PREADYw;
    wire RESETn;
    wire [127:0] data_i;
    //wire [7:0] data0;
    wire req_ack;

    
    integer i;
    
    kuznechik_cipher DUT(
        .clk_i      (PCLK),
        .resetn_i   (RESETn),
        .data_i     (data_i),
        .request_i  (req_ack),
        .ack_i      (req_ack),
        .data_o     (data_o),
        .valid_o    (valid),
        .busy_o     (busy)
    );
    
   
    //wire         busy; 
    //reg [7:0]   REQ_ASK;
    //reg         valid;
    //reg [7:0]   BUSY;
    //reg [7:0]   data_in [0:15];
    //reg [7:0]   data_out;
    
    reg [7:0] memory [0:35];
    
   
    //assign data0 = memory[4];
    //assign valid = memory[2];
    //assign busy  = memory[3];
    assign data_i = {memory[19],memory[18],memory[17],memory[16],memory[15],memory[14],memory[13],memory[12],
                     memory[11],memory[10],memory[9],memory[8],memory[7],memory[6],memory[5],memory[4]};
    
    assign RESETn = PRESETn && memory[0]; 
    assign req_ack = (memory[1])? 1:0;
    //assign PREADY = PENABLE;
    //assign PREADY = PREADYw;
    
    always @(posedge PCLK)
    begin
        PREADY <= PENABLE;
        if (!PRESETn) begin
            //for (i = 1; i < 32; i = i + 1) begin
            //    memory[i]  <= 8'h00;
            //end
            //memory[0]  <= 8'h1;
            
            $readmemh("RST_mem.mem",memory);
        end
        else begin
            memory[2]  <= valid;
            memory[3]  <= busy;
            if(valid) begin
                for(i = 0;  i < 128; i = i + 8)begin
                    memory[36'h14 + i/8] <= {data_o[i+7],data_o[i+6],data_o[i+5],data_o[i+4],data_o[i+3],data_o[i+2],data_o[i+1],data_o[i]}; 
                end
            end
            if (PSEL) begin
                if(PWRITE) begin
                    //PSLVERR <= 1'b0;
                    if ((PADDR <= 'h23) && (PADDR >= 'h14)) begin
                        PSLVERR <= 1'b1;
                    end else 
                    if (PADDR == 32'b0) begin
                          //PSLVERR <= 1'b0;
//                        if(PSTRB[0])
//                            memory[PADDR] <= PWDATA[7:0];
//                        else if(PSTRB[1])
//                            memory[PADDR] <= PWDATA[15:8];
//                        else if(PSTRB[2])
//                            memory[PADDR] <= PWDATA[23:16];
//                        else if(PSTRB[3])
//                            memory[PADDR] <= PWDATA[31:24];
                        if (PENABLE) begin
                            memory[0] <= (PSTRB[0])?   PWDATA[7:0] : 8'b0;
                            memory[1] <= (PSTRB[1])?   PWDATA[15:8]: 8'b0;
                            //PSLVERR   <= (PSTRB[3:2])? 1:0;
                            PSLVERR   <= (PSTRB[3:2])? 1:0;
                            //PREADY <= 'b1;
                        end else begin
                            //PREADY <= 'b0;
                            PSLVERR <= 'b0;
                        end
                    end else if ((32'h4 <= PADDR <= 32'h13)) begin
                        PSLVERR <= 1'b0;
                        memory[PADDR]     <= PWDATA[7:0];
                        memory[PADDR + 1] <= PWDATA[15:8];
                        memory[PADDR + 2] <= PWDATA[23:16];
                        memory[PADDR + 3] <= PWDATA[31:24];
                    end
                
                end else begin  //////////////////////////!PWRITE
                    //if((32'h14 <= PADDR) && (PADDR <= 32'h23)) begin
                        //if (!PADDR && !PSTRB[2] && !PSTRB[3]) begin
                      //      PSLVERR <= 'b1;
                     //   end else begin
                            PSLVERR <= 'b0;
                            //PREADY <= 'b1;
                            PRDATA[7:0]     <= memory[PADDR];
                            PRDATA[15:8]    <= memory[PADDR + 1];
                            PRDATA[23:16]   <= memory[PADDR + 2];
                            PRDATA[31:24]   <= memory[PADDR + 3];
                    //    end
                    //end else if(32'h2 <= PADDR <= 32'h3) begin
                      //  if (PENABLE) begin
                        //    PRDATA <= memory[PADDR];
                        //    PREADY <= 'b1;
                        //end
                    //end
                end
                               
            end else begin
                //PREADY <= 8'b0;  //sel == 0
            end
                        
        end
        
    end    
endmodule
