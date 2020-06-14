// yusme pradera
// TB for T Bird Tail Lights
//




module TestBench;
reg Left, Right, Hazard, Clear, Clock;
wire LA,LB,LC,RA,RB,RC;


parameter TRUE   = 1'b1;
parameter FALSE  = 1'b0;
parameter CLOCK_CYCLE  = 20;
parameter CLOCK_WIDTH  = CLOCK_CYCLE/2;
parameter IDLE_CLOCKS  = 2;



TBirdTailLights TFSM(Clock, Clear, Left, Right, Hazard, LA, LB, LC, RA, RB, RC);

//
// set up monitor
//

initial
begin
$display("                Time Clear Left Right Hazard  LA LB LC RA RB RC\n");
$monitor($time, "   %b    %b    %b     %b       %b  %b  %b  %b  %b  %b",Clear,Left,Right,Hazard,LA,LB,LC,RA,RB,RC);
end



//
// Create free running clock
//

initial
begin
Clock = FALSE;
forever #CLOCK_WIDTH Clock = ~Clock;
end


//
// Generate Clear signal for two cycles
//

initial
begin
Clear = TRUE;
repeat (IDLE_CLOCKS) @(negedge Clock);
Clear = FALSE;
end




//
// Generate stimulus after waiting for reset
//

initial
begin

repeat (6) @(negedge Clock); {Left,Right,Hazard} = 3'b100;   // simple Left, Right, Hazard tests
repeat (6) @(negedge Clock); {Left,Right,Hazard} = 3'b000;
repeat (6) @(negedge Clock); {Left,Right,Hazard} = 3'b010;
repeat (6) @(negedge Clock); {Left,Right,Hazard} = 3'b000;
repeat (6) @(negedge Clock); {Left,Right,Hazard} = 3'b001;
repeat (6) @(negedge Clock); {Left,Right,Hazard} = 3'b000;

repeat (6) @(negedge Clock); {Left,Right,Hazard} = 3'b100;   // initiate Left then interrupt with Hazard
repeat (1) @(negedge Clock); {Left,Right,Hazard} = 3'b101;   // after one cycle
repeat (6) @(negedge Clock); {Left,Right,Hazard} = 3'b000;

repeat (6) @(negedge Clock); {Left,Right,Hazard} = 3'b010;   // initiate Right then interrupt with Hazard
repeat (1) @(negedge Clock); {Left,Right,Hazard} = 3'b011;   // after one cycle
repeat (6) @(negedge Clock); {Left,Right,Hazard} = 3'b000;

repeat (6) @(negedge Clock); {Left,Right,Hazard} = 3'b100;   // initiate Left then interrupt with Hazard
repeat (2) @(negedge Clock); {Left,Right,Hazard} = 3'b101;   // after two cycles
repeat (6) @(negedge Clock); {Left,Right,Hazard} = 3'b000;

repeat (6) @(negedge Clock); {Left,Right,Hazard} = 3'b010;   // initiate Right then interrupt with Hazard
repeat (2) @(negedge Clock); {Left,Right,Hazard} = 3'b011;   // after two cycles
repeat (6) @(negedge Clock); {Left,Right,Hazard} = 3'b000;

repeat (6) @(negedge Clock); {Left,Right,Hazard} = 3'b100;   // initiate Left then interrupt with Hazard
repeat (3) @(negedge Clock); {Left,Right,Hazard} = 3'b101;   // after three cycles
repeat (6) @(negedge Clock); {Left,Right,Hazard} = 3'b000;

repeat (6) @(negedge Clock); {Left,Right,Hazard} = 3'b010;   // initiate Right then interrupt with Hazard
repeat (3) @(negedge Clock); {Left,Right,Hazard} = 3'b011;   // after three cycles
repeat (6) @(negedge Clock); {Left,Right,Hazard} = 3'b000;
repeat (6) @(negedge Clock);
$stop;
end


endmodule

