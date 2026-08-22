import torch
import torch.nn as nn
import numpy as np

#复用之前写好的量化、反量化函数
def quant_float_to_int8(x,scale,zp):
    res = np.round(x / scale + zp)
    res = np.clip(res, -128, 127)
    return res.astype(np.int8)

def dequant_int8_to_float(x_int8, scale, zp):
    return (x_int8.astype(np.float32) - zp) * scale

# 简易两层CNN测试网络
class TinyCNN(nn.Module):
    def __init__(self):
        super().__init__()
        self.conv1 = nn.Conv2d(3, 8, kernel_size=3, padding=1)
        self.conv2 = nn.Conv2d(8, 16, kernel_size=3, padding=1)

    def forward(self, x):
        x = self.conv1(x)
        x = self.conv2(x)
        return x

# 初始化模型，评估模式
model = TinyCNN()
model.eval()

# ----------------------处理第一层卷积conv1----------------------
w1_tensor = model.conv1.weight.data.cpu()
w1_np = w1_tensor.numpy()

f_max1 = np.max(w1_np)
f_min1 = np.min(w1_np)
scale1 = (f_max1 - f_min1) / 255.0
zero_point1 = round(-f_min1 / scale1)

# 量化+反量化
w1_int8 = quant_float_to_int8(w1_np, scale1, zero_point1)
w1_recover = dequant_int8_to_float(w1_int8, scale1, zero_point1)
max_err1 = np.max(np.abs(w1_np - w1_recover))

# 打印参数
print("=====卷积第一层 conv1=====")
print(f"权重维度shape: {w1_np.shape}")
print(f"权重最大值={f_max1:.4f}, 最小值={f_min1:.4f}")
print(f"量化scale={scale1:.6f}, zero_point={zero_point1}")
print(f"量化前后最大误差={max_err1:.6f}\n")

# 输出FPGA使用的二进制bin文件
with open("conv1_weight_int8.bin","wb") as f:
    f.write(w1_int8.tobytes())
print("已生成 conv1_weight_int8.bin\n")

# ----------------------处理第二层卷积conv2----------------------
w2_tensor = model.conv2.weight.data.cpu()
w2_np = w2_tensor.numpy()

f_max2 = np.max(w2_np)
f_min2 = np.min(w2_np)
scale2 = (f_max2 - f_min2) / 255.0
zero_point2 = round(-f_min2 / scale2)

w2_int8 = quant_float_to_int8(w2_np, scale2, zero_point2)
w2_recover = dequant_int8_to_float(w2_int8, scale2, zero_point2)
max_err2 = np.max(np.abs(w2_np - w2_recover))

print("=====卷积第二层 conv2=====")
print(f"权重维度shape: {w2_np.shape}")
print(f"权重最大值={f_max2:.4f}, 最小值={f_min2:.4f}")
print(f"量化scale={scale2:.6f}, zero_point={zero_point2}")
print(f"量化前后最大误差={max_err2:.6f}")

with open("conv2_weight_int8.bin","wb") as f:
    f.write(w2_int8.tobytes())
print("已生成 conv2_weight_int8.bin")