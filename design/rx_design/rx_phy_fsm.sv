package phy_design_params_pkg;

    // PHY parameters
    localparam DATA_WIDTH = 8;
    localparam OVERSAMPLE_RATE = 16; // 16x oversampling
    localparam SAMPLE_POINT = 6;

    typedef enum logic [2:0] {IDLE, START, DATA, STOP} state_e;
    

endpackage


import phy_design_params_pkg::*;

module rx_phy_fsm(
    input sys_clk,
    input rst_n,

    input baud_rate_oversample, // runs at 57600*16
    input logic rx_line,
//    output logic rx_busy,
    output logic rx_done,
    output logic [7:0] data_recived
);


logic [3:0] cnt2; // reset on 16.
logic [3:0] data_counter;
logic [phy_design_params_pkg::DATA_WIDTH-1:0] shift_reg;
logic rx_busy;
logic Q1,Q2,Q3;
// detection
always_ff @(posedge sys_clk or negedge rst_n) begin
    if (!rst_n) begin
        Q1 <= 0;
        Q2 <= 0;
        Q3 <= 0; 
    end else if (baud_rate_oversample) begin
        Q1 <= rx_line;
        Q2 <= Q1;
        Q3 <= Q2;
    end
end

phy_design_params_pkg::state_e current_state, next_state;

always_ff @(posedge sys_clk or negedge rst_n) begin
    if(!rst_n) current_state <= phy_design_params_pkg::IDLE;
    else if(baud_rate_oversample) current_state <= next_state;
end

always_ff @(posedge sys_clk or negedge rst_n) begin
    if(!rst_n) begin
        // reset
        data_counter <= 'd0;
//        cnt1 <= 'd0;
        cnt2 <= 'd0;
        rx_busy <= 1'b0;
        rx_done <= 1'b0;
        shift_reg <= 'd0;
        data_recived <= 'd0;

    end else if(baud_rate_oversample) begin
        case(next_state)
            phy_design_params_pkg::IDLE: begin
                rx_busy <= 1'b0;
//                cnt1 <= (cnt1 == 7) ? 'd0 : (cnt1 + 1);
                data_counter <= 'd0;
                rx_done <= 1'b0; // maybe no
            end
            phy_design_params_pkg::START: 
            begin
                cnt2 <= (cnt2 == 15) ? 'd0 : (cnt2 + 1);  
//                
            end
            phy_design_params_pkg::DATA: 
                begin
                    rx_busy <= 1'b1;
                    data_counter <= (cnt2 != SAMPLE_POINT) ? data_counter : (data_counter + 1); // was 15 instead of 7
                    cnt2 <= (cnt2 == 15) ? 'd0 : (cnt2 + 1); 
                    if (cnt2 == SAMPLE_POINT) begin
                       shift_reg[data_counter] <= rx_line; // LSB FIRST
//                     shift_reg <= {shift_reg[6:0], rx_line}; // MSB FIRST 
                    end
                    // shift_reg[data_counter] <= (cnt2 == 15) ? rx_line; // only when cnt2 == 15 sample (baud_rate affect)
                end
            phy_design_params_pkg::STOP: 
                begin
                    cnt2 <= (cnt2 == 15) ? 'd0 : (cnt2 + 1);
                    rx_done <= (cnt2 == 15);
                    if(cnt2 == 15) begin
                        data_recived <= shift_reg;
                    end 
//                    rx_done <= (cnt2 == 15) ? 1'b1 : 1'b0;
                end
            default: rx_busy <= 1'b0;
        endcase
    end
end

always_comb begin
    case(current_state)
        phy_design_params_pkg::IDLE: next_state = ((!Q1 && Q2)) ? phy_design_params_pkg::START : phy_design_params_pkg::IDLE; //&& cnt1 == 7
        phy_design_params_pkg::START:
            begin
                if ((cnt2 == 7) && (~Q1 && ~Q2 && ~Q3)) next_state = phy_design_params_pkg::DATA;
                else if ((cnt2 == 15) && !(~Q1 && ~Q2 && ~Q3)) next_state = phy_design_params_pkg::IDLE;
                else next_state = phy_design_params_pkg::START; // cnt2 != 15
            end
        phy_design_params_pkg::DATA: next_state = ((cnt2 == 15) && data_counter == 8) ? phy_design_params_pkg::STOP : phy_design_params_pkg::DATA;
        phy_design_params_pkg::STOP: 
            begin 
                if(!Q1 && Q2) next_state = phy_design_params_pkg::START;
                else if(cnt2 == 15) next_state = phy_design_params_pkg::IDLE;
                else next_state = phy_design_params_pkg::STOP;
//                next_state = (cnt2 == 15) ? IDLE : STOP; 
            end //rx_done <= (cnt2 == 15) ? 1'b1 : 1'b0; end
        default: next_state = phy_design_params_pkg::IDLE;
    endcase
end

endmodule : rx_phy_fsm