在pass4的基础上
实现了跳转指令的译码
解释了 wire rs_eq_rt;//相等
    wire rs_ge_z;//是否满足 rdata1 的值大于等于 0
    wire rs_gt_z;//表示是否满足 rdata1 的值大于 0
    wire rs_le_z;//表示是否满足 rdata1 的值小于等于0
    wire rs_lt_z;//表示是否满足 rdata1 的值小于于0
  并对其赋值 用于跳转类指令的实现
添加jalr,bgezal,bltzal,bgtz,bltz,blez,bgez，j指令
对之前jr之类赋值问题进行修改
