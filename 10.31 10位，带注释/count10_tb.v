module count10_tb(

    );
    reg rst;
    reg clk;
    reg en;
    wire [3:0] count;
    wire co;
    initial begin
        rst = 0;
        clk = 0;
        en = 0;
        #100 //延时100ns
        rst = 1;
        #40//延时40ns
        rst = 0;
        en = 1;
    end
    
    always #10 clk = ~clk;  //20ns一周期，10ns转变高低电压
    count_10 count10(rst,clk,en,count,co);    
endmodule
