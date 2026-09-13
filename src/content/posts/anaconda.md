---
title: Anaconda
author: 碳水化合物
pubDatetime: 2026-09-14T00:31:15+08:00
draft: false
tags: []
description: ""
---

# Anaconda 速通

![image-20260913235410584](images/image-20260913235410584.png)

## 介绍

**Anaconda** 是一个面向数据科学、机器学习和科学计算的 **Python/R 发行版**。它把 Python、`conda` 包管理器、大量常用科学计算库，以及 Jupyter、Spyder 等工具打包在一起，安装后基本可以“开箱即用”。

常见的几个容易混淆的词：

- **Anaconda**：完整发行版，预装大量包和工具，体积大。
- **conda**：包管理和环境管理工具，Anaconda 里包含它。
- **Miniconda**：精简版，只含 `conda` + Python，其他包自己装。
- **Miniforge**：类似 Miniconda，但默认使用社区频道 `conda-forge`。



## 包含什么

典型 Anaconda Distribution 包含：

- **Python**：默认 Python 环境
- **conda**：安装包、创建环境、管理依赖
- **Anaconda Navigator**：图形化管理界面
- **Jupyter Notebook / JupyterLab**：交互式编程
- **Spyder**：科学计算 IDE
- **常用科学计算包**：
  - NumPy、SciPy、pandas
  - Matplotlib、Seaborn、Plotly
  - scikit-learn、statsmodels
  - NLTK、Dask、Numba 等
- **Anaconda Prompt / Terminal**：命令行入口
- 对 R 语言也有一定支持，但默认以 Python 生态为主

它支持 Windows、macOS、Linux。



## 优点

1. **开箱即用**
   安装后 NumPy、pandas、Jupyter 等常用工具基本都有了，适合新手和教学。

2. **环境隔离**
   可以为不同项目创建不同环境，避免包版本冲突：

   ```bash
   conda create -n myenv python=3.11
   conda activate myenv
   ```

   

3. **跨平台、支持非 Python 依赖**
   conda 不仅能装 Python 包，还能装 C/C++ 库、CUDA、R 包等，对科学计算和深度学习比较友好。

4. **依赖解析能力强**
   相比单纯 pip，conda 更擅长处理复杂的二进制依赖关系。

5. **适合数据科学、科研、机器学习**
   很多课程、论文复现、Kaggle 项目都直接用 Anaconda 环境。


## 缺点

1. **体积大**
   完整安装通常几 GB，占用磁盘较多，安装也较慢。

2. **预装包多，可能冗余**
   很多包你可能用不到，环境不够轻量。

3. **依赖解析有时较慢**
   尤其是环境复杂、频道多的时候，`conda install` 可能比较慢。

4. **商业许可问题**
   Anaconda 默认频道 `defaults` 有服务条款，商业/组织使用前建议查看官方许可。
   如果不想受此影响，可以用 **Miniforge + conda-forge**，或 **Miniconda** 自行配置频道。

5. **pip 和 conda 混用可能冲突**
   在 conda 环境里可以用 pip，但建议：

   ```bash
   python -m pip install 包名  # 给当前的环境安装包
   ```

   不要频繁混用，否则可能破坏依赖关系。

## 命令

### 基础命令

**查看conda 版本：**

```bash
conda --version
```

**查看conda的详细信息：**

```bash
conda info
```

详细信息当中几个常用信息：

```
  active environment : base
    active env location : /Users/w/anaconda3
            shell level : 1
       user config file : /Users/w/.condarc
 conda version : 25.11.0
       python version : 3.13.9.final.0
     base environment : /Users/w/anaconda3  (writable)
          channel URLs : https://repo.anaconda.com/pkgs/main/osx-arm64
                        https://repo.anaconda.com/pkgs/r/osx-arm64
           platform : osx-arm64
```

看几个重点：

- `active environment : base` -- 你现在在 base 环境里。
- `python version : 3.13.9` -- 这个 Anaconda 自带的 Python 是 3.13 版。
- `platform : osx-arm64` -- 你的系统平台（我这里是苹果芯片的 Mac，Intel 芯片的 Mac 会显示 `osx-64`，Windows 显示 `win-64`）。
- `channel URLs` -- conda 从哪些网址下载库。

**查看当前拥有的虚拟环境:**

```bash
conda env list
```



## 环境操作

### 创建环境

想要创建一个环境，可以通过下面的命令：

```bash
conda create -n myfirst python=3.11
```

逐个拆开看这行命令：

- `conda create` -- 创建环境，固定写法。
- `-n myfirst` -- `-n` 是 name 的缩写，后面跟环境名。这里叫 `myfirst`。
- `python=3.11` -- 指定这个环境里装哪个版本的 Python。不写的话，conda 会给你装当前默认版本（通常和 base 一样）。

### 激活环境

创建好环境之后，还需要激活这个环境，可以通过下面的命令来实现：

```bash
conda activate myfirst
```

### 退出当前环境

如果想要从一个虚拟环境中退出，需要通过下面的命令：

```bash
conda deactivate
```

### 删除虚拟环境

如果某个环境已经没有用了，可以通过下面的命令删除:

```bash
conda remove -n myfirst --all # 注意，删除某个环境之前，要先通过deactivate命令退出要删除的环境
```

- `conda remove` -- 删除，固定写法。
- `-n myfirst` -- 删哪个环境。
- `--all` -- 删干净，连里面的包一起清掉。不加 `--all` 只删包不删环境。

## 环境的导出和克隆

### 导出环境

#### 同一台电脑导出

如果是在同一台电脑上导出环境，可以通过下面的命令来实现：

```bash
conda create -n myblog-test --clone myblog
```

- `--clone myblog` -- 以 myblog 为模板复制一份。

回车，等它复制完，你就得到了一个和 myblog 一模一样的 `myblog-test` 环境。改 test 环境里的东西，不会影响原来的 myblog。

克隆是在**同一台电脑**上做的，因为它是直接复制文件，速度快。

#### 多台电脑配置同步

主要思路是导出配置文件，然后到了新电脑上按照这个配置文件进行安装。

首先需要进入到要导出的环境中。

```bash
conda activate myblog
```

然后导出yml文件。

```bash
conda env export > environment.yml
```

- `conda env export` -- 把当前环境的配置打印出来。
- `> environment.yml` -- 用重定向符 `>` 把输出写到叫 `environment.yml` 的文件里（而不是显示在屏幕上）。

这条命令会在你**当前所在的文件夹**里生成一个 `environment.yml` 文件。

用记事本或 `cat` 打开它，大概长这样：

```
name: myblog
channels:
  - defaults
dependencies:
  - python=3.11.14=h80e0c04_0_cpython
  - django=4.2.16=py311h80e0c04_0
  - requests=2.32.3=py311h80e0c04_0
  - pip:
      - some-pip-package==1.2.3
prefix: /Users/w/anaconda3/envs/myblog
```

把这个yml文件拿到另外一台电脑上，然后执行下面的命令：

```bash
conda env create -f environment.yml
```

- `-f environment.yml` -- from file，从这份清单创建环境。

> 注意：`conda env create` 会用文件里 `name:` 那行指定的名字建环境。你想换个名字，加 `-n 新名字`：`conda env create -f environment.yml -n 新名字`。

#### 容易出错的地方

`conda env export` 导出的清单里，库的版本号后面会带一串**构建编号**（build string），这些编号和**操作系统****、芯片架构**有关。比如你在 Mac 苹果芯片上导出的清单，拿到 Windows 上 `conda env create`，可能报错说"找不到这个版本的包"--因为那个构建编号是苹果芯片专用的，Windows 上没有。

解决办法：导出时加 `--no-builds`，让 conda 只记版本号、不记构建编号：

```bash
conda env export --no-builds > environment.yml
```

还有一个更干净的选项 `--from-history`：

```bash
conda env export --from-history > environment.yml
```

它只记录你**主动指定**装过的库（`conda install xxx` 时敲的那些），不记自动跟着装的依赖。清单更短、更通用，代价是别人重建时可能装到稍微新一点的依赖版本（通常没问题）。

还有一点要提醒：用 `pip install` 装的库**不会**被 `--from-history` 记下来（pip 装的东西不在 conda 的历史里）。所以如果你的项目大量用 pip 装包，别用 `--from-history`，老老实实用 `--no-builds` 导出更保险。

给别人分享的清单，我推荐用 `--from-history`（项目以 conda 包为主时）；自己精确复刻，用默认的完整导出或 `--no-builds`。

## 包的安装和删除

### 搜索包

安装之前，可以通过下面的命令来搜索一下这个包是否存在于conda的频道当中：

```bash
conda search 包名
```

想看某个大版本下有哪些，加条件（注意 `>` 是特殊字符，要用引号包起来）：

```bash
conda search "django>=4.2"
```



### 安装包

通过下面的命令安装包：

```bash
conda install requests # requests 是包的名字
```

也可以一次性安装多个包：

```bash 
conda install numpy pandas matplotlib
```

指定版本：

```bash
conda install django=4.2
conda install django=4.2.16
```

**不想每次都敲 y**：加 `-y`，直接确认。

```bash
conda install requests -y
```

### 查看装了哪些包

```bash
conda list
```

想找某个特定的包，加包名过滤：

```bash
conda list requests
```

### 更新包

把某个包升到最新版：

```bash
conda update requests
```

想升级当前环境里**所有**的包（谨慎用）：

```bash
conda update --all
```

> 提醒：`conda update --all` 会同时动很多包，依赖关系可能大变，有时反而把环境搞坏。除非你确实要全面升级，否则**别随便用 --all**，按需更新单个包更安全。

### 卸载包

不想要某个包了：

```bash
conda remove requests
```

会列出要删的东西，确认 `y`。注意 conda 可能会连带删掉只被它依赖的包，这是正常的（删干净）。

> 注意区分：`conda remove -n 环境名 --all` 是删整个环境；`conda remove 包名` 是在当前环境里删一个包。别搞混。

## 频道

频道，就是 conda 下载包的**仓库地址**。

**defaults（****Anaconda** **官方频道）**

- Anaconda 公司自己维护，装好就有。
- 里面的包经过 Anaconda 测试，比较稳。
- 但有个问题：defaults 频道受 Anaconda 的商业条款约束--如果你所在的组织超过 200 人，用它做商业用途是需要付费授权的。个人学习没问题，但公司里大规模用要注意。

**conda-forge（社区频道）**

- 全社区维护，完全开源免费，没有商业限制。
- 包的数量比 defaults 多得多，更新也更快--很多新包先在 conda-forge 出现。
- 现在大多数 Python 开发者都把 conda-forge 当主力频道。

默认 conda 从 defaults 装。想从 conda-forge 装，用 `-c` 指定：

```bash
conda install -c conda-forge 包名
```

`-c conda-forge` 的意思是"从 conda-forge 这个频道装"。

什么时候要指定？比如某个包在 defaults 里没有、或者 conda-forge 里版本更新，你就显式指定从 conda-forge 装。

**如果想把conda-forge社区频道当作默认频道，需要通过下面的命令:**

```bash
conda config --add channels conda-forge
```

这条命令把 conda-forge 加到频道列表第一位（`--add` 是往最前面塞）。再看一下配置：

```bash
conda config --show channels
```

```
channels:
  - conda-forge
  - defaults
```

**还可以设置一下频道优先级。**

默认情况下，conda 在不同频道间会"混着挑"--可能这个包从 conda-forge 拿，那个包从 defaults 拿，混在一起容易出依赖冲突。

更推荐的做法是开启 **strict 严格优先级**：

```bash
conda config --set channel_priority strict
```

strict 模式下，conda 会**优先用一个频道里的所有包**，只有这个频道没有的才去下一个频道找。这样能最大程度避免不同频道之间的包混搭冲突。

> 刚才那些 `conda config` 命令，其实都是在改一个配置文件，叫 **.condarc**，放在你的用户目录下（Windows 在 `C:\Users\你的用户名\.condarc`，macOS/Linux 在 `~/.condarc`）。

## 清除缓存

conda使用时间久了就会出现一堆缓存，通过下面的命令可以清除缓存：

```bash
conda clean --all -y
```

这条命令清掉缓存的安装包和索引文件，不影响已经装好的环境，安全。清完能用 `df -h`（macOS/Linux）或看磁盘属性（Windows）确认空间释放了。