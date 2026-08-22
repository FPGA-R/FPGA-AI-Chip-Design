import numpy as np
#生成4行4列的float32随机矩阵
mat_a =np.random.randn(4,4).astype(np.float32)

print("矩阵A:")
print(mat_a)
print("max=",np.max(mat_a))
print("min=",np.min(mat_a))

#输出二进制bin文件
with open("float_A.bin","wb") as f:
    f.write(mat_a.tobytes())