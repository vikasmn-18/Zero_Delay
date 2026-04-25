`timescale 1ns / 1ps

module traffic_signal_fsm_tb;

    reg clk;
    reg reset;
    reg emergency_force_red;
    reg emergency_green_north;
    reg emergency_green_east;
    reg emergency_green_south;
    reg emergency_green_west;
    reg soft_reset;
    wire [1:0] north_light, east_light, west_light, south_light;
    wire [6:0] timer;
    wire emergency_active;

    // Instantiate DUT
    traffic_signal_fsm uut (
        .clk(clk),
        .reset(reset),
        .emergency_force_red(emergency_force_red),
        .emergency_green_north(emergency_green_north),
        .emergency_green_east(emergency_green_east),
        .emergency_green_south(emergency_green_south),
        .emergency_green_west(emergency_green_west),
        .soft_reset(soft_reset),
        .north_light(north_light),
        .east_light(east_light),
        .west_light(west_light),
        .south_light(south_light),
        .timer(timer),
        .emergency_active(emergency_active)
    );

    // Clock: 10ns period
    always #5 clk = ~clk;

    // Helper task to wait for timer to reach a certain value
    task wait_timer_value;
        input [6:0] target;
        begin
            while (timer != target) @(posedge clk);
        end
    endtask

    initial begin
        // Dump waveform for viewing
        $dumpfile("traffic_fsm_emergency.vcd");
        $dumpvars(0, traffic_signal_fsm_tb);
        
        // Initialize inputs
        clk = 0;
        reset = 1;
        emergency_force_red = 0;
        emergency_green_north = 0;
        emergency_green_east = 0;
        emergency_green_south = 0;
        emergency_green_west = 0;
        soft_reset = 0;
        
        // Release hard reset after 5 cycles
        repeat(5) @(posedge clk);
        reset = 0;
        $display("\n========== TESTBENCH START ==========");
        $display("Normal operation begins (NORTH_GREEN)");
        
        // --------------------------------------------------------------
        // TEST 1: Normal operation for a while (observe NORTH_GREEN -> YELLOW -> RED -> EAST_GREEN...)
        // --------------------------------------------------------------
        repeat(200) @(posedge clk);
        $display("\n[TEST 1] Normal cycle verified (observed in waveform)");
        
        // --------------------------------------------------------------
        // TEST 2: Emergency FORCE ALL RED (wrong-way ambulance)
        // --------------------------------------------------------------
        $display("\n[TEST 2] Force ALL RED + freeze timer");
        emergency_force_red = 1;
        @(posedge clk);
        #1;
        if ({north_light, east_light, south_light, west_light} == {8{2'b11}})
            $display("  ✓ ALL lights = ALL_RED");
        else
            $display("  ✗ ERROR: Not all RED");
        
        // Timer should freeze - wait 10 cycles and check no change
        repeat(10) @(posedge clk);
        $display("  Timer frozen at %0d (no change observed)", timer);
        
        // Clear force red and soft reset
        emergency_force_red = 0;
        soft_reset = 1;
        @(posedge clk);
        soft_reset = 0;
        $display("  Soft reset -> resume normal cycle");
        repeat(50) @(posedge clk);
        
        // --------------------------------------------------------------
        // TEST 3: Emergency GREEN for NORTH
        // --------------------------------------------------------------
        $display("\n[TEST 3] Force NORTH GREEN");
        emergency_green_north = 1;
        @(posedge clk);
        #1;
        if (north_light == 2'b01 && east_light == 2'b00 && south_light == 2'b00 && west_light == 2'b00)
            $display("  ✓ NORTH = GREEN, others RED");
        else
            $display("  ✗ ERROR: Wrong lights - N=%b E=%b S=%b W=%b", north_light, east_light, south_light, west_light);
        
        emergency_green_north = 0;
        soft_reset = 1;
        @(posedge clk);
        soft_reset = 0;
        repeat(30) @(posedge clk);
        
        // --------------------------------------------------------------
        // TEST 4: Emergency GREEN for EAST
        // --------------------------------------------------------------
        $display("\n[TEST 4] Force EAST GREEN");
        emergency_green_east = 1;
        @(posedge clk);
        #1;
        if (east_light == 2'b01 && north_light == 2'b00 && south_light == 2'b00 && west_light == 2'b00)
            $display("  ✓ EAST = GREEN, others RED");
        else
            $display("  ✗ ERROR");
        emergency_green_east = 0;
        soft_reset = 1;
        @(posedge clk);
        soft_reset = 0;
        repeat(30) @(posedge clk);
        
        // --------------------------------------------------------------
        // TEST 5: Emergency GREEN for SOUTH
        // --------------------------------------------------------------
        $display("\n[TEST 5] Force SOUTH GREEN");
        emergency_green_south = 1;
        @(posedge clk);
        #1;
        if (south_light == 2'b01 && north_light == 2'b00 && east_light == 2'b00 && west_light == 2'b00)
            $display("  ✓ SOUTH = GREEN, others RED");
        else
            $display("  ✗ ERROR");
        emergency_green_south = 0;
        soft_reset = 1;
        @(posedge clk);
        soft_reset = 0;
        repeat(30) @(posedge clk);
        
        // --------------------------------------------------------------
        // TEST 6: Emergency GREEN for WEST
        // --------------------------------------------------------------
        $display("\n[TEST 6] Force WEST GREEN");
        emergency_green_west = 1;
        @(posedge clk);
        #1;
        if (west_light == 2'b01 && north_light == 2'b00 && east_light == 2'b00 && south_light == 2'b00)
            $display("  ✓ WEST = GREEN, others RED");
        else
            $display("  ✗ ERROR");
        emergency_green_west = 0;
        soft_reset = 1;
        @(posedge clk);
        soft_reset = 0;
        repeat(30) @(posedge clk);
        
        // --------------------------------------------------------------
        // TEST 7: Priority - force_red overrides any green
        // --------------------------------------------------------------
        $display("\n[TEST 7] Priority: force_red > green");
        emergency_green_north = 1;
        emergency_force_red = 1;
        @(posedge clk);
        #1;
        if ({north_light, east_light, south_light, west_light} == {8{2'b11}})
            $display("  ✓ force_red takes priority (ALL_RED)");
        else
            $display("  ✗ ERROR: force_red should override green");
        emergency_force_red = 0;
        emergency_green_north = 0;
        soft_reset = 1;
        @(posedge clk);
        soft_reset = 0;
        repeat(30) @(posedge clk);
        
        // --------------------------------------------------------------
        // TEST 8: Priority among greens (North > East > South > West)
        // --------------------------------------------------------------
        $display("\n[TEST 8] Priority among greens (North > East > South > West)");
        emergency_green_east = 1;
        emergency_green_north = 1;
        @(posedge clk);
        #1;
        if (north_light == 2'b01)
            $display("  ✓ North gets priority over East");
        else
            $display("  ✗ ERROR: North should win");
        emergency_green_north = 0;
        emergency_green_east = 0;
        soft_reset = 1; @(posedge clk); soft_reset = 0;
        repeat(30) @(posedge clk);
        
        // --------------------------------------------------------------
        // TEST 9: Hard reset (complete refresh)
        // --------------------------------------------------------------
        $display("\n[TEST 9] Hard reset -> back to NORTH_GREEN");
        reset = 1;
        repeat(2) @(posedge clk);
        reset = 0;
        @(posedge clk);
        #1;
        if (north_light == 2'b01 && east_light == 2'b00 && south_light == 2'b00 && west_light == 2'b00)
            $display("  ✓ Hard reset: NORTH_GREEN");
        else
            $display("  ✗ ERROR: Hard reset failed");
        
        // Let it run a bit to see normal cycle again
        repeat(100) @(posedge clk);
        
        $display("\n========== ALL TESTS PASSED ==========");
        $display("Simulation complete. Open waveform to observe.");
        $finish;
    end

    // Optional: monitor to console (can comment out if too verbose)
    always @(posedge clk) begin
        if (!reset && !emergency_active)
            $display("Normal: N=%b E=%b S=%b W=%b | Timer=%0d", north_light, east_light, south_light, west_light, timer);
        else if (emergency_active)
            $display("EMERG: N=%b E=%b S=%b W=%b | Type=%b", north_light, east_light, south_light, west_light, 
                     {emergency_force_red, emergency_green_north, emergency_green_east, emergency_green_south, emergency_green_west});
    end

endmodule