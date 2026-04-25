module traffic_signal_fsm (
    input clk,
    input reset,                     // Hard reset → NORTH_GREEN
    input emergency_force_red,       // Force ALL RED + freeze timer (wrong-way ambulance)
    input emergency_green_north,     // Force NORTH GREEN
    input emergency_green_east,      // Force EAST GREEN
    input emergency_green_south,     // Force SOUTH GREEN
    input emergency_green_west,      // Force WEST GREEN
    input soft_reset,                // Resume from stored state after emergency
    output reg [1:0] north_light,
    output reg [1:0] east_light,
    output reg [1:0] west_light,
    output reg [1:0] south_light,
    output reg [6:0] timer,
    output reg emergency_active      // Indicates emergency mode is active
);

// Light encodings
parameter GREEN   = 2'b01;
parameter YELLOW  = 2'b10;
parameter RED     = 2'b00;
parameter ALL_RED = 2'b11;   // Pedestrian crossing

// FSM states (12 states: 4 directions × 3 phases)
parameter NORTH_GREEN  = 4'd0;
parameter NORTH_YELLOW = 4'd1;
parameter NORTH_RED    = 4'd2;   // ALL_RED pedestrian
parameter EAST_GREEN   = 4'd3;
parameter EAST_YELLOW  = 4'd4;
parameter EAST_RED     = 4'd5;   // ALL_RED pedestrian
parameter SOUTH_GREEN  = 4'd6;
parameter SOUTH_YELLOW = 4'd7;
parameter SOUTH_RED    = 4'd8;   // ALL_RED pedestrian
parameter WEST_GREEN   = 4'd9;
parameter WEST_YELLOW  = 4'd10;
parameter WEST_RED     = 4'd11;  // ALL_RED pedestrian

reg [3:0] current_state, next_state;
reg [6:0] count;
reg [6:0] count_next;

// Emergency storage registers
reg        emergency_mode;
reg [2:0]  emergency_type;        // 0=force_red, 1=north_green, 2=east_green, 3=south_green, 4=west_green
reg [3:0]  stored_state;
reg [6:0]  stored_count;
reg [6:0]  stored_count_next;

// Emergency priority: force_red > north > east > south > west
wire any_emergency = emergency_force_red || emergency_green_north || emergency_green_east ||
                     emergency_green_south || emergency_green_west;

always @(posedge clk or posedge reset) begin
    if (reset) begin  // HARD RESET - complete refresh
        current_state <= NORTH_GREEN;
        count <= 7'd0;
        emergency_mode <= 1'b0;
        stored_state <= NORTH_GREEN;
        stored_count <= 7'd0;
        stored_count_next <= 7'd0;
        emergency_type <= 3'd0;
    end else begin
        if (!emergency_mode && any_emergency) begin
            // ENTER EMERGENCY MODE - store current state and freeze everything
            emergency_mode <= 1'b1;
            stored_state <= current_state;
            stored_count <= count;
            stored_count_next <= count_next;
            
            // Determine emergency type (priority: force_red > north > east > south > west)
            if (emergency_force_red)
                emergency_type <= 3'd0;
            else if (emergency_green_north)
                emergency_type <= 3'd1;
            else if (emergency_green_east)
                emergency_type <= 3'd2;
            else if (emergency_green_south)
                emergency_type <= 3'd3;
            else if (emergency_green_west)
                emergency_type <= 3'd4;
            else
                emergency_type <= 3'd0;
        end
        else if (soft_reset && emergency_mode) begin
            // SOFT RESET - resume from stored state
            emergency_mode <= 1'b0;
            current_state <= stored_state;
            count <= stored_count;
            // next_state will be recomputed in combinational block
        end
        else if (!emergency_mode) begin
            // NORMAL OPERATION (your original FSM)
            current_state <= next_state;
            if (count == 7'd0)
                count <= count_next;
            else
                count <= count - 1;
        end
        // else: emergency_mode active - do nothing (timer frozen, no state change)
    end
end

always @(*) begin
    // Default outputs
    north_light = RED;
    east_light  = RED;
    west_light  = RED;
    south_light = RED;
    next_state  = current_state;
    count_next  = 7'd0;
    timer       = count;
    emergency_active = emergency_mode;

    if (emergency_mode) begin
        // EMERGENCY OVERRIDE - outputs depend on emergency_type
        case (emergency_type)
            3'd0: begin  // Force ALL RED (wrong-way ambulance)
                north_light = ALL_RED;
                east_light  = ALL_RED;
                south_light = ALL_RED;
                west_light  = ALL_RED;
                // count_next not used, timer frozen
            end
            3'd1: begin  // Force NORTH GREEN
                north_light = GREEN;
                east_light  = RED;
                south_light = RED;
                west_light  = RED;
            end
            3'd2: begin  // Force EAST GREEN
                north_light = RED;
                east_light  = GREEN;
                south_light = RED;
                west_light  = RED;
            end
            3'd3: begin  // Force SOUTH GREEN
                north_light = RED;
                east_light  = RED;
                south_light = GREEN;
                west_light  = RED;
            end
            3'd4: begin  // Force WEST GREEN
                north_light = RED;
                east_light  = RED;
                south_light = RED;
                west_light  = GREEN;
            end
            default: begin
                north_light = ALL_RED;
                east_light  = ALL_RED;
                south_light = ALL_RED;
                west_light  = ALL_RED;
            end
        endcase
    end else begin
        // NORMAL FSM OPERATION - exactly as you wrote
        case (current_state)
            NORTH_GREEN: begin
                north_light = GREEN;
                count_next = 7'd20;
                if (count == 7'd0) next_state = NORTH_YELLOW;
            end
            NORTH_YELLOW: begin
                north_light = YELLOW;
                count_next = 7'd5;
                if (count == 7'd0) next_state = NORTH_RED;
            end
            NORTH_RED: begin
                north_light = ALL_RED;
                east_light  = ALL_RED;
                west_light  = ALL_RED;
                south_light = ALL_RED;
                count_next = 7'd85;
                if (count == 7'd0) next_state = EAST_GREEN;
            end
            EAST_GREEN: begin
                east_light = GREEN;
                count_next = 7'd20;
                if (count == 7'd0) next_state = EAST_YELLOW;
            end
            EAST_YELLOW: begin
                east_light = YELLOW;
                count_next = 7'd5;
                if (count == 7'd0) next_state = EAST_RED;
            end
            EAST_RED: begin
                north_light = ALL_RED;
                east_light  = ALL_RED;
                west_light  = ALL_RED;
                south_light = ALL_RED;
                count_next = 7'd85;
                if (count == 7'd0) next_state = SOUTH_GREEN;
            end
            SOUTH_GREEN: begin
                south_light = GREEN;
                count_next = 7'd20;
                if (count == 7'd0) next_state = SOUTH_YELLOW;
            end
            SOUTH_YELLOW: begin
                south_light = YELLOW;
                count_next = 7'd5;
                if (count == 7'd0) next_state = SOUTH_RED;
            end
            SOUTH_RED: begin
                north_light = ALL_RED;
                east_light  = ALL_RED;
                west_light  = ALL_RED;
                south_light = ALL_RED;
                count_next = 7'd85;
                if (count == 7'd0) next_state = WEST_GREEN;
            end
            WEST_GREEN: begin
                west_light = GREEN;
                count_next = 7'd20;
                if (count == 7'd0) next_state = WEST_YELLOW;
            end
            WEST_YELLOW: begin
                west_light = YELLOW;
                count_next = 7'd5;
                if (count == 7'd0) next_state = WEST_RED;
            end
            WEST_RED: begin
                north_light = ALL_RED;
                east_light  = ALL_RED;
                west_light  = ALL_RED;
                south_light = ALL_RED;
                count_next = 7'd85;
                if (count == 7'd0) next_state = NORTH_GREEN;
            end
            default: begin
                north_light = ALL_RED;
                east_light  = ALL_RED;
                west_light  = ALL_RED;
                south_light = ALL_RED;
                count_next = 7'd85;
                next_state = NORTH_GREEN;
            end
        endcase
    end
end

endmodule