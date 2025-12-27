module baud_rate_sample #(parameter BAUD = 1736)(
    input logic sys_clk,
    input logic rst_n,
    output logic clock_enable
);


localparam COUNTER_WIDTH = $clog2(BAUD);
logic [COUNTER_WIDTH-1:0] counter;

always_ff @(posedge sys_clk or negedge rst_n) begin
    if (!rst_n) begin
        counter <= 'b0;
        clock_enable <= 1'b0;
    end else if (counter == BAUD) begin
        clock_enable <= 1'b1;
        counter <= 'b0;
    end else  begin 
        counter++;
        clock_enable <= 1'b0;
    end
end


endmodule : baud_rate_sample