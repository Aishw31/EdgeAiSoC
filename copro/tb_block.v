`timescale 1ns / 1ns

module block_tb;
    
    // Parameters
    parameter WIDTH = 16;
    parameter PERIOD = 10;  // Clock period in ns
    
    // Testbench signals
    reg clk;
    reg rst;
    reg [WIDTH-1:0] inp_north;
    reg [WIDTH-1:0] inp_west;
    wire [WIDTH-1:0] outp_south;
    wire [WIDTH-1:0] outp_east;
    wire [WIDTH*2-1:0] result;
    
    // Instantiate the DUT (Device Under Test)
    block #(.WIDTH(WIDTH)) dut (
        .clk(clk),
        .rst(rst),
        .inp_north(inp_north),
        .inp_west(inp_west),
        .outp_south(outp_south),
        .outp_east(outp_east),
        .result(result)
    );
    
    // Clock generation
    initial begin
        clk = 0;
        forever #(PERIOD/2) clk = ~clk;
    end
    
    // Test stimulus
    initial begin
        // Initialize inputs
        rst = 0;
        inp_north = 0;
        inp_west = 0;
        
        // Test case 1: Reset condition
        $display("Test 1: Reset condition");
        #(PERIOD) rst = 1;
        #(PERIOD) rst = 0;
        check_outputs(0, 0, 0, "Reset");
        
        // Test case 2: Single multiplication
        $display("\nTest 2: Single multiplication");
        inp_north = 5;
        inp_west = 3;
        #(PERIOD);
        check_outputs(5, 3, 15, "Single multiplication");
        
        // Test case 3: Accumulation
        $display("\nTest 3: Accumulation");
        inp_north = 2;
        inp_west = 4;
        #(PERIOD);
        check_outputs(2, 4, 23, "Accumulation 1"); // 15 + 8 = 23
        inp_north = 3;
        inp_west = 5;
        #(PERIOD);
        check_outputs(3, 5, 38, "Accumulation 2"); // 23 + 15 = 38
        
        // Test case 4: Maximum values
        $display("\nTest 4: Maximum values");
        inp_north = {WIDTH{1'b1}};  // 2^16-1
        inp_west = {WIDTH{1'b1}};
        #(PERIOD);
        check_outputs({WIDTH{1'b1}}, {WIDTH{1'b1}}, 38 + 32'hffff_ffff, "Max values");
        
        // Test case 5: Zero multiplication
        $display("\nTest 5: Zero multiplication");
        inp_north = 0;
        inp_west = 10;
        #(PERIOD);
        check_outputs(0, 10, 38 + 32'hffff_ffff, "Zero multiplication");
        
        // Test case 6: Reset during operation
        $display("\nTest 6: Reset during operation");
        inp_north = 7;
        inp_west = 8;
        #(PERIOD/2) rst = 1;
        #(PERIOD) rst = 0;
        check_outputs(0, 0, 0, "Reset during operation");
        
        // Test case 7: Negative numbers (since WIDTH=16 is signed)
        $display("\nTest 7: Negative numbers");
        inp_north = -5;    // 16'hfffb
        inp_west = -3;     // 16'hfffd
        #(PERIOD);
        check_outputs(-5, -3, 15, "Negative numbers");
        
        // Finish simulation
        #(PERIOD*2);
        $display("\nTestbench completed!");
        $finish;
    end
    
    // Task to check outputs and display results
    task check_outputs;
        input [WIDTH-1:0] exp_south;
        input [WIDTH-1:0] exp_east;
        input [WIDTH*2-1:0] exp_result;
        input string test_name;
        begin
            #(PERIOD/4);  // Wait for signals to settle
            $display("Time=%0t: %s", $time, test_name);
            $display("  inp_north = %d, inp_west = %d", $signed(inp_north), $signed(inp_west));
            $display("  outp_south = %d, expected = %d", $signed(outp_south), $signed(exp_south));
            $display("  outp_east  = %d, expected = %d", $signed(outp_east), $signed(exp_east));
            $display("  result     = %d, expected = %d", $signed(result), $signed(exp_result));
            
            if (outp_south !== exp_south)
                $display("  ERROR: outp_south mismatch!");
            if (outp_east !== exp_east)
                $display("  ERROR: outp_east mismatch!");
            if (result !== exp_result)
                $display("  ERROR: result mismatch!");
            $display("------------------------");
        end
    endtask
    
    // Monitor signals
    initial begin
        $monitor("Time=%0t: rst=%b, inp_north=%d, inp_west=%d, outp_south=%d, outp_east=%d, result=%d",
                 $time, rst, $signed(inp_north), $signed(inp_west), 
                 $signed(outp_south), $signed(outp_east), $signed(result));
    end
    
endmodule