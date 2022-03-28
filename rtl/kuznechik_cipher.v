module kuznechik_cipher(
    input        clk_i,       // Тактовый сигнал
                 resetn_i,    // Синхронный сигнал сброса с активным уровнем LOW
                 request_i,   // Сигнал запроса на начало шифрования
                 ack_i,       // Сигнал подтверждения приема зашифрованных данных
         [127:0] data_i,      // Шифруемые данные

    output       busy_o,      // Сигнал, сообщающий о невозможности приёма
                              // очередного запроса на шифрование, поскольку
                              // модуль в процессе шифрования предыдущего
                              // запроса
    reg          valid_o,     // Сигнал готовности зашифрованных данных
    reg  [127:0] data_o       // Зашифрованные данные
);

`define  IDLE        0
`define  KEY_PHASE   1
`define  S_PHASE     2
`define  L_PHASE     3
`define  FINISH      4

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
reg [127:0] address;
reg [7:0]   value;
reg         busy;
reg [3:0]   count;
reg [3:0]   i;
assign  busy_o = busy;



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
        valid_o <= 0;
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
                    valid_o <= 0;
                    address <= data_i;
                    i <= 0;
                end
            end
            `KEY_PHASE:
            begin
                state <= `S_PHASE;
                address = address ^ key_mem[i];
                i <= i + 1;
                if (i == 9)
                begin
                    state <= `FINISH;
                    valid_o <= 1;
                    data_o <= address;
                end
            end
            `S_PHASE:
            begin
                address[127:120]  <= S_box_mem[address[127:120]];
		address[121:112]  <= S_box_mem[address[119:112]];
                address[111:104]  <= S_box_mem[address[111:104]];
                address[105:96]   <= S_box_mem[address[103:96]];
                address[95:88]    <= S_box_mem[address[95:88]];
                address[89:80]    <= S_box_mem[address[87:80]];
                address[79:72]    <= S_box_mem[address[79:72]];
                address[73:64]    <= S_box_mem[address[71:64]];
                address[63:56]    <= S_box_mem[address[63:56]];
                address[57:48]    <= S_box_mem[address[55:48]];
                address[47:40]    <= S_box_mem[address[47:40]];
                address[41:32]    <= S_box_mem[address[39:32]];
                address[31:24]    <= S_box_mem[address[31:24]];
                address[25:16]    <= S_box_mem[address[23:16]];
                address[15:8]     <= S_box_mem[address[15:8]];
                address[9:0]      <= S_box_mem[address[7:0]];
                
                state <= `L_PHASE;
                count <= 0;
            end
            `L_PHASE:
            begin
                addres <= {L_mul_148_mem[address[127:120]] ^ L_mul_32_mem[address[119:112]] ^ L_mul_133_mem[address[111:104]] ^ L_mul_16_mem[address[103:96]] ^ L_mul_194_mem[address[95:88]] ^ L_mul_192_mem[address[87:80]] ^ address[79:72] ^ L_mul_251_mem[address[71:64]] ^ address[63:56] ^ L_mul_192_mem[address[55:48]] ^ L_mul_194_mem[address[47:40]] ^ L_mul_16_mem[address[39:32]] ^ L_mul_133_mem[address[31:24]] ^ L_mul_32_mem[address[23:16]] ^ L_mul_148_mem[address[15:8]] ^ address[7:0],address[127:8]};
                //address <= {value, address[127:8]};
                count <= count + 1;
                if(count == 15)
                    state <= `KEY_PHASE;
            end
            `FINISH:
            begin
                if (ack_i == 1)
                begin
                    valid_o <= 0;
                    busy <= 0;
                end
                if (request_i)
                    begin
                        state <= `KEY_PHASE;
                        address <= data_i;
                        busy <= 0;
                        value <= 0;
                        valid_o <= 0;
                        i <= 0;
                    end
                else
                    begin
                        state <= `IDLE;
                        busy <= 0;
                        value <= 0;
                        valid_o <= 0;
                        i <= 0;
                    end
             end
        endcase    
    end
end

endmodule
