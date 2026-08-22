import numpy as np

# 读取生成的bin文件，把二进制读回int8数组，做简单校验
def read_int8_bin(filepath, shape):
    with open(filepath, "rb") as f:
        data = f.read()
    arr = np.frombuffer(data, dtype=np.int8)
    arr = arr.reshape(shape)
    return arr

if __name__ == "__main__":
    # conv1权重shape (out_channel,in_channel,kernel,kernel) → (8,3,3,3)
    w1_int8_read = read_int8_bin("conv1_weight_int8.bin", (8, 3, 3, 3))
    print("conv1 bin读取成功，shape =", w1_int8_read.shape)
    print("conv1 int8数值范围：", w1_int8_read.min(), "~", w1_int8_read.max())

    # conv2权重shape (16,8,3,3)
    w2_int8_read = read_int8_bin("conv2_weight_int8.bin", (16, 8, 3, 3))
    print("\nconv2 bin读取成功，shape =", w2_int8_read.shape)
    print("conv2 int8数值范围：", w2_int8_read.min(), "~", w2_int8_read.max())

    print("\n✅ bin文件读取校验完成，二进制数据格式正常，可以交给FPGA使用。")