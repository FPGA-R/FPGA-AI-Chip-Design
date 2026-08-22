import numpy as np

#生成4*4浮点矩阵
mat_a=np.random.randn(4,4).astype(np.float32)

f_max=np.max(mat_a)
f_min=np.min(mat_a)

#INT8量化公式
scale=(f_max-f_min)/255.0
zero_point=round(-f_min/scale)

#封装成量化函数
def quant_float_to_int8(x,scale,zp):
    res = np.round(x / scale + zp)
    # 限制在‑128~127
    res = np.clip(res, -128, 127)
    return res.astype(np.int8)

mat_int8=quant_float_to_int8(mat_a, scale, zero_point)

print("原始浮点矩阵：")
print(mat_a)
print(f"\nscale = {scale:.6f}, zero_point = {zero_point}")
print("\n量化后int8矩阵：")
print(mat_int8)

# 输出量化后的数据bin文件（给FPGA读的数据）
with open("int8_A.bin","wb") as f:
    f.write(mat_int8.tobytes())