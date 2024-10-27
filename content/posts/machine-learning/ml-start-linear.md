---
title: Machine Learning Start -- Linear
date: 2024-01-21T21:52:06+08:00
mathjax: true
tags:
  - Machine-Learning
description:
---

## instro

线性回归是在特征与输出之间构建一个线性方程。如$ y = \sum_{i=0}^{n}a_{i}x_{i} + b$, $x, y$分别为特征向量和输出。
$a$作为需要求解的系数。一般的线性回归适用于回归任务（连续值），对于分类任务则使用对数几率回归，又称
逻辑斯特回归，使用对数几率函数$ f(x) = \frac{1}{1-e^{-x}} $。对于多分类任务则使用Softmax回归。

线性回归问题，书本上给了两种求解方法：1. 最小二乘法 2. 梯度下降法。本篇文章将只实现最小二乘法，
因为梯度下降在神经网络中更加适合

## Linear Regression

### basic model

特征向量$x$，输出$y$，有
$$
\begin{aligned}
y &= a_0x_0 + a_1x_1 + \cdots + a_{i-1}x_{n-1} + b \\\
  &= \sum_{i=0}^{n-1}a_ix_i + b
\end{aligned}
$$

把$a$和$b$吸收入向量形式$ w=(a;b) $, 相应的，把数据集$D$表示为一个$m×(d+1)$大小的矩阵，其中每行对应于一个示例，该行前d个元素对应于示例的d个属性值，最后一个元素恒置为1，即：

$$
\mathbf{X}=\begin{pmatrix}x_{11}&x_{12}&\ldots&x_{1d}&1\\\
x_{21}&x_{22}&\ldots&x_{2d}&1\\\
\vdots&\vdots&\ddots&\vdots&\vdots\\\
x_{m1}&x_{m2}&\ldots&x_{md}&1\end{pmatrix}=\begin{pmatrix}\boldsymbol{x}_1^\mathrm{T}&1\\\x_2^\mathrm{T}&1\\\ \vdots&\vdots\\\x_m^\mathrm{T}&1\end{pmatrix}
$$

$$
Y = Xw
$$

损失函数选择均方差损失

$$
\begin{aligned}
L &= \sum_{i=0}^{n-1}(y - \hat{y})^2 \\\
     &= \sum_{i=0}^{n-1}(y - \sum_{i=0}^{n-1}a_ix_i - b)^2 \\\
     &= (Y - Xw)^2
\end{aligned}
$$

### solve

使用最小二乘法求解模型，令均方差损失最小，即求出极小值，分别对$a,b$求导, 即对$w$求导

$$
\begin{aligned}
\frac{\partial{L}}{\partial{w}} &= 0 \\\
X^{T}(Y - Xw) &= 0 \\\
w &= (X^{T}X)^{-1}X^{T}Y
\end{aligned}
$$

### test

使用下面的代码生成需要的数据集

```python
def get_data_set(m: int, wights: np.ndarray, bias: float) -> Tuple[np.ndarray, ...]:
    n = wights.size
    X = np.random.rand(m, n)
    Y = np.array(
        [np.dot(wights, X[i]) + bias + random.random() * 0.01 for i in range(m)]
    )
    return X, Y

```

其中`random.random() * 0.01`是作为error项，目的是不要让样本的分布直接呈现线性关系

使用下面的代码来实现最小二乘法求解
```python
def solve(X, Y) -> np.ndarray:
    X_T = np.transpose(X)
    w = np.matmul(np.linalg.inv(np.matmul(X_T, X)), np.matmul(X_T, Y))
    return w


def lsm(X: np.ndarray, Y: np.ndarray):
    m, n = X.shape
    X = np.concatenate((X, np.ones((1, m)).T), axis=1)
    Y = Y.reshape((m, 1))
    w = solve(X, Y)
    return w.flatten()
```

以6维特征来进行测试
```python
featrue_nums = 6
real_b = random.random()
real_a = np.random.rand(featrue_nums)
X, Y = get_data_set(10, real_a, real_b)
w = lsm(X, Y)
print(w)
print(real_a, real_b)
```

测试结果
```bash
[0.43376235 0.78558162 0.20773861 0.88983048 0.80890781 0.40127196
 0.35963757]
[0.43057936 0.79179205 0.20033821 0.87883885 0.8172409  0.40964536] 0.35893656235086113
```

