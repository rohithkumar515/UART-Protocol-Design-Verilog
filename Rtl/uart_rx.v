module uart_rx #(parameter CLK_FREQ = 100000000,
                 parameter BAUD = 9600)

                (input clk,
                 input rst,
                 input rx,

                 output reg [7:0] dout,
                 output reg rx_valid);

    //states 

    localparam IDLE   = 3'd0;
    localparam START  = 3'd1;
    localparam DATA   = 3'd2;
    localparam PARITY = 3'd3;
    localparam STOP   = 3'd4;


   
    // 16x OVERSAMPLING
  

    localparam SAMPLE_VALUE = CLK_FREQ / (BAUD * 16);
  
    // REGISTERS
    
    reg [2:0] p,n;

    reg [15:0] sample_count;

    reg [7:0] data_reg;

    reg [2:0] bit_count;

    reg parity_bit;


        // STATE REGISTER
    
    always @(posedge clk or posedge rst)
    begin
        if(rst)
            p <= IDLE;
        else
            p <= n;
    end

   
    // NEXT STATE LOGIC

    always @(*)
    begin
        case(p)

            
            // IDLE
            

            IDLE:
            begin
                if(rx == 1'b1)
                    n = IDLE;
                else
                    n = START;
            end


            
            // START
           

            START:
            begin
                if(sample_count == SAMPLE_VALUE*8-1)
                begin
                    // Check the middle of START bit

                    if(rx == 1'b0)
                        n = DATA;
                    else
                        n = IDLE;
                end

                else
                    n = START;
            end


          
            // DATA

            DATA:
            begin
                if((sample_count == SAMPLE_VALUE*16-1) &&
                   (bit_count == 3'd7))
                begin
                    n = PARITY;
                end

                else
                    n = DATA;
            end


       
            // PARITY
      

            PARITY:
            begin
                if(sample_count == SAMPLE_VALUE*16-1)
                    n = STOP;
                else
                    n = PARITY;
            end



            // STOP


            STOP:
            begin
                if(sample_count == SAMPLE_VALUE*16-1)
                    n = IDLE;
                else
                    n = STOP;
            end



            // DEFAULT


            default:
            begin
                n = IDLE;
            end

        endcase
    end



    // SAMPLE COUNTER


    always @(posedge clk or posedge rst)
    begin
        if(rst)
            sample_count <= 0;

        else
        begin

            // IDLE
            if(p == IDLE)
            begin
                sample_count <= 0;
            end

            // START
            else if(p == START)
            begin
                if(sample_count == SAMPLE_VALUE*8-1)
                    sample_count <= 0;
                else
                    sample_count <= sample_count + 1'b1;
            end

            // DATA / PARITY / STOP
            else
            begin
                if(sample_count == SAMPLE_VALUE*16-1)
                    sample_count <= 0;
                else
                    sample_count <= sample_count + 1'b1;
            end

        end
    end



    // DATA BIT COUNTER


    always @(posedge clk or posedge rst)
    begin
        if(rst)
            bit_count <= 0;

        else
        begin

            if(p == IDLE)
            begin
                bit_count <= 0;
            end

            else if(p == DATA)
            begin

                if(sample_count == SAMPLE_VALUE*16-1)
                begin

                    if(bit_count < 3'd7)
                        bit_count <= bit_count + 1'b1;
                    else
                        bit_count <= bit_count;

                end

                else
                    bit_count <= bit_count;

            end

            else
                bit_count <= bit_count;

        end
    end



    // RECEIVE DATA AND PARITY


    always @(posedge clk or posedge rst)
    begin
        if(rst)
        begin
            data_reg <= 8'b0;
            parity_bit <= 1'b0;
        end

        else
        begin


            // RECEIVE DATA


            if(p == DATA)
            begin

                if(bit_count == 3'd0)
            begin
                if(sample_count == SAMPLE_VALUE*8-1'b1)
                    data_reg[bit_count] <= rx;
                else
                    data_reg <= data_reg;
            end
            
            else
            begin
                if(sample_count == SAMPLE_VALUE*16-1)
                    data_reg[bit_count] <= rx;
                else
                    data_reg <= data_reg;
            end

            end



            // RECEIVE PARITY


            else if(p == PARITY)
            begin

                if(sample_count == SAMPLE_VALUE*16-1)
                    parity_bit <= rx;
                else
                    parity_bit <= parity_bit;

            end


            else
            begin
                data_reg <= data_reg;
                parity_bit <= parity_bit;
            end

        end
    end



    // OUTPUT DATA + PARITY CHECK + STOP CHECK


    always @(posedge clk or posedge rst)
    begin
        if(rst)
        begin
            dout <= 8'b0;
            rx_valid <= 1'b0;
        end

        else
        begin

            // Default: rx_valid is LOW
            rx_valid <= 1'b0;



            // STOP BIT SAMPLE

            if((p == STOP) &&
               (sample_count == SAMPLE_VALUE*16-1))
            begin

                // Check STOP bit
                if(rx == 1'b1)
                begin

                    // Check EVEN PARITY
                    if(parity_bit == ^data_reg)
                    begin
                        dout <= data_reg;
                        rx_valid <= 1'b1;
                    end

                    else
                    begin
                        dout <= dout;
                        rx_valid <= 1'b0;
                    end
                end

                else
                begin
                    dout <= dout;
                    rx_valid <= 1'b0;
                end

            end

            else
            begin
                dout <= dout;
                rx_valid <= 1'b0;
            end

        end
    end

endmodule
