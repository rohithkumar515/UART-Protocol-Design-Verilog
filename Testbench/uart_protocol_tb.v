module uart_protocol_tb;

reg clk;
reg rst;
reg start;
reg [7:0] din;

wire tx;
wire rx;

wire busy;

wire [7:0] dout;
wire rx_valid;


// CONNECT TX TO RX
assign rx = tx;


// UART TX
uart_tx #(
    .CLK_FREQ(160),
    .BAUD(1)
) tx_inst
(
    .clk(clk),
    .rst(rst),
    .start(start),
    .din(din),
    .tx(tx),
    .busy(busy)
);


// UART RX
uart_rx #(
    .CLK_FREQ(160),
    .BAUD(1)
) rx_inst
(
    .clk(clk),
    .rst(rst),
    .rx(rx),
    .dout(dout),
    .rx_valid(rx_valid)
);


// CLOCK
always #5 clk = ~clk;


// TEST
initial
begin

    clk   = 0;
    rst   = 1;
    start = 0;
    din   = 0;


    // RESET
    #20;

    rst = 0;


    // DATA TO TRANSMIT
    din = 8'b10110010;


    // START TRANSMISSION
    #10;

    start = 1;

    #10;

    start = 0;


    // WAIT FOR RX TO RECEIVE COMPLETE BYTE
    wait(rx_valid == 1'b1);
    
    
 $display("--------------------------------");
       $display("TX DATA       = %b", din);
       $display("RX DATA       = %b", dout);
       $display("RX VALID      = %b", rx_valid);
       $display("--------------------------------");
   
   
       if(dout == din)
       begin
           $display("UART TEST PASSED");
       end
       else
       begin
           $display("UART TEST FAILED");
       end


    #100;

    $finish;

end

endmodule
