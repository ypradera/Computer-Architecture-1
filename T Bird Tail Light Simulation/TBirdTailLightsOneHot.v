// yusme pradera
// T Bird Tail Light FSM
//



module TBirdTailLights(Clock, Clear, Left, Right, Hazard, LA, LB, LC, RA, RB, RC);
input Clock, Clear, Left, Right, Hazard;
output LA,LB,LC,RA,RB,RC;
reg LA,LB,LC,RA,RB,RC;


parameter ON  = 1'b1;
parameter OFF = 1'b0;

// define states using same names and state assignments as state diagram and table
// Using one-hot method, we have one bit per state

parameter
	IDLE  = 8'b00000001,
	L1    = 8'b00000010,
	L2    = 8'b00000100,
	L3    = 8'b00001000,
	R1    = 8'b00010000,
	R2    = 8'b00100000,
	R3    = 8'b01000000,
	LR3   = 8'b10000000;


reg [7:0] State, NextState;


//
// Update state or reset on every + clock edge
//

always @(posedge Clock)
begin
if (Clear)
	State <= IDLE;
else
	State <= NextState;
end



//
// Outputs depend only upon state (Moore machine)
//

always @(State)
begin
case (State)
	IDLE:	begin
		LA = OFF;
		LB = OFF;
		LC = OFF;
		RA = OFF;
		RB = OFF;
		RC = OFF;
		end

	L1:	begin
		LA = ON;
		LB = OFF;
		LC = OFF;
		RA = OFF;
		RB = OFF;
		RC = OFF;
		end

	L2:	begin
		LA = ON;
		LB = ON;
		LC = OFF;
		RA = OFF;
		RB = OFF;
		RC = OFF;
		end

	L3:	begin
		LA = ON;
		LB = ON;
		LC = ON;
		RA = OFF;
		RB = OFF;
		RC = OFF;
		end

	R1:	begin
		LA = OFF;
		LB = OFF;
		LC = OFF;
		RA = ON;
		RB = OFF;
		RC = OFF;
		end

	R2:	begin
		LA = OFF;
		LB = OFF;
		LC = OFF;
		RA = ON;
		RB = ON;
		RC = OFF;
		end

	R3:	begin
		LA = OFF;
		LB = OFF;
		LC = OFF;
		RA = ON;
		RB = ON;
		RC = ON;
		end

	LR3:	begin
		LA = ON;
		LB = ON;
		LC = ON;
		RA = ON;
		RB = ON;
		RC = ON;
		end

endcase
end



//
// Next state generation logic
//

always @(State or Left or Right or Hazard)
begin
case (State)
	IDLE:	begin
		if (Hazard || Left && Right)
			NextState = LR3;
		else if (Left)
			NextState = L1;
		else if (Right)
			NextState = R1;
		else
			NextState = IDLE;
		end

	L1:	begin
		if (Hazard)
			NextState = LR3;
		else
			NextState = L2;
		end

	L2:	begin
		if (Hazard)
			NextState = LR3;
		else
			NextState = L3;
		end

	L3:	begin
		NextState = IDLE;
		end

	R1:	begin
		if (Hazard)
			NextState = LR3;
		else
			NextState = R2;
		end

	R2:	begin
		if (Hazard)
			NextState = LR3;
		else
			NextState = R3;
		end

	R3:	begin
		NextState = IDLE;
		end

	LR3:	begin
		NextState = IDLE;
		end
endcase
end


endmodule

