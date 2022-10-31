module count_10(
    input wire rst, //重置标志
    input wire clk, //时钟
    input wire en,  //开始标志
    output reg [3:0] count,  //4位寄存器   
    output reg co       //进位标志
);
    always @ (posedge clk) begin
        if (rst) begin  //重置，赋0
            count <= 4'b0;
            co <= 1'b0;
        end
        else if (en) begin
            if (count == 4'd8) begin  //当原来count=8时，count=9，co=1 
                count <= 4'd9;
                co <= 1'b1;
            end
            else if(count == 4'd9) begin //9时进位，全为0
                count <=4'b0;
                co <= 1'b0;
            end
            else begin  //  count++
                count <= count + 1'b1;
                co <= 1'b0;
            end
        end
    end
endmodule