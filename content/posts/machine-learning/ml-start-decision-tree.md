---
title: Machine Learning Start -- Decision Tree
date: 2024-01-23T18:53:18+08:00
mathjax: true
tags:
  - Machine-Learning
description:
---

## intro

西瓜书的决策树部分，在这篇文章中，将主要实现书中的`TreeGenerate`算法以及各种选取
最优划分属性的方式。

决策树在进行学习的时候有一个很要命的问题，就是过拟合。因为决策树会把所有的样本特征
都学习到，所以过拟合是很难避免的，虽然可以使用剪枝的方法来减少过拟合。不过这篇文章
并不会涉及到剪枝的内容。

数据集依然使用西瓜书对应的西瓜数据集
```python
    色泽  根蒂  敲声  纹理  脐部  触感 好瓜
0   青绿  蜷缩  浊响  清晰  凹陷  硬滑  是
1   乌黑  蜷缩  沉闷  清晰  凹陷  硬滑  是
2   乌黑  蜷缩  浊响  清晰  凹陷  硬滑  是
3   青绿  蜷缩  沉闷  清晰  凹陷  硬滑  是
4   浅白  蜷缩  浊响  清晰  凹陷  硬滑  是
5   青绿  稍蜷  浊响  清晰  稍凹  软粘  是
6   乌黑  稍蜷  浊响  稍糊  稍凹  软粘  是
7   乌黑  稍蜷  浊响  清晰  稍凹  硬滑  是
8   乌黑  稍蜷  沉闷  稍糊  稍凹  硬滑  否
9   青绿  硬挺  清脆  清晰  平坦  软粘  否
10  浅白  硬挺  清脆  模糊  平坦  硬滑  否
11  浅白  蜷缩  浊响  模糊  平坦  软粘  否
12  青绿  稍蜷  浊响  稍糊  凹陷  硬滑  否
13  浅白  稍蜷  沉闷  稍糊  凹陷  硬滑  否
14  乌黑  稍蜷  浊响  清晰  稍凹  软粘  否
15  浅白  蜷缩  浊响  模糊  平坦  硬滑  否
16  青绿  蜷缩  沉闷  稍糊  稍凹  硬滑  否
```

## best feature to split

划分数据集的方式有基于信息增益，信息增益率和基尼指数。笔者只实现了信息增益和基尼指数
，因为信息增益率实现起来其实就和信息增益一样，只不过加了一个惩罚在里面。

### Gain

```python
def Entropy(label: pd.DataFrame) -> float:
    _, counts = np.unique(label, return_counts=True)
    total = len(label)

    ent = 0
    for count in counts:
        prop = count / total
        ent += -prop * np.log2(prop)
    return ent


def Gain(dataset: pd.DataFrame, feature_index: int) -> float:
    total_samples_num = dataset.shape[0]
    feature_values = np.unique(dataset.iloc[:, feature_index])
    gain = Entropy(dataset.iloc[:, -1])
    for value in feature_values:
        subset = dataset[dataset.iloc[:, feature_index] == value]
        sub_smaples_num = subset.shape[0]
        gain -= sub_smaples_num / total_samples_num * Entropy(subset.iloc[:, -1])
    return gain
```

以上代码是用来计算`Gain(D, a)`，测试结果和西瓜书上的一致
```python
Ent(D) = 0.9975025463691152
Gain(D, 色泽) = 0.10812516526536525
Gain(D, 根蒂) = 0.14267495956679277
Gain(D, 敲声) = 0.14078143361499584
Gain(D, 纹理) = 0.3805918973682685
Gain(D, 脐部) = 0.2891587828416789
Gain(D, 触感) = 0.006046489176565528
```

选取`Gain`最大的作为最优划分属性 `纹理`。然后实现寻找最大的信息增益

```python
def __split_with_gain(dataset: pd.DataFrame) -> Tuple[int, float]:
    features_num = dataset.shape[1] - 1
    max_gain = 0.0
    best_feature = None
    for feature_index in range(features_num):
        gain = Gain(dataset, feature_index)
        if gain > max_gain:
            max_gain = gain
            best_feature = feature_index
    if best_feature == None:
        return np.random.randint(0, features_num + 1), -1
    else:
        return best_feature, max_gain
```

