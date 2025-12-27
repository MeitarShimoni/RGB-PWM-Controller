



module btn_debounce #(
    parameter int DELAY = 5_000_000,//15, // 20ms for 100MHz
    parameter int BTN_WIDTH = 1
)(
    input logic sys_clk,
    input logic rst_n,
    input logic [BTN_WIDTH-1:0] btn_in,
    output logic [BTN_WIDTH-1:0] btn_out
);

// 20ms delay
logic [$clog2(DELAY+1)-1:0] btn_counter;



always_ff @(posedge sys_clk or negedge rst_n) begin
    if (!rst_n) begin
        btn_counter <= 'd0;
        btn_out <= 'd0;
    end else if (btn_in) begin
        if (btn_counter == DELAY-1) begin
            btn_counter <= 'd0; // becomes DELAY-1
            btn_out     <= 'd1;             // pulse exactly once
        end else begin
            // already at DELAY-1, keep locked until release
            btn_counter <= btn_counter + 1;
            btn_out     <= 'd0;
        end
    end else begin
        btn_counter <= 'd0;
        btn_out     <= 'd0;
    end
    
    end



endmodule

