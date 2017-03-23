<?xml version="1.0" encoding="UTF-8"?>
<project name="myCPU" board="Mojo V3" language="Lucid">
  <files>
    <src>cortexM0.luc</src>
    <src top="true">mojo_top.luc</src>
    <ucf lib="true">mojo.ucf</ucf>
    <ucf>bus.ucf</ucf>
    <component>simple_ram.v</component>
    <component>reset_conditioner.luc</component>
  </files>
</project>
