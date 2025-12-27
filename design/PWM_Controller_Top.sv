
`include "gamma_lut_table.sv"

module PWM_Controller_Top(
    input logic sys_clk,
    input logic rst_n,
    
    // UART RX LINE
    input logic rx_line,
    // BUTTONS
    input logic center_push, // push tp pwm
    input logic up_push, // increase value
    input logic down_push, // decrease value
    input logic left_push, // select value
    input logic right_push, // select value

    // DISPLAY
    output logic [6:0] cathodes_out,
    output logic [7:0] anodes,
    output logic [7:0] leds_array,
    // RGB OUTPUTS
    output logic red_pwm_out_1,
    output logic green_pwm_out_1,
    output logic blue_pwm_out_1,
    
    output logic red_pwm_out_2,
    output logic green_pwm_out_2,
    output logic blue_pwm_out_2

);

    localparam int N_BTNS = 5;
    localparam int VAL_WIDTH = 10;


    // Message 
    logic [23:0] rgb_msg;
    logic [7:0]  led_msg; 
    logic        rgb_valid, led_valid;
    //logic        rx_busy;
    
    // RGB Values & PWM signals
    logic [7:0] red_p,green_p,blue_p, led_p;
    logic red_pwm_out;
    logic green_pwm_out;
    logic blue_pwm_out;

    // ----------------------------------------
    logic [VAL_WIDTH-1:0] r_gamma;
    logic [VAL_WIDTH-1:0] g_gamma;
    logic [VAL_WIDTH-1:0] b_gamma;
    
    assign r_gamma = gamma_table[red_p];
    assign g_gamma = gamma_table[green_p];
    assign b_gamma = gamma_table[blue_p];

    // TODO: 
    // 1. after gamma table -> use the equation for Br = 0.299R + 0.587G + 0.114B
    // ----------------------------------------
  
    //logic [3:0][7:0] RGB_DISP;
    logic [31:0] RGB_DISP;
    assign led_p = RGB_DISP[31:24];
    assign red_p = RGB_DISP[23:16];
    assign green_p = RGB_DISP[15:8];
    assign blue_p = RGB_DISP[7:0];


    // GENERATE BUTTON DEBOUNCERS 
    logic [N_BTNS-1:0] btn_in;
    logic [N_BTNS-1:0] btn_out;
    logic center_btn, up_btn, down_btn, left_btn, right_btn;
    
    
    assign btn_in = {center_push, up_push, down_push, left_push, right_push};
    assign {center_btn, up_btn, down_btn, left_btn, right_btn} = btn_out;
    
    
    genvar i;
    generate
      for (i = 0; i < N_BTNS; i++) begin : gen_deb
        btn_debounce u_btn_debounce (
          .sys_clk    (sys_clk),
          .rst_n      (rst_n),
    //      .clk_enable (clk_enable),
          .btn_in     (btn_in[i]),
          .btn_out    (btn_out[i])
        );
      end
    endgenerate
    
    
    // --------------------- INCTANCE RX MODULE -------------------- 
    rx_phaser rx_inst(
        .sys_clk(sys_clk),
        .rst_n(rst_n),
        .rx_line(rx_line),
        .rgb_msg(rgb_msg),
        .led_msg(led_msg),
        .rgb_valid(rgb_valid),
        .led_valid(led_valid)
    //    .rx_busy(rx_busy)
    );
    
    // INSTANCE DISPLAY ON 7 SEGMENT 
    seven_segment segment_display(
        .system_clock(sys_clk),
        .cpu_rst_n(rst_n),
        .display_val(RGB_DISP),
        .cathodes_out(cathodes_out),
        .anodes(anodes)
    );
    
    // INSTANCE USER BUTTONS SELECTION
    user_interface ui(        
        .sys_clk(sys_clk),
        .rst_n(rst_n),
        .up_btn(up_btn),
        .down_btn(down_btn),
        .left_btn(left_btn),
        .right_btn(right_btn),
        .rgb_msg(rgb_msg),
        .rgb_valid(rgb_valid),
        .led_msg(led_msg),
        .led_valid(led_valid),
        .leds_array(leds_array),
        .RGB_DISP(RGB_DISP)
    );
    
    // INSTNACES OF THE PWM FOR RGB SIGNALS 
    pwm_gen #(.VAL_WIDTH(VAL_WIDTH)) red_pwm(
      .sys_clk(sys_clk),
      .rst_n(rst_n),
      // .value(red_p),
      .value(r_gamma),
      .enable_value(center_btn),
      .pwm_out(red_pwm_out)
    );
    
    pwm_gen #(.VAL_WIDTH(VAL_WIDTH)) green_pwm(
      .sys_clk(sys_clk),
      .rst_n(rst_n),
      // .value(green_p),
      .value(g_gamma),
      .enable_value(center_btn),
      .pwm_out(green_pwm_out)
    );
    
    pwm_gen #(.VAL_WIDTH(VAL_WIDTH)) blue_pwm(
      .sys_clk(sys_clk),
      .rst_n(rst_n),
      // .value(blue_p),
      .value(b_gamma),
      .enable_value(center_btn),
      .pwm_out(blue_pwm_out)
    );
    
    // MUX THE OUTPUT LED BASED ON SELECTION
    always_comb begin
      
      case(led_p)
        'h01: 
        begin 
        red_pwm_out_1 = red_pwm_out;
        green_pwm_out_1 = green_pwm_out;
        blue_pwm_out_1 = blue_pwm_out;
        
        red_pwm_out_2 = 'd0;
        green_pwm_out_2 = 'd0;
        blue_pwm_out_2 = 'd0;
        end
        'h02:
        begin 
        red_pwm_out_2 = red_pwm_out;
        green_pwm_out_2 = green_pwm_out;
        blue_pwm_out_2 = blue_pwm_out;
        
        red_pwm_out_1 = 'd0;
        green_pwm_out_1 = 'd0;
        blue_pwm_out_1 = 'd0;
        end
        default:
            begin 
        red_pwm_out_1 = red_pwm_out;
        green_pwm_out_1 = green_pwm_out;
        blue_pwm_out_1 = blue_pwm_out;
        
        red_pwm_out_2 = 'd0;
        green_pwm_out_2 = 'd0;
        blue_pwm_out_2 = 'd0;
        end
      endcase 
    end

endmodule
