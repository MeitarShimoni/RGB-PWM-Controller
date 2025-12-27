
module user_interface(
    input logic sys_clk,
    input logic rst_n,

    input logic up_btn,
    input logic down_btn,
    input logic left_btn,
    input logic right_btn,
    
    input logic [23:0] rgb_msg,
    input logic rgb_valid,
    input logic [7:0] led_msg,
    input logic led_valid,

    output logic [7:0] leds_array,
//    output logic [3:0][7:0] RGB_DISP
    output [31:0] RGB_DISP


);

logic [7:0] r_temp;
logic [7:0] g_temp;
logic [7:0] b_temp;
logic [7:0] l_temp;



//logic [3:0][7:0] RGB_DISP;
assign RGB_DISP = {l_temp, r_temp, g_temp, b_temp};





logic [1:0] val_ptr;
//logic [7:0] leds_array;

always_ff @(posedge sys_clk or negedge rst_n) begin
if (!rst_n) begin
    // reset
    r_temp <= 'd0;
    g_temp <= 'd0;
    b_temp <= 'd0;
    l_temp <= 'b01;
    val_ptr <= 'd0;
    leds_array <= 8'b0000_0011;
end else begin
    if(rgb_valid) begin
        r_temp <= rgb_msg[23:16];
        g_temp <= rgb_msg[15:8];
        b_temp <= rgb_msg[7:0];
    end else if(led_valid) begin
    case(led_msg)
        16: l_temp <= 'h01;
        17: l_temp <= 'h02;
        default: l_temp <= 'h01;
    endcase
//        l_temp <= led_msg;
    end
    else begin

        if (left_btn && val_ptr < 3) val_ptr <= val_ptr + 1;
        if (right_btn && val_ptr > 0) val_ptr <= val_ptr - 1;

        unique case(val_ptr)
            0: // BLUE  
            begin 
                // turn select LEDS
                leds_array <= 8'b0000_0011;
                if (up_btn && b_temp < 255) b_temp <= b_temp + 1;
                if (down_btn && b_temp > 0) b_temp <= b_temp - 1;
            end
            1: // GREEN
            begin
                // turn select LEDS
                leds_array <= 8'b0000_1100;
                if (up_btn && g_temp < 255) g_temp <= g_temp + 1;
                if (down_btn && g_temp > 0) g_temp <= g_temp - 1;
            end
            2: // RED
            begin
                // turn select LEDS
                leds_array <= 8'b0011_0000;
                if (up_btn && r_temp < 255) r_temp <= r_temp + 1;
                if (down_btn && r_temp > 0) r_temp <= r_temp - 1;
            end
            3: // LEDS
            begin
                // turn select LEDS
                leds_array <= 8'b1100_0000; 
                if (up_btn && l_temp < 'h02) l_temp <= l_temp + 1;
                if (down_btn && l_temp > 'h01) l_temp <= l_temp - 1;
            end
            default: 
            begin
                // turn select LEDS
                leds_array <= 8'b0000_0011;
                if (up_btn && b_temp < 255) b_temp <= b_temp + 1;
                if (down_btn && b_temp > 0) b_temp <= b_temp - 1;
            end
        endcase
    end
end
end


endmodule