# Here is an overview which bits are used for which feature

```

non_pushable1 = bit1 = 2
non_pushable2 = bit2 = 4
static_world1 = bit3 = 8
static_world2 = bit4 = 16 = 0x10

tractors = bit6 = 64 = 0x40
combines = bit7 = 128 = 0x80
trailers = bit8 = 256 = 0x100

dynamic_objects = bit12 = 4096 = 0x1000


dynamic_objects_machines = bit13 = 8192 = 0x2000 flag for all machines, to make them collide


trigger_player = bit20 = 1048576 = hex 100000
trigger_tractors = bit21 = 2097152 = hex 200000
trigger_combines = bit22 = 4194304 = hex 400000
trigger_fillables = bit23 = 8388608 = hex 800000 (trailers, sprayers, sowingmachines)

trigger_dynamic_objects = bit24 = 16777216 = hex 1000000

trigger_trafficVehicles = bit25 = 33554432 = hex 2000000

trigger_cutters = bit26 = 67108864 = hex 4000000


kinematic_objects_without_collision = bit30 = 1073741824 = hex 40000000

```

So here are some examples which you should use for some objects. Other stuff you can create with the information above:

```

bits for tractors= 1,6,13,21 = 2105410 = 0x202042
bits for combines= 1,7,13,22 = 4202626 = 0x402082
bits for fillables= 1,8,13,23 = 8397058 = 0x802102
bits for cutters = 1,12,13,26 = 67121154 = 0x4003002

bits for tools = 1,13 = 8194

```

Note that only the main body of a tractor, combine, fillable should have the corresponding bits set. Other parts such as the wheel collisions normally don't need to have the trigger flag set, unless you really need it. E.g. the colliding part of the basin of a trailer.

Numbers preceded by a 0x are hexadecimal values. These are shown in the attribute panel fo the GIANTS Editor. The other values are the corresponding decimal values. These are used in the exporter settings in Maya, 3ds Max or Blender.
