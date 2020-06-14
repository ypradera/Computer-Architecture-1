// yusme Pradera
// Test bench for traffic lights
module top;
	reg Reset,Clock;
	reg  // sensors for approaching vehicles
		S1, // Northbound on SW 4th Avenue
		S2, // Eastbound on SW Harrison Street
		S3; // Westbound on SW Harrison Street
wire [1:0] // outputs for controlling traffic lights
		L1, // light for NB SW 4th Avenue
		L2, // light for EB SW Harrison Street
		L3; // light for WB SW Harrison Street

	
	
parameter TRUE   = 1'b1;
parameter FALSE  = 1'b0;
parameter CLOCK_TIMES  = 20;
parameter CLOCK_WIDTH  = CLOCK_TIMES/2;
parameter IDLE_CLOCKS  = 2;

TrafficLights TFSM(S1,S2,S3,Reset,Clock,L1,L2,L3);

// Set up monitor 
initial
begin
	$display("               Time Clock Reset  S1  S2  S3  L1   L2   L3 ");
	$monitor($time, "  %b     %b     %b      %b     %b    %b    %b        %b ",Clock,Reset,S1,S2,S3,L1,L2,L3);
end 
//Create free running clock
initial
begin
	Clock = FALSE;
	forever #CLOCK_WIDTH Clock = ~Clock;
end

// Generate Reset signal 

initial
begin
	Reset = TRUE;
	repeat (IDLE_CLOCKS) @(negedge Clock);
	Reset = FALSE;
end

// Generate stimulus after waiting for reset
initial
begin
{Reset} = 1'b0;repeat (2) @(negedge Clock); 
{Reset} = 1'b1;repeat (2) @(negedge Clock);

repeat (2) @(negedge Clock); {S1,S2,S3} = 3'b000;	
repeat (2) @(negedge Clock); {S1,S2,S3} = 3'b001;	
repeat (2) @(negedge Clock); {S1,S2,S3} = 3'b010; 	
repeat (2) @(negedge Clock); {S1,S2,S3} = 3'b011;	
repeat (2) @(negedge Clock); {S1,S2,S3} = 3'b100;	
repeat (2) @(negedge Clock); {S1,S2,S3} = 3'b101;	
repeat (2) @(negedge Clock); {S1,S2,S3} = 3'b110; 
repeat (2) @(negedge Clock); {S1,S2,S3} = 3'b111; 
repeat (2) @(negedge Clock);
$stop;
end
endmodule
