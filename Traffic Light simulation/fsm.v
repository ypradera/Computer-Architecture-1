// yusme Pradera
// 
// (Traffic Light)

module fsm(Clock, Reset, S1, S2, S3, L1, L2, L3);
//Input and output assignments
input Clock;
input Reset;
input 			// sensors for approaching vehicles
S1, 			// Northbound on SW 4th Avenue
S2,		 	// Eastbound on SW Harrison Street
S3; 			// Westbound on SW Harrison Street

output reg [1:0]	// outputs for controlling traffic lights
L1, 			// light for NB SW 4th Avenue
L2, 			// light for EB SW Harrison Street
L3; 			// light for WB SW Harrison Street

// Initialize counter
counter_timer1(
		.clk(Clock),
		.reset(Reset),
		.value(value)
		.load(load),
		.decr(decr),
		.timeup(timeup),
		);

//Traffic Lights counter
TrafficLights(
				.Clock(Clock),
				.reset(Reset), 
				.S1(S1), 
				.S2(S2), 
				.S3(S3), 
				.L1(L1), 
				.L2(L2), 
				.L3(L3),
				.value(value), 
				.load(load), 
				.decr(decr), 
				.timeup(timeup));

endmodule



//Real fsm 
module realfsm(Clock, Reset, S1, S2, S3, L1, L2, L3, load, decr, value, timeup);
input Clock, Reset;
input 			// sensors to detect vehicles
S1,			// sensor located North SW 4th Avenue
S2,			// sensor located East SW Harrison st
S3;			// sensor located West SW Harrison st

output reg [1:0]	// outputs for controlling traffic lights
L1, 			// light located North SW 4th Avenue
L2, 			// light located East SW Harrison Street
L3; 			// light located West SW Harrison Street

output reg [7:0]  value;	// value to set timer duration	
wire load, decr;		// wires needed to control the counter

//Define states using one-hot encoding where only 1 bit of the state vector is asserted for any given state
parameter
	F_SAFE	= 6'b000001,	// Fail safe mode in case something goes bad
	ALL_RED	= 6'b000010,	// Case when all the lights are red	
	North_G	= 6'b000100,	// Case when the light on SW 4th ave is Green
	North_Y	= 6'b001000,	// Case when the light on SW 4th ave is Yellow 
	Side_G	= 6'b010000,	// Case when East and West on SW Harrison st is Green
	Side_Y	= 6'b100000;	// Case when East and West on SW Harrison st is Yellow

// Each traffic light its controlled with two inputs

parameter
	FLASH 	  = 2'b00, 
	GREEN	  = 2'b01,
	YELLOW	  = 2'b10,
	RED	  = 2'b11,

// Different times needed
North_G_T = 6'b101101, 		// SW 4th ave gets 45s of Green light
RED_T  	  = 6'b000001,		// All the red lights must be on for 1 second before transitioning
Yellow_T  = 6'b000101,		// All yellow lights must be on for 5 s
Side_G_T  = 6'b001111;		// Light on SW Harrison st gets 15s on green

reg [5:0] State, NextState;

//Update state or reset on every positive Clock edge

always @(posedge Clock, posedge Reset)
begin
	if(Reset) 
	begin
		State = F_SAFE; 		//Fail_SAfe mode in case of problems
		value = 1'b1;			
		load = 1'b1;			// Load bit to 1 to value to assert timer
	end

	else
	begin
		load = 1'b0;		// Load bit 0 to value
		if(timeup)		// If timeup is less than or equal to bit 0
			decr <= 1'b0;
		State <= NextState;	// Go to the next State
	end
end
// The Outputs depend only upon the state since its a moore machine
always @(State)
begin
case(State)
		F_SAFE:	
		begin		//Fail Safe Mode
			L1 = FLASH;			
			L2 = FLASH;
			L3 = FLASH;
		end

		ALL_RED: 
		begin		// When all the lights are in red
			L1 = RED;			
			L2 = RED;
			L3 = RED;
		end

		North_G: 
		begin		// When SW 4th ave light is green and SW Harrison st is RED				
			L1 = GREEN;
			L2 = RED;
			L3 = RED;
		end


		North_Y: 
		begin		// When SW 4th ave light is yellow and SW Harrison st still red
			L1 = YELLOW;			
			L2 = RED;
			L3 = RED;
		end


		Side_G:
		begin		//WHen SW 4th ave light is red and SW Harrison st is green
			L1 = RED;			
			L2 = GREEN;
			L3 = GREEN;
		end

		Side_Y: 
		begin		//WHen SW 4th ave light is red and SW Harrison st is yellow
			L1 = RED;			
			L2 = YELLOW;
			L3 = YELLOW;
		end
		
	endcase
end


always @(State or NextState)				
begin
case(State)
	
	ALL_RED: 
	begin
		if(S1 && timeup)			//In this case SW 4th ave has priority
			begin
				value = North_G_T;	// Load the value for the green light on SW 4th ave (45s)
				load = 1'b1;		//Load bit 1
				NextState = North_G;	//When timer is done change State
			end
				

		else
			begin
				decr <= 1'b1;		// Load decrement bit for the timer
				NextState = ALL_RED;	// RED light until car shows up
			end
	end
	 
		North_G:	
		begin
			if(timeup && ~S2 && ~S3 && S1)	// Case where there is still traffic in SW 4th ave, NO traffic in SW harrison
				begin	
					load = 1'b1; 		// Load bit 1 to reload the timer value
					NextState = North_G;
				end
			
			else if(timeup && ~S1 && (S2 || S3)) 	//If there is no traffic on SW 4th ave but there is traffic on SW Harrison st switch light to yellow				begin
				value = Yellow_T;		// Load the timer value for Yellow for SW Harrison st (15s)
				load = 1'b1;			
				NextState = North_Y;		// Go to next state YELLOW
			
			else
				begin
					decr <= 1b'1;			//Load the bit to decrement
					NextState = North_G;		// Cycle in present state
				end
		end


		North_Y:	
		begin
			if(timeup) 	
					begin
						value = RED_T;		//Load value for 1s counter time				load = 1'b1;
						load = 1'b1;		// Load assertion bit
						NextState = Side_G;	// Change to next State, green on SW Harrison st
					end
	
				else
					begin
						decr <= 1'b1;
						NextState = North_Y;	//Otherwise proceed to next State
					end
		end


		Side_G:	
		begin
			if(timeup)	 			
				begin
					value = Yellow_T;	//load yellow light timer value
					load = 1'b1;		// load assertion bit 1
					NextState = Side_Y;	// Go to next State Yellow
				end
			
			else
				begin
					decr <= 1'b1;
					NextState = Side_G;	
				end

		Side_Y:	
		begin
			if(timeup)
			begin
				value = RED_T;			// Load the 1s timer
				load = 1'b1;     		// load assertive bit 1
				NextState = ALL_RED;
			end
		else
			begin
			NextState = Side_Y;
			end 
		end
	endcase
end

endmodule
