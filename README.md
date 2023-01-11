
## 安装
https://rubyinstaller.org/downloads/ 下载with devkit
安装最后选择3

安装jekll
gem install jekyll

安装jekyll-paginate
gem install jekyll-paginate

验证 jekyll
jekyll -v

安装 bundle
gem install bundle



## 使用
切换到项目目录，安装github-pages
gem install github-pages
bundle install

<!-- bundle add webrick -->

bundle exec jekyll serve

bundle exec jekyll serve -P 4000 --watch

更新
bundle update github-pages

显示主题所包含的文件
bundle show minima


jekyll build
# => 当前文件夹中的内容将会生成到 ./_site 文件夹中。
