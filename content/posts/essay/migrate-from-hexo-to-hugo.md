---
title: Migrate From Hexo to Hugo
date: 2023-12-23T14:55:24+08:00
mathjax: false
tags:
  - Essay
description:
---

嗨嗨嗨，Blog大变样。

上上个周末强网杯打的有点道心破碎，于是抽了点时间出来把博客整了整，大体上就是从hexo迁移到了hugo。于是呢就来简单聊聊整个迁移的过程。

为什么要迁移到hugo呢？

-   我hexo的数学公式不知道什么原因一直渲染有问题。
-   感觉hexo有点慢，而且臃肿。正好hugo自称是世界上最快的网页生成框架，就想试试。
-   总感觉用hugo比用hexo要高级….
-   对于go语言写的东西没有抵抗力，而且越来越不喜欢nodejs了。

于是在上周二决定要整成hugo，从此命运的齿轮开始转动。

安装hugo，在archlinux上直接`yay -S hugo`就ok了。

装好hugo后的第一步应该要先选择一个自己喜欢的主题。[hugo themes](https://themes.gohugo.io/)这里有非常多的好看的主题可以选择。我使用的是[Jane](https://themes.gohugo.io/themes/hugo-theme-jane/)，在此呢也是非常推荐大家使用这个主题尤其是喜欢"简洁"的小伙伴。

![Jane preview](https://themes.gohugo.io/themes/hugo-theme-jane/screenshot_hue86ec56387d55a4e982f80cc54614468_206579_750x500_fill_catmullrom_top_3.png)

关于主题的配置可以看主题的[github仓库](https://github.com/xianmin/hugo-theme-jane/blob/master/README-zh.md)有很详细的介绍，而且配置文件里也有很详细的中文注释和英文注释，我这里主要提一下数学公式的配置。

在示例配置文件theme/jane/exampleSite/full-config.toml中有关于数学公式的配置项（记得把这个复制到博客根目录的配置文件中）

![Screenshot_2023-12-23-21-57-07.png](https://s2.loli.net/2023/12/23/xt51I7Y8cw3ybWi.png)

可以在这里直接选一个开，但是这样还不够，我们需要找到主题中用于渲染latex公式的js部分。

我已经找到在themes/jane/layout/partials/scripts.html，把他修改成下面这个样子

```html
<!-- Mathjax -->
{{- if and (or .Params.mathjax (and .Site.Params.mathjax (ne .Params.mathjax false))) (or .IsPage .IsHome) }}
<script type="text/javascript">
    window.MathJax = { showProcessingMessages: false, messageStyle: "none" };
</script>
<script src="https://cdnjs.cloudflare.com/ajax/libs/mathjax/2.7.4/MathJax.js?config=TeX-MML-AM_CHTML" async>
    MathJax.Hub.Config({ tex2jax: { inlineMath: [['$','$'], ['\\(','\\)']], displayMath: [['$$','$$'], ['\[\[','\]\]']], processEscapes: true, processEnvironments: true, skipTags: ['script', 'noscript', 'style', 'textarea', 'pre'], TeX: { equationNumbers: { autoNumber: "AMS" }, extensions: ["AMSmath.js", "AMSsymbols.js"] } } }); MathJax.Hub.Queue(function() { // Fix <code> tags after MathJax finishes running. This is a // hack to overcome a shortcoming of Markdown. Discussion at // https://github.com/mojombo/jekyll/issues/199 var all = MathJax.Hub.getAllJax(), i; for(i = 0; i < all.length; i += 1) { all[i].SourceElement().parentNode.className += ' has-jax'; } });
</script>
<style>
    code.has-jax {
        font: inherit;
        font-size: 100%;
        background: inherit;
        border: inherit;
        color: #515151;
    }
</style>
{{- end }}
<!-- End -->
<!-- KaTeX -->
{{- if and (or .Params.katex (and .Site.Params.katex (ne .Params.katex false))) (or .IsPage .IsHome) }}
<link rel="stylesheet" href="https://cdn.jsdelivr.net/npm/katex@0.11.0/dist/katex.min.css" integrity="sha384-BdGj8xC2eZkQaxoQ8nSLefg4AV4/AwB3Fj+8SUSo7pnKP6Eoy18liIKTPn9oBYNG" crossorigin="anonymous" />
<!-- The loading of KaTeX is deferred to speed up page rendering -->
<script defer src="https://cdn.jsdelivr.net/npm/katex@0.11.0/dist/katex.min.js" integrity="sha384-JiKN5O8x9Hhs/UE5cT5AAJqieYlOZbGT3CHws/y97o3ty4R7/O5poG9F3JoiOYw1" crossorigin="anonymous"></script>
<!-- To automatically render math in text elements, include the auto-render extension: -->
<script
    defer
    src="https://cdn.jsdelivr.net/npm/katex@0.11.0/dist/contrib/auto-render.min.js"
    integrity="sha384-kWPLUVMOks5AQFrykwIup5lo0m3iMkkHrD0uJ4H5cjeGihAutqP0yW0J6dpFiVkI"
    crossorigin="anonymous"
    onload="renderMathInElement(document.body);"
></script>
<script>
    document.addEventListener("DOMContentLoaded", function() { renderMathInElement(document.body, { // ...options... // customised options // • auto-render specific keys, e.g.: delimiters: [ { left: '$$', right: '$$', display: true }, { left: '$', right: '$', display: false }, { left: '\\(', right: '\\)', display: false }, { left: '\\[', right: '\\]', display: true } ], // • rendering keys, e.g.: throwOnError: false }); });
</script>
{{- end }}
<!-- End -->
```

原先这里应该是空的，我加入了一些mathjax和katex的配置，比如公式的前缀后缀这些。

从上面的代码中我们可以看到jane主题在处理latex公式时是请求的cdn，而不是像hexo这样把模块存储在本地。

然后我们就可以愉快的用`hugo server`来在线部署我们的博客了。如果想把草稿(draft: true)也加进去记得在命令后面加上参数`-D`。

至于部署虽然不能像hexo那样`hexo d`一键部署，不过写一个脚本来代替git的几个操作用起来还是不错的。

最后夸一下hugo生成的目录结构真的比hexo好太多了。hexo把我们写的文章按照时间在分类，比如2022年写的文章放一起，2023年写的文章放一起。而hugo的文章目录跟我们content文件夹的目录结构是一样的，这样非常方便我们进行后续的管理或者再迁移。
