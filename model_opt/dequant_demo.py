import numpy as np

scale = 0.009533
zero_point = 94

# 量化出来的int8矩阵
mat_int8 = np.array([
    [ 68, 127, 127,   0],
    [ 92,  50, 127,  76],
    [ 37,   1, 101, 127],
    [ 48, 127, 127, 127]
], dtype=np.int8)

# 反量化公式：float = (int8 − zero_point) * scale
def dequant_int8_to_float(x_int8, scale, zp):
    return (x_int8.astype(np.float32) - zp) * scale

mat_recover = dequant_int8_to_float(mat_int8, scale, zero_point)

print("反量化恢复出来浮点矩阵：")
print(mat_recover)