# tb_programa_rvc1
iverilog -o waveform/sim.out \
  src/top_pipe.v src/pipeline.v src/if_stage.v src/id_stage.v \
  src/ex_stage.v src/mem_stage.v src/wb_stage.v \
  src/controller_pipe.v src/maindec.v src/aludec.v \
  src/hazard_unit.v src/extend.v src/regfile.v \
  src/imem.v src/dmem.v src/alu.v src/adder.v \
  src/flopr.v src/mux2.v src/mux3.v src/decompressor.v \
  tb/tb_programa_rvc1.v && vvp waveform/sim.out

# tb_programa_rvc2
iverilog -o waveform/sim.out \
  src/top_pipe.v src/pipeline.v src/if_stage.v src/id_stage.v \
  src/ex_stage.v src/mem_stage.v src/wb_stage.v \
  src/controller_pipe.v src/maindec.v src/aludec.v \
  src/hazard_unit.v src/extend.v src/regfile.v \
  src/imem.v src/dmem.v src/alu.v src/adder.v \
  src/flopr.v src/mux2.v src/mux3.v src/decompressor.v \
  tb/tb_programa_rvc2.v && vvp waveform/sim.out


# test_instrucciones
iverilog -o waveform/sim.out \
  src/top_pipe.v src/pipeline.v src/if_stage.v src/id_stage.v \
  src/ex_stage.v src/mem_stage.v src/wb_stage.v \
  src/controller_pipe.v src/maindec.v src/aludec.v \
  src/hazard_unit.v src/extend.v src/regfile.v \
  src/imem.v src/dmem.v src/alu.v src/adder.v \
  src/flopr.v src/mux2.v src/mux3.v src/decompressor.v \
  tb/tb_test_instrucciones.v && vvp waveform/sim.out

# test_forwarding
iverilog -o waveform/sim.out \
  src/top_pipe.v src/pipeline.v src/if_stage.v src/id_stage.v \
  src/ex_stage.v src/mem_stage.v src/wb_stage.v \
  src/controller_pipe.v src/maindec.v src/aludec.v \
  src/hazard_unit.v src/extend.v src/regfile.v \
  src/imem.v src/dmem.v src/alu.v src/adder.v \
  src/flopr.v src/mux2.v src/mux3.v src/decompressor.v \
  tb/tb_test_forwarding.v && vvp waveform/sim.out

# test_flushing
iverilog -o waveform/sim.out \
  src/top_pipe.v src/pipeline.v src/if_stage.v src/id_stage.v \
  src/ex_stage.v src/mem_stage.v src/wb_stage.v \
  src/controller_pipe.v src/maindec.v src/aludec.v \
  src/hazard_unit.v src/extend.v src/regfile.v \
  src/imem.v src/dmem.v src/alu.v src/adder.v \
  src/flopr.v src/mux2.v src/mux3.v src/decompressor.v \
  tb/tb_test_flushing.v && vvp waveform/sim.out

# test_stalling
iverilog -o waveform/sim.out \
  src/top_pipe.v src/pipeline.v src/if_stage.v src/id_stage.v \
  src/ex_stage.v src/mem_stage.v src/wb_stage.v \
  src/controller_pipe.v src/maindec.v src/aludec.v \
  src/hazard_unit.v src/extend.v src/regfile.v \
  src/imem.v src/dmem.v src/alu.v src/adder.v \
  src/flopr.v src/mux2.v src/mux3.v src/decompressor.v \
  tb/tb_test_stalling.v && vvp waveform/sim.out

# test_10_instrucciones  
iverilog -o waveform/sim.out \
  src/top_pipe.v src/pipeline.v src/if_stage.v src/id_stage.v \
  src/ex_stage.v src/mem_stage.v src/wb_stage.v \
  src/controller_pipe.v src/maindec.v src/aludec.v \
  src/hazard_unit.v src/extend.v src/regfile.v \
  src/imem.v src/dmem.v src/alu.v src/adder.v \
  src/flopr.v src/mux2.v src/mux3.v src/decompressor.v \
  tb/tb_test_10_instrucciones.v && vvp waveform/sim.out