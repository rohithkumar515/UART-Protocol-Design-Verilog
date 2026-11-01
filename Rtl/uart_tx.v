module uart_tx #(parameter CLK_FREQ=100000000,
                       parameter BAUD=9600)//declaring of clock frequency and baud rate
                       
            (input clk,rst,start,
             input [7:0]din,
             output reg tx,busy);
             
             //declaring the states
             localparam IDLE=0;
             localparam START=1;
             localparam DATA=2;
             localparam PARITY=3;
             localparam STOP=4;
       
       reg[2:0]p,n;      
       reg[7:0]data_reg;
       reg[2:0]bit_count;
       reg[13:0]baud_count;
       reg parity_bit;
       
       localparam BAUD_VALUE=CLK_FREQ/BAUD;//calculating the baud value 
       
       //changing the next state to present state
       always @(posedge clk or posedge rst)
       begin
       if(rst)
       p<=IDLE;
       else
       p<=n;
       end
       
       //sequincing the states
       always @(*)
       begin
            case(p)
                
                IDLE: if(start)
                      n=START;
                      else
                      n=IDLE;
                      
                START: if(baud_count==BAUD_VALUE-1'b1)
                       n=DATA;
                       else
                       n=START;
                       
                DATA: if((baud_count==BAUD_VALUE-1'b1)&&(bit_count==3'd7))
                      n=PARITY;
                      else
                      n=DATA;
                      
               PARITY: if(baud_count==BAUD_VALUE-1'b1)
                       n=STOP;
                       else
                       n=PARITY;
                       
               STOP: if(baud_count==BAUD_VALUE-1'b1)
                     n=IDLE;
                     else
                     n=STOP;
                     
               default: n= IDLE;
            endcase
       end
       
       
       //storing the input data
       always @(posedge clk or posedge rst)
       begin
            if(rst)
            begin
            data_reg<=0;
            parity_bit<=0;
            end
            else
            begin
                if(p==IDLE && start)
                begin
                data_reg<=din;
                parity_bit<=^din;
                end
                else
                begin
                data_reg<=data_reg;
                parity_bit<=parity_bit;
                end
            end
       end
       
       //baud count
       always @(posedge clk or posedge rst)
       begin
            if(rst)
            baud_count<=0;
            else
            begin
                if(p==IDLE)
                baud_count<=0;
                else
                begin
                    if(baud_count==BAUD_VALUE-1'b1)
                    baud_count<=0;
                    else
                    baud_count<=baud_count+1'b1;
                end
            end
       end
       
       
       //data bit count
       always @(posedge clk or posedge rst)
       begin
            if(rst)
            bit_count<=0;
            else
            begin
                if(p==IDLE)
                bit_count<=0;
                else if(p==DATA)
                begin
                    if(baud_count==BAUD_VALUE-1'b1)
                     begin
                        if(bit_count<3'd7)
                        bit_count<=bit_count+1'b1;
                        else
                        bit_count<=bit_count;
                     end
                     else
                     bit_count<=bit_count;    
                end
                else
                bit_count<=bit_count;
            end
       end
       
       //ouput logic
       always @(*)
       begin
            case(p)
                IDLE:
                begin
                tx=1'b1; busy=1'b0;
                end
                
                START:
                begin
                tx=1'b0; busy=1'b1;
                end
                
                DATA:
                begin
                tx= data_reg[bit_count]; busy=1'b1;
                end
                
                PARITY:
                begin
                tx=parity_bit; busy=1'b1;
                end
                
                STOP:
                begin
                tx=1'b1; busy=1'b1;
                
                end
            endcase
       end

endmodule