### Gini index

内容与上面一致，直接贴代码了
```python
def Gini(label: pd.DataFrame) -> float:
    _, counts = np.unique(label, return_counts=True)
    total = len(label)

    gini = 1
    for count in counts:
        prop = count / total
        gini -= prop**2
    return gini


def Gini_index(dataset: pd.DataFrame, feature_index: int) -> float:
    total_samples_num = dataset.shape[0]
    feature_values = np.unique(dataset.iloc[:, feature_index])
    gini_index = 0
    for value in feature_values:
        subset = dataset[dataset.iloc[:, feature_index] == value]
        sub_smaples_num = subset.shape[0]
        gini_index += sub_smaples_num / total_samples_num * Gini(subset.iloc[:, -1])
    return gini_index

def __split_with_gini(dataset: pd.DataFrame) -> Tuple[int, float]:
    features_num = dataset.shape[1] - 1
    min_gini = float("inf")
    best_feature = None
    for feature_index in range(features_num):
        gini_index = Gini_index(dataset, feature_index)
        if gini_index < min_gini:
            min_gini = gini_index
            best_feature = feature_index
    if best_feature == None:
        return np.random.randint(0, features_num + 1), -1
    else:
        return best_feature, min_gini
```

## generate tree

我选择使用多重字典来作为树的数据结构

```python
def TreeGenerate(dataset: pd.DataFrame, criterion: str = "gini"):
    classes, classes_num = np.unique(dataset.iloc[:, -1], return_counts=True)
    if len(classes_num) == 1:
        return classes[0]
    is_all_same = len(dataset[dataset.duplicated(keep=False)]) == len(dataset)
    if dataset.shape[1] == 1 or is_all_same:
        return dataset.iloc[:, -1].value_counts().idxmax()

    if criterion == "gini":
        feature_to_split, c = __split_with_gini(dataset)
        print(f"最优划分属性：{features[feature_to_split]}")
        print(f"Gini_index：{c}\n")
    if criterion == "gain":
        feature_to_split, c = __split_with_gain(dataset)
        print(f"最优划分属性：{features[feature_to_split]}")
        print(f"Gain：{c}\n")

    feature_values = np.unique(dataset.iloc[:, feature_to_split])
    Tree = {}

    for value in feature_values:
        subset = pd.DataFrame(dataset[dataset.iloc[:, feature_to_split] == value])
        Tree[value] = TreeGenerate(subset, criterion)
    return Tree


print(TreeGenerate(dataset, criterion="gain"))
print(TreeGenerate(dataset, criterion="gini"))
```

运行结果

```shell
最优划分属性：纹理
Gain：0.3805918973682685

最优划分属性：根蒂
Gain：0.45810589515712374

最优划分属性：色泽
Gain：0.2516291673878229

最优划分属性：触感
Gain：1.0

最优划分属性：触感
Gain：0.7219280948873623

{'模糊': '否', '清晰': {'硬挺': '否', '稍蜷': {'乌黑': {'硬滑': '是', '软粘': '否'}, '青绿': '是'}, '蜷缩': '是'}, '稍糊': {
'硬滑': '否', '软粘': '是'}}
最优划分属性：纹理
Gini_index：0.2771241830065359

最优划分属性：根蒂
Gini_index：0.14814814814814814

最优划分属性：色泽
Gini_index：0.3333333333333333

最优划分属性：触感
Gini_index：0.0

最优划分属性：触感
Gini_index：0.0

{'模糊': '否', '清晰': {'硬挺': '否', '稍蜷': {'乌黑': {'硬滑': '是', '软粘': '否'}, '青绿': '是'}, '蜷缩': '是'}, '稍糊': {
'硬滑': '否', '软粘': '是'}}
```

使用信息增益和基尼指数得到的结果是一样的。与书上不同的是，在`纹理=清晰 -> 根蒂=稍蜷`
这个分支没有`色泽=浅白`分支，可是数据集中确实没有`纹理=清晰, 根蒂=稍蜷, 色泽=浅白`的数据。
不知道是不是书上搞错了。
