https://en.wikipedia.org/wiki/Hewson_Consultants

Usages:
Exolon: https://www.worldofspectrum.org/infoseekid.cgi?id=0001686
Marauder: https://www.worldofspectrum.org/infoseekid.cgi?id=0003030
Cybernoid: https://www.worldofspectrum.org/infoseekid.cgi?id=0001196
Gunrunner: https://www.worldofspectrum.org/infoseekid.cgi?id=0002181

Protections:
1. XOR

FC00       LD BC,029D
FC03       LD HL,FC13
FC06       LD DE,FC14
FC09 LOOP  LD A,(DE)
FC0A       XOR (HL)
FC0B       LD (HL),A
FC0C       INC HL
FC0D       INC DE
FC0E       DEC BC
FC0F       LD A,B
FC10       OR C
FC11       JR NZ,LOOP

2. Non-standard file headers

FE90       LD A,(FC21)
FE93       CP 2A
FE95       JR NZ,LD_HEADER
