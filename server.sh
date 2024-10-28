#!/bin/bash

# 检查 public 文件夹和 .hugo_build.lock 文件是否存在
if [ -d "public" ] && [ -f ".hugo_build.lock" ]; then
    echo "Deleting public directory and .hugo_build.lock file..."
    rm -r public
    rm .hugo_build.lock
    echo "Deletion complete."
else
    echo "Either public directory or .hugo_build.lock file does not exist."
fi

hugo server
