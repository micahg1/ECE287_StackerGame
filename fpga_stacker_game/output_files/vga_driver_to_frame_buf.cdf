/* Quartus Prime Version 23.1std.1 Build 993 05/14/2024 SC Lite Edition */
JedecChain;
	FileRevision(JESD32A);
	DefaultMfr(6E);

	P ActionCode(Ign)
		Device PartName(SOCVHPS) MfrSpec(OpMask(0));
	P ActionCode(Cfg)
		Device PartName(5CSEMA5F31) Path("M:/VGA_ON_DE1_SOC_2024/vga_driver_to_frame_buf/output_files/") File("vga_driver_to_frame_buf.sof") MfrSpec(OpMask(1));

ChainEnd;

AlteraBegin;
	ChainType(JTAG);
AlteraEnd;
