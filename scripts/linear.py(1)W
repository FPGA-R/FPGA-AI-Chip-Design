
import torch
import torch.nn as nn
import torch.optim as optim

torch.manual_seed(42)

# ==================================================
# 1. 定义模型：3输入、1输出
# ==================================================

class LinearModel(nn.Module):

    def __init__(self):
        super().__init__()
        self.linear = nn.Linear(3, 1, bias=True)

    def forward(self, x):
        return self.linear(x)


model = LinearModel()


# ==================================================
# 2. 生成训练数据
#
# 这里只是为了验证流程。
# 假设目标参数为：
# w = [3, 4, 7]
# b = 6
# ==================================================

X_train = torch.rand(512, 3) * 6 - 3

true_w = torch.tensor([3.0, 4.0, 7.0])
true_b = 6.0

Y_train = (X_train @ true_w + true_b).reshape(-1, 1)


# ==================================================
# 3. 训练模型
# ==================================================

criterion = nn.MSELoss()

optimizer = optim.SGD(
    model.parameters(),
    lr=0.01
)

epochs = 5000

print("===== 开始训练 =====")

for epoch in range(epochs):

    optimizer.zero_grad()

    y_pred = model(X_train)

    loss = criterion(y_pred, Y_train)

    loss.backward()

    optimizer.step()

    if epoch % 500 == 0:
        print(
            f"epoch:{epoch}, "
            f"loss:{loss.item():.6f}"
        )


# ==================================================
# 4. 获取训练后的浮点参数
# ==================================================

w_float = model.linear.weight.detach().reshape(-1)
b_float = model.linear.bias.detach().item()

print("\n===== 训练得到的浮点参数 =====")

print("w =", w_float.tolist())
print("b =", b_float)


# ==================================================
# 5. 设置输入量化尺度
#
# 假设输入范围为 [-3, 3]
# 对称INT8量化：
# qx = round(x / Sx)
# ==================================================

Sx = 3.0 / 127.0


# ==================================================
# 6. 权重INT8量化
#
# qw = round(w / Sw)
# ==================================================

Sw = w_float.abs().max().item() / 127.0

w_int8 = torch.round(
    w_float / Sw
).clamp(-127, 127).to(torch.int8)


# ==================================================
# 7. Bias量化
#
# Bias必须与乘加结果使用相同的尺度
#
# Sb = Sx * Sw
# qb = round(b / Sb)
# ==================================================

Sb = Sx * Sw

bias_int32 = round(b_float / Sb)


# ==================================================
# 8. 打印量化结果
# ==================================================

print("\n===== INT8量化结果 =====")

print("w_int8 =", w_int8.tolist())

print("bias_int32 =", bias_int32)

print(f"Sx = {Sx:.10f}")
print(f"Sw = {Sw:.10f}")
print(f"Sb = {Sb:.10f}")


# ==================================================
# 9. 测试一个新输入
# ==================================================

x_test = torch.tensor([1.0, 2.0, 3.0])

# PyTorch浮点推理
with torch.no_grad():
    y_float = model(x_test).item()


# 输入量化
x_int8 = torch.round(
    x_test / Sx
).clamp(-127, 127).to(torch.int8)


# ==================================================
# 10. 模拟FPGA整数乘加
#
# FPGA执行：
# acc = qx0*qw0 + qx1*qw1 + qx2*qw2 + qb
# ==================================================

acc = (
    (x_int8.to(torch.int32) *
     w_int8.to(torch.int32)).sum().item()
    + bias_int32
)


# 反量化
y_quant = acc * Sb


# ==================================================
# 11. 比较浮点和量化结果
# ==================================================

print("\n===== 推理结果对比 =====")

print("原始输入 =", x_test.tolist())

print("INT8输入 =", x_int8.tolist())

print("浮点模型输出 =", y_float)

print("INT32累加结果 =", acc)

print("量化后反量化输出 =", y_quant)

print("绝对误差 =", abs(y_float - y_quant))


# ==================================================
# 12. 导出FPGA参数
# ==================================================

with open("linear_params.txt", "w") as f:

    f.write("w_int8\n")
    f.write(" ".join(str(int(v)) for v in w_int8))
    f.write("\n")

    f.write("bias_int32\n")
    f.write(str(bias_int32))
    f.write("\n")

    f.write("scales\n")
    f.write(f"{Sx:.12f} {Sw:.12f} {Sb:.12f}\n")


print("\n参数导出完成！")
print("文件：linear_params.txt")







运行结果
D:\Miniconda_Setup\Miniconda\envs\fpga_ai\python.exe D:\Python-project\py_project01\第一章\data\MNIST\studying4.py 
===== 开始训练 =====
epoch:0, loss:232.716614
epoch:500, loss:0.000000
epoch:1000, loss:0.000000
epoch:1500, loss:0.000000
epoch:2000, loss:0.000000
epoch:2500, loss:0.000000
epoch:3000, loss:0.000000
epoch:3500, loss:0.000000
epoch:4000, loss:0.000000
epoch:4500, loss:0.000000

===== 训练得到的浮点参数 =====
w = [3.000002384185791, 3.99999737739563, 6.999995708465576]
b = 5.999987602233887

===== INT8量化结果 =====
w_int8 = [54, 73, 127]
bias_int32 = 4608
Sx = 0.0236220472
Sw = 0.0551180764
Sb = 0.0013020018

===== 推理结果对比 =====
原始输入 = [1.0, 2.0, 3.0]
INT8输入 = [42, 85, 127]
浮点模型输出 = 37.99997329711914
INT32累加结果 = 29210
量化后反量化输出 = 38.03147274678148
绝对误差 = 0.031499449662341306

参数导出完成！
文件：linear_params.txt

进程已结束，退出代码为 0







文件：linear_params.txt
w_int8
54 73 127
bias_int32
4608
scales
0.023622047244 0.055118076445 0.001302001806
