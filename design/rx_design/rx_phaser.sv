


module rx_phaser(
    input logic sys_clk,
    input logic rst_n,

    input logic rx_line,

    output logic [23:0] rgb_msg,
    output logic [7:0] led_msg,
    output logic rgb_valid,
    output logic led_valid//,

//    output logic rx_busy
);

logic [7:0] data_recived;
logic valid_message_flag;
logic [126:0] valid_messege_out;

localparam MSG_R_ASCCI     = 8'h52; // ASCII "R"
localparam MSG_G_ASCCI     = 8'h47; // ASCII "G"
localparam MSG_B_ASCCI     = 8'h42; // ASCII "B"
localparam MSG_L_ASCCI     = 8'h4C; // ASCII "L"

baud_rate_sample #(.BAUD(108)) baud_rate_int(
    .sys_clk(sys_clk),
    .rst_n(rst_n),
    .clock_enable(clk_enable)
    );
// baud_rate_sample #(.BAUD(108)) baud_rate_rx_sample (.sys_clk(sys_clk), .rst_n(rst_n), .clock_enable(clock_enable));


rx_phy_fsm rx_phy(
    .sys_clk(sys_clk),
    .rst_n(rst_n),
    .baud_rate_oversample(clk_enable), 
    .rx_line(rx_line),
//    .rx_busy(rx_busy),
    .rx_done(rx_done), 
    .data_recived(data_recived)
    );


rx_mac_fsm rx_mac_inst(
    .sys_clk(sys_clk),
    .rst_n(rst_n),
    .clk_enable(clk_enable),
    .data_recived(data_recived),
    .rx_done(rx_done),
    .valid_messege_out(valid_messege_out),
    .valid_message_flag(valid_message_flag)//,
//    .mac_busy(mac_busy)
);

logic [15:0][7:0] msg_out;
// maybe to take only the used bits from the first place?
assign msg_out = valid_messege_out[126:0];

// logic [23:0] rgb_msg;
//logic rgb_valid;

//logic [7:0] led_msg;
//logic led_valid;

// --------------- CONVERTING FROM ASCII TO A DECEMAL VALUE -------------------
logic [7:0] red, green, blue, led;
assign red = (msg_out[13] - 8'h30)*100 + (msg_out[12]-8'h30)*10 + (msg_out[11]-8'h30);
assign green = (msg_out[8]-8'h30)*100 + (msg_out[7]-8'h30)*10 + (msg_out[6]-8'h30);
assign blue = (msg_out[3]-8'h30)*100 + (msg_out[2]-8'h30)*10 + (msg_out[1]-8'h30);

assign led = (msg_out[13]-8'h30)*100 + (msg_out[12]-8'h30)*10 + (msg_out[11]-8'h30);

always_ff @(posedge sys_clk or negedge rst_n) begin
    if(!rst_n) begin
        // reset
        rgb_msg <= 'd0;
        rgb_valid <= 0;
        led_msg <= 'd0;
        led_valid = 0;
    end else if(valid_message_flag) begin
        if(msg_out[14] == MSG_R_ASCCI && msg_out[9] == MSG_G_ASCCI && msg_out[4] == MSG_B_ASCCI) begin
                
            rgb_msg <= {red,green,blue};
            rgb_valid = 1'b1;
        end 

        if(msg_out[14] == MSG_L_ASCCI) begin
            led_msg <= (led == 016 || led == 017) ? led : led_msg;
            led_valid = 1'b1;
        end 
    end else begin
        rgb_valid = 1'b0;
        led_valid = 1'b0;
    end
end





endmodule