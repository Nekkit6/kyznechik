`define IDLE        0
`define KEY_PHASE   1
`define S_PHASE     2
`define L_PHASE     3
`define FINISH      4

module kuznechik_cipher(
    input               clk_i,      // Тактовый сигнал
                        resetn_i,   // Синхронный сигнал сброса с активным уровнем LOW
                        request_i,  // Сигнал запроса на начало шифрования
                        ack_i,      // Сигнал подтверждения приема зашифрованных данных
                [127:0] data_i,     // Шифруемые данные

    output     wire     busy_o,     // Сигнал, сообщающий о невозможности приёма
                                    // очередного запроса на шифрование, поскольку
                                    // модуль в процессе шифрования предыдущего
                                    // запроса
           wire          valid_o,    // Сигнал готовности зашифрованных данных
           wire  [127:0] data_o      // Зашифрованные данные
);


reg [127:0] key_mem [0:9];
reg [7:0] S_box_mem [0:255];

reg [7:0] L_mul_16_mem  [0:255];
reg [7:0] L_mul_32_mem  [0:255];
reg [7:0] L_mul_133_mem [0:255];
reg [7:0] L_mul_148_mem [0:255];
reg [7:0] L_mul_192_mem [0:255];
reg [7:0] L_mul_194_mem [0:255];
reg [7:0] L_mul_251_mem [0:255];

reg [2:0]   state;
reg [127:0] data;
reg [7:0]   value;
reg         busy;
reg         valid;
reg [127:0] datao;
reg [3:0]   count;
reg [3:0]   i;
assign  busy_o = busy;
assign valid_o = valid;
assign data_o = datao;

initial begin
    $readmemh("keys.mem",key_mem );
    $readmemh("S_box.mem",S_box_mem );

    $readmemh("L_16.mem", L_mul_16_mem );
    $readmemh("L_32.mem", L_mul_32_mem );
    $readmemh("L_133.mem",L_mul_133_mem);
    $readmemh("L_148.mem",L_mul_148_mem);
    $readmemh("L_192.mem",L_mul_192_mem);
    $readmemh("L_194.mem",L_mul_194_mem);
    $readmemh("L_251.mem",L_mul_251_mem);
    
end

always @(posedge clk_i)
begin
    if (!resetn_i)
    begin
        state <= `IDLE;
        value <= 0;
        busy <= 0;
        valid <= 0;
        i <= 0;
    end
    else
    begin
        case (state)
            `IDLE:
            begin
                if (request_i)
                begin
                    state <= `KEY_PHASE;
                    value <= 0;
                    busy <= 1;
                    valid <= 0;
                    data <= data_i;
                    i <= 0;
                end
            end
            `KEY_PHASE:
            begin
                state <= `S_PHASE;
                data = data ^ key_mem[i];
                i <= i + 1;
                if (i == 9)
                begin
                    state <= `FINISH;
                    valid <= 1;
                    datao <= data;
                end
            end
            `S_PHASE:
            begin
                data[127:120]  <= S_box_mem[data[127:120]];
                data[119:112]  <= S_box_mem[data[119:112]];
                data[111:104]  <= S_box_mem[data[111:104]];
                data[103:96]   <= S_box_mem[data[103:96]];
                data[95:88]    <= S_box_mem[data[95:88]];
                data[87:80]    <= S_box_mem[data[87:80]];
                data[79:72]    <= S_box_mem[data[79:72]];
                data[71:64]    <= S_box_mem[data[71:64]];
                data[63:56]    <= S_box_mem[data[63:56]];
                data[55:48]    <= S_box_mem[data[55:48]];
                data[47:40]    <= S_box_mem[data[47:40]];
                data[39:32]    <= S_box_mem[data[39:32]];
                data[31:24]    <= S_box_mem[data[31:24]];
                data[23:16]    <= S_box_mem[data[23:16]];
                data[15:8]     <= S_box_mem[data[15:8]];
                data[7:0]      <= S_box_mem[data[7:0]];

                state <= `L_PHASE;
                count <= 0;
            end
            `L_PHASE:
            begin
                data <= {L_mul_148_mem[data[127:120]] ^ L_mul_32_mem[data[119:112]] ^ L_mul_133_mem[data[111:104]]   ^ 
                 L_mul_16_mem[data[103:96]] ^ L_mul_194_mem[data[95:88]] ^ L_mul_192_mem[data[87:80]] ^ data[79:72] ^ 
                 L_mul_251_mem[data[71:64]] ^ data[63:56] ^ L_mul_192_mem[data[55:48]] ^ L_mul_194_mem[data[47:40]] ^ 
                 L_mul_16_mem[data[39:32]] ^ L_mul_133_mem[data[31:24]] ^ L_mul_32_mem[data[23:16]] ^ L_mul_148_mem[data[15:8]] ^ data[7:0], data[127:8]};
                //data <= {value, data[127:8]};
                count <= count + 1;
                if(count == 15)
                    state <= `KEY_PHASE;
            end
            `FINISH:
            begin
                
                if (request_i)
                    begin
                        state <= `KEY_PHASE;
                        data <= data_i;
                        busy <= 0;
                        value <= 0;
                        valid <= 0;
                        i <= 0;
                    end
                else if (ack_i == 1) 
                    begin 
                        state <= `IDLE;
                        busy <= 0;
                        value <= 0;
                        valid <= 0;
                        i <= 0;
                    end
                    
                
             end
        endcase    
    end
end

endmodule
