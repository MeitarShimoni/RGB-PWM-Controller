// package pwm_design_param;
//     // parameter MAX_PWM_COUNT = 2048;
//     parameter MAX_PWM_COUNT = 1024;
//     localparam COUNTER_VAL_WIDTHWIDTH = $clog2(MAX_PWM_COUNT);
//     // parameter  = 8;


// endpackage

//import pwm_design_param::*;

// TODO: 
// Normalize the value to 255.
// 1.Value = (input_value/MAX_VALUE)*255

module pwm_gen #(
    parameter VAL_WIDTH = 8,
    parameter MAX_PWM_COUNT = 1024 )(
    input logic sys_clk,
    input logic rst_n,
    input logic [VAL_WIDTH-1:0] value,
    input logic enable_value,

    output logic pwm_out
);

localparam COUNTER_WIDTH = $clog2(MAX_PWM_COUNT);
logic [COUNTER_WIDTH-1:0] pwm_counter;
//logic pwm_out;
logic cycle_done; // debug
//logic [VAL_WIDTH-1:0] value_enabled; 
logic [VAL_WIDTH-1:0] value_reg; 

always_ff @(posedge sys_clk or negedge rst_n) begin
    if(!rst_n) begin
        pwm_counter <= 'd0;
        cycle_done <= 1'b0;
        value_reg <= 'd0;
    end else begin
//        value_enabled <= (enable_value) ? value : value_enabled; // without enable
        if(pwm_counter == MAX_PWM_COUNT-1) begin // full cycle
            pwm_counter <= 'd0;
            cycle_done <= 1'b1;
            // value_reg <= value;
        end else 
        begin 
            pwm_counter <= pwm_counter + 1;
            cycle_done <= 1'b0;
//            if(pwm_counter == MAX_PWM_COUNT-2) value_reg <= value_enabled; 
            if(pwm_counter == MAX_PWM_COUNT-2) value_reg <= value; // without enable
        end



    end
end

always_ff @(posedge sys_clk or negedge rst_n) begin
    if (!rst_n) begin
//        pwm_out <= 1'b0;
        pwm_out <= 1'b0;
    end else begin
        if (value_reg == 0 && (MAX_PWM_COUNT-1)) pwm_out <= 1'b0;
        else if (pwm_counter == MAX_PWM_COUNT-1) pwm_out <= 1'b1;
        else if (pwm_counter == value_reg) pwm_out <= ~pwm_out; //|| pwm_counter == 0  

    end
end




endmodule