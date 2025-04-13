.globl main

main:
  addi	sp, sp, -0x30

  lui	t1, 0x10
  addi	t1, t1, 0x1

  lui	t2, 0x20
  addi	t2, t2, 0x1

  lui	t3, 0x30
  addi	t3, t3, 0x1

  lui	t4, 0x20
  addi	t4, t4, 0x2

  lui	t5, 0x30
  addi	t5, t5, 0x2

  lui	t6, 0x40
  addi	t6, t6, 0x2

  set_addr_cfg.0	t1, t2, t3
  set_addr_cfg.1	t1, t2, t3
  set_addr_cfg.2	t1, t2, t3

  set_cood_cfg.0	t1, t2, t3
  set_cood_cfg.1	t1, t2, t3
  set_cood_cfg.2	t1, t2, t3

  bge	t1, t1, 8
  vmask_set	t1
  vmask_set	t4

  bge	t1, t1, 8
  set_sync	0x3
  set_sync	0x4

  bge	t1, t1, 8
  mul.m.vv.f32	t1, t2, t3, 0x1, 0x1, 0x1
  mul.m.vv.f32	t4, t5, t6, 0x1, 0x1, 0x1

  bge	t1, t1, 8
  wait_sync	0x3
  wait_sync	0x4

  addi	sp, sp, 0x30
  addi	x0, x0, 0
  addi	x0, x0, 0
  addi	x0, x0, 0
  addi	x0, x0, 0
  addi	x0, x0, 0
  ret