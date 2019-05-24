module regfile #(
  parameter N=8, //Width of registers
  parameter M=8, //Number of registers
  parameter A=$clog2(M) //Number of address lines
) (
  input 
