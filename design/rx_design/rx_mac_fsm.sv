

package rx_mac_design_params;

    localparam MSG_WIDTH = 16;

    typedef enum logic [1:0] {IDLE, START, DIGIT,VALID} state_e;




    localparam MSG_START_ASCCI = 8'h7B; // ASCII "{"
    
    localparam MIN_CHAR = 8'h41; // ASCII "A"
    localparam MAX_CHAR = 8'h5A; // ASCII "Z" 
    
    localparam MIN_DIGIT = 8'h30; // ASCII "0"
    localparam MAX_DIGIT = 8'h39; // ASCII "9"


    localparam MSG_R_ASCCI     = 8'h52; // ASCII "R"
    localparam MSG_C_ASCCI     = 8'h43; // ASCII "C"
    localparam MSG_V_ASCCI     = 8'h56; // ASCII "V"
    localparam MSG_COMA_ASCCI  = 8'h2C; // ASCII ","
    localparam MSG_CLOSE_ASCCI = 8'h7D; // ASCII "}"

endpackage

import rx_mac_design_params::*;

module rx_mac_fsm(
    input logic sys_clk,
    input logic rst_n,
    input logic clk_enable,

    input logic [7:0] data_recived,
    input logic rx_done,

    output logic [126:0] valid_messege_out,
    output logic valid_message_flag//,
//    output logic mac_busy

    );


// logic [MSG_WIDTH-1:0] valid_messege_out;
state_e current_state, next_state;
logic [3:0] data_counter, ptr;
logic [1:0] cnt;
//logic [7:0] mem [15:0];
logic [15:0][7:0] mem;

always_ff @(posedge sys_clk or negedge rst_n) begin
    if(!rst_n) current_state <= IDLE;
    else if(clk_enable) current_state <= next_state;
end

always_ff @(posedge sys_clk or negedge rst_n) begin
    if(!rst_n) begin
        // resets all registers
        data_counter <= 'd0;
//        mac_busy <= 1'b0;
        cnt <= 'd0;
        ptr <= 'd15;
        valid_messege_out <= 'd0;
        valid_message_flag <= 1'b0;
    end else if(clk_enable) begin
//    valid_message_flag <= 1'b0; // to avoid set and reset warning
        case(next_state) 
            IDLE: 
            begin
                data_counter <= 'd0;
                cnt <= 'd0;
//                mac_busy <= 1'b0;
                valid_message_flag <= 1'b0;
                mem <= 'd0;
                ptr <= 'd15;
            end
                
            START: 
            begin
//                mac_busy <= 1'b1;
                data_counter <= 'd0;
                     if(rx_done) begin 
                        mem[ptr] <= data_recived;
                        ptr <= ptr - 1;
                     end
            end
            DIGIT:
            begin
                if(rx_done) begin
                    data_counter <= data_counter + 1;
                    ptr <= ptr - 1;
                    mem[ptr] <= data_recived;
                end
            end
            VALID:
            begin
                cnt <= cnt + 1;
                ptr <= ptr - 1;
                mem[ptr] <= data_recived;
                if(cnt == 1) begin
                    valid_messege_out <= mem;
                    valid_message_flag <= 1'b1;
                end
            end
        endcase
    end
end



always_comb begin
    case(current_state) 
        IDLE: next_state = (rx_done && data_recived == MSG_START_ASCCI) ? START : IDLE;
        START:
            if(rx_done) next_state = (data_recived >= MIN_CHAR && data_recived <= MAX_CHAR) ? DIGIT : IDLE; 
            else next_state = START;
        DIGIT:
            if(rx_done) begin
                if (data_counter == 4) begin // coma or }
                    if (data_recived == MSG_COMA_ASCCI) next_state = START;
                    else if (data_recived == MSG_CLOSE_ASCCI) next_state = VALID;
                    else next_state = IDLE;
                end
                else begin    
                    if (data_recived >= MIN_DIGIT && data_recived <= MAX_DIGIT) next_state = DIGIT;
                    else next_state = IDLE;
                end
            end else next_state = DIGIT;
        VALID:
            next_state = (cnt == 2) ? IDLE : VALID;
        default: next_state = current_state;
    endcase
end

endmodule